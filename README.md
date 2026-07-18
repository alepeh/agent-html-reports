# agent-html-reports

Claude Code skill that produces polished, self-contained HTML reports in the
style of **[html-effectiveness](https://github.com/ThariqS/html-effectiveness)**
by **[Thariq Shihipar](https://github.com/ThariqS)** ([thariq.io](https://thariq.io)).
All credit for the design system, exemplars, and visual language goes to him —
this repo is just routing logic that points Claude Code at his work.

## Install

### macOS / Linux

```bash
make install
```

Symlinks `skills/html-reports/` into `~/.claude/skills/html-reports`. Pulling
new changes in this repo updates the live skill automatically.

```bash
make help     # list targets
make doctor   # report install state
make uninstall
```

### Windows

```powershell
.\install.ps1
```

Copies `skills\html-reports\` into `%USERPROFILE%\.claude\skills\html-reports\`,
overwriting any existing files. Re-run after a `git pull` to refresh.

```powershell
.\install.ps1 -Uninstall
```

## Refresh exemplars

The skill ships with 20 exemplar HTML files cached under
`skills/html-reports/references/`. To pull the latest from upstream:

```bash
make refresh-references
# or directly:
./skills/html-reports/install-references.sh
```

## Layout

- `skills/html-reports/` — the skill itself (SKILL.md, references/, helper script)
- `Makefile` — `install` / `uninstall` / `doctor` / `refresh-references` (symlink-based)
- `install.ps1` — Windows copy-and-overwrite installer

## Scope — design system only

This repo is a **domain-agnostic** design-system reference: `html-reports`
knows nothing about any particular project, and nothing here reads another
repo's data. It is meant to be *copied from*, not to depend on anything
downstream.

The `changespec-view` skill that previously lived here has moved to its real
home in **[incunabula](https://github.com/alepeh/incunabula)** (`skills/changespec-view/`),
because it is coupled to incunabula's changespec YAML artifacts — it belongs
with the data model it renders, not with the design system it borrows from.
`changespec-view` copies its layouts from `html-reports` here; the dependency
runs one way (incunabula → this repo) and never back.

## Credits and licence notice

The exemplar HTML files in `skills/html-reports/references/` come from
[ThariqS/html-effectiveness](https://github.com/ThariqS/html-effectiveness),
**© 2026 Anthropic PBC**, licensed under the **Apache License, Version 2.0**.
Each file carries an SPDX header (`SPDX-License-Identifier: Apache-2.0`).

Apache-2.0 permits use, modification, and redistribution provided you retain
the copyright notice and license and state any significant changes. So:

- This repo still fetches the exemplars from upstream on install (`make install`
  / `.\install.ps1`, via `skills/html-reports/install-references.sh`) rather
  than committing them — that's now a size/staleness choice, **not** a legal
  requirement (the "no LICENSE, all rights reserved" situation no longer
  applies).
- Only the routing logic (`SKILL.md`, helper scripts, this README) is original
  to this repo and is MIT-licensed (see `LICENSE`).

If you fork or redistribute, keep the Apache-2.0 attribution to Thariq
Shihipar / Anthropic PBC intact.
