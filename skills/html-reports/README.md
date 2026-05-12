# html-reports skill

Routes HTML report requests to exemplar files cloned from
github.com/ThariqS/html-effectiveness, then adapts them to user data.

Built and installed by Claude Code.

## Refresh exemplars

```bash
~/.claude/skills/html-reports/install-references.sh
```

## Files

- `SKILL.md` — routing table and authoring rules (the skill itself)
- `references/` — 20 exemplar HTML files (the design system source of truth)
- `install-references.sh` — re-clone the upstream repo and refresh `references/`
