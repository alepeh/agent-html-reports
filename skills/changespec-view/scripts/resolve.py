#!/usr/bin/env python3
"""
Resolve a changespec target (a `changes/<name>/` directory, an
`architecture/` directory, or a single artifact YAML file) into a
single JSON tree with every `{ md: <path> }` prose reference inlined,
every date stringified, and every cross-artifact bundle pre-grouped so
a renderer can consume it without further file I/O.

Usage:
    resolve.py <path>            # autodetect kind
    resolve.py changes/X         # → kind=change
    resolve.py architecture      # → kind=architecture
    resolve.py architecture/decisions/0007-*.yaml   # → kind=artifact

Output: a single JSON document on stdout, structured as:

    kind=change:
        { kind, path, meta, proposal?, design?, tasks?, specs?{cap: {...}} }
    kind=architecture:
        { kind, path, domain_model?, rules?, adrs?[], acceptance?{group: {...}} }
    kind=artifact (single YAML file):
        { kind, path, name, data }

Exit codes:
  0 — resolved successfully
  1 — missing file, malformed YAML, or missing prose md ref
  2 — usage error or missing dependency

Requires PyYAML (`pip install PyYAML`).
"""
from __future__ import annotations

import datetime as _dt
import json
import sys
from pathlib import Path
from typing import NoReturn

try:
    import yaml
except ImportError:
    sys.stderr.write("[resolve] PyYAML not installed. Run: pip install PyYAML\n")
    sys.exit(2)


def fail(msg: str) -> NoReturn:
    sys.stderr.write(f"[resolve] {msg}\n")
    sys.exit(1)


def _stringify_dates(obj):
    if isinstance(obj, dict):
        return {k: _stringify_dates(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_stringify_dates(v) for v in obj]
    if isinstance(obj, _dt.datetime):
        return obj.isoformat(timespec="seconds")
    if isinstance(obj, _dt.date):
        return obj.isoformat()
    return obj


def _resolve_md_refs(obj, base: Path):
    """Replace every `{ md: <path> }` shape with the inlined file contents.
    Path is relative to `base` — the directory containing the YAML file
    that holds the reference. Recurses into dicts and lists."""
    if isinstance(obj, dict):
        if set(obj.keys()) == {"md"} and isinstance(obj["md"], str):
            md_path = (base / obj["md"]).resolve()
            if not md_path.is_file():
                fail(f"prose md ref not found: {md_path} (referenced from {base})")
            return md_path.read_text()
        return {k: _resolve_md_refs(v, base) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_resolve_md_refs(v, base) for v in obj]
    return obj


def load_artifact(path: Path) -> dict:
    if not path.is_file():
        fail(f"file not found: {path}")
    try:
        raw = yaml.safe_load(path.read_text()) or {}
    except yaml.YAMLError as e:
        fail(f"{path}: YAML parse error: {e}")
    return _resolve_md_refs(_stringify_dates(raw), path.parent)


CHANGE_FILES = {
    "meta.yaml": "meta",
    "proposal.yaml": "proposal",
    "design.yaml": "design",
    "tasks.yaml": "tasks",
}

ARCH_NAMED = {
    "domain-model.yaml": "domain_model",
    "rules.yaml": "rules",
}


def resolve_change(change_dir: Path) -> dict:
    out: dict = {"kind": "change", "path": str(change_dir)}
    for name, key in CHANGE_FILES.items():
        f = change_dir / name
        if f.is_file():
            out[key] = load_artifact(f)
    specs_dir = change_dir / "specs"
    if specs_dir.is_dir():
        specs: dict = {}
        for cap_dir in sorted(p for p in specs_dir.iterdir() if p.is_dir()):
            spec_file = cap_dir / "spec.yaml"
            if spec_file.is_file():
                specs[cap_dir.name] = load_artifact(spec_file)
        if specs:
            out["specs"] = specs
    return out


def resolve_architecture(arch_dir: Path) -> dict:
    out: dict = {"kind": "architecture", "path": str(arch_dir)}
    for name, key in ARCH_NAMED.items():
        f = arch_dir / name
        if f.is_file():
            out[key] = load_artifact(f)
    decisions_dir = arch_dir / "decisions"
    if decisions_dir.is_dir():
        adrs = [load_artifact(f) for f in sorted(decisions_dir.glob("*.yaml"))]
        if adrs:
            out["adrs"] = adrs
    accept_dir = arch_dir / "acceptance"
    if accept_dir.is_dir():
        acceptance: dict = {
            f.stem: load_artifact(f) for f in sorted(accept_dir.glob("*.yaml"))
        }
        if acceptance:
            out["acceptance"] = acceptance
    return out


def resolve_single(yaml_file: Path) -> dict:
    return {
        "kind": "artifact",
        "path": str(yaml_file),
        "name": yaml_file.name,
        "data": load_artifact(yaml_file),
    }


def detect_and_resolve(target: Path) -> dict:
    if target.is_file():
        return resolve_single(target)
    if target.is_dir():
        if (target / "meta.yaml").is_file():
            return resolve_change(target)
        markers = [
            target / "domain-model.yaml",
            target / "rules.yaml",
            target / "decisions",
            target / "acceptance",
        ]
        if any(m.exists() for m in markers):
            return resolve_architecture(target)
        fail(
            f"could not detect kind for: {target} "
            "(no meta.yaml, no architecture markers)"
        )
    fail(f"path does not exist: {target}")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        sys.stderr.write("usage: resolve.py <path>\n")
        return 2
    target = Path(argv[1]).resolve()
    result = detect_and_resolve(target)
    json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
