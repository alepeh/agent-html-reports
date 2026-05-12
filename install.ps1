# install.ps1 — Windows installer for the agent-html-reports skill.
#
# Fetches the upstream exemplar HTML files from ThariqS/html-effectiveness
# into skills/html-reports/references/, then copies skills/<name>/ into
# $env:USERPROFILE\.claude\skills\<name>\ with overwrite. Use on Windows where
# symlinks require admin/Developer Mode; on macOS/Linux prefer `make install`.
#
# We do not vendor the upstream files (no LICENSE upstream) — each install pulls
# them fresh. See skills/html-reports/references/NOTICE.md.

[CmdletBinding()]
param(
    [switch]$Uninstall,
    [switch]$SkipFetch
)

$ErrorActionPreference = 'Stop'

$RepoDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsSrc = Join-Path $RepoDir 'skills'
$SkillsDst = Join-Path $env:USERPROFILE '.claude\skills'
$RefsDir   = Join-Path $SkillsSrc 'html-reports\references'

if (-not (Test-Path $SkillsSrc)) {
    Write-Error "Source directory not found: $SkillsSrc"
    exit 1
}

New-Item -ItemType Directory -Force -Path $SkillsDst | Out-Null

$skillDirs = Get-ChildItem -Path $SkillsSrc -Directory

if ($Uninstall) {
    foreach ($skill in $skillDirs) {
        $dst = Join-Path $SkillsDst $skill.Name
        if (Test-Path $dst) {
            Remove-Item -Recurse -Force $dst
            Write-Host "  - removed $($skill.Name)"
        }
    }
    Write-Host "Uninstalled."
    exit 0
}

if (-not $SkipFetch) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is required to fetch upstream exemplars. Install git or re-run with -SkipFetch."
        exit 1
    }

    $tmp = Join-Path $env:TEMP ("html-effectiveness-" + [guid]::NewGuid())
    git clone --depth 1 --quiet https://github.com/ThariqS/html-effectiveness.git $tmp
    try {
        New-Item -ItemType Directory -Force -Path $RefsDir | Out-Null
        Get-ChildItem -Path $RefsDir -Filter '*.html' | Remove-Item -Force
        # Skip the upstream landing page (index.html).
        Get-ChildItem -Path $tmp -Filter '*.html' |
            Where-Object { $_.Name -ne 'index.html' } |
            ForEach-Object { Copy-Item -Force $_.FullName $RefsDir }
        $count = (Get-ChildItem -Path $RefsDir -Filter '*.html').Count
        Write-Host "Fetched $count exemplar files from ThariqS/html-effectiveness."
    }
    finally {
        Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    }
}

foreach ($skill in $skillDirs) {
    $dst = Join-Path $SkillsDst $skill.Name
    if (Test-Path $dst) {
        Remove-Item -Recurse -Force $dst
    }
    Copy-Item -Recurse -Force -Path $skill.FullName -Destination $dst
    Write-Host "  + $($skill.Name) -> $dst"
}

Write-Host ""
Write-Host "Installed skills into $SkillsDst"
Write-Host "Refresh later by re-running this script after a git pull."
