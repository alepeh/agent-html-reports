---
name: changespec-view
description: Render a YAML changespec (a `changes/<name>/` directory or an `architecture/` directory from an SDLC-bootstrapped project) into a single-file HTML view that matches the html-effectiveness design system. Reads typed YAML artifacts (meta, proposal, design, tasks, capability spec deltas, ADRs, distilled rules, domain model, acceptance criteria) plus their referenced .md prose files, and projects each artifact onto the appropriate exemplar pattern. Auto-triggered when the user asks to render, view, visualize, or generate HTML for a change, ADR, domain model, rules registry, or any other SDLC artifact produced by the changespec-schema skill.
---

# Changespec view

Produce a single-file HTML view for an SDLC changespec. Takes structured
YAML data + prose .md files as input, emits a styled HTML report that
matches the html-effectiveness design system as a rich projection for
human review.

The companion skill **changespec-schema** (in the `incunabula` repo)
owns the data model — JSON Schemas for every artifact, the
inline-prose-vs-MD-ref split rule, the example fixture changeset. Read
its `SKILL.md` before rendering. This skill renders **what's there**;
it does not author or modify YAML.

This skill **inherits the design system** from the **html-reports**
skill. Read `html-reports/SKILL.md` and the exemplar files it routes
to before producing any HTML. Same tokens, same component vocabulary,
same one-file/no-externals constraint. The only thing different is
*what* gets rendered.

---

## Step 1 — Identify the target

The user will point at one of:

| Target type | What it points at | Output filename |
|---|---|---|
| Single change | `changes/<name>/` | `<name>.html` |
| Architecture pack | `architecture/` | `architecture.html` |
| Domain model | `architecture/domain-model.yaml` | `domain-model.html` |
| Single ADR | `architecture/decisions/NNNN-<slug>.yaml` | `adr-NNNN-<slug>.html` |
| Rules registry | `architecture/rules.yaml` | `rules.html` |
| Acceptance group | `architecture/acceptance/<group>.yaml` | `acceptance-<group>.html` |
| Archived change | `changes/archive/YYYY-MM-DD-<name>/` | `<name>.html` |

If the user is ambiguous ("render the change"), list active changes
(`changes/<name>/` excluding `archive/`) and ask via `AskUserQuestion`.

---

## Step 2 — Resolve the data

Use `scripts/resolve.py` (under this skill) to flatten a target into a
single resolved JSON tree:

```bash
python3 ~/.claude/skills/changespec-view/scripts/resolve.py changes/<name>
```

The resolver:

- Loads every YAML artifact in the target tree
- Resolves every `{ md: ./path/to/file.md }` reference by inlining the
  file contents as a string under the same key
- Stringifies dates to ISO format
- Returns one JSON document on stdout that the renderer consumes
  without further file I/O

Read that JSON. **Do not** chase the original YAML files or `.md` refs
yourself — the resolver has done that work.

Optionally validate first by calling the validator from incunabula:

```bash
python3 tools/validate.py changes/<name>     # if the project copied tools
# OR
CHANGESPEC_SCHEMAS=~/.claude/skills/changespec-schema/schemas \
  python3 ~/.claude/skills/change-protocol/scripts/validate.py changes/<name>
```

Refuse to render a changeset that fails validation — fix the YAML first.

---

## Step 3 — Pick projections per artifact type

The skill routes each artifact onto an existing **html-reports**
exemplar. Read the exemplar file before composing the section.

| Artifact YAML | Exemplar to adapt from | Notes |
|---|---|---|
| `meta.yaml` + `proposal.yaml` (or change summary) | `references/17-pr-writeup.html` | The "change overview" panel: type pill, status row, why-and-what summary, capabilities list. |
| `design.yaml` | `references/15-research-concept-explainer.html` | Context → rationale → decisions table → risks → rollback. The 9-item `domain_impact.checklist` renders as a status band; each item a card colored by `checked`. |
| `tasks.yaml` | `references/16-implementation-plan.html` or `references/18-editor-triage-board.html` | Phases as columns or sections, tasks as rows. Done count vs total in a stat band at top. |
| `spec.yaml` (delta) | `references/14-research-feature-explainer.html` | Four delta buckets (`added`/`modified`/`removed`/`renamed`) as separate panels. Each requirement card lists scenarios with verb pills (GIVEN/WHEN/THEN/AND/BUT). |
| `adr.yaml` | `references/17-pr-writeup.html` (decision card) | Status pill, context, decision, three-column consequences (easier/harder/neutral), rules-produced as `R-NNN` pills linking back to rules.html. |
| `rules.yaml` | `references/11-status-report.html` (table) | Filterable table with R-NNN | title | category | source | rule. Provenance column links back to its source change. |
| `domain-model.yaml` | `references/13-flowchart-diagram.html` + table | ERD-style SVG of bounded contexts → aggregates → concepts using `relationships[]`. Below it: invariants list, glossary table. Enum concepts render `enum_values` as inline pills. |
| `acceptance/<group>.yaml` | `references/11-status-report.html` | Each AC as a row colored by `status`: olive = implemented, clay = partial, gray-500 = specified. Test path in mono. |

When the target is a **whole change** (`changes/<name>/`), compose the
artifacts in lifecycle order under one `<main>`: change overview →
proposal → design → spec deltas → tasks. Don't render an artifact that
isn't present; don't emit empty placeholder panels.

When the target is `architecture/`, compose: domain model → rules
registry → ADR index → acceptance index, each as its own section with
in-page anchors and a top-of-page nav.

---

## Step 4 — Render

Follow the html-reports SKILL's "Step 3 — Adapt, don't re-invent" and
"Step 4 — Honour these absolutes" rules verbatim:

- One file, no externals
- Copy the `:root` token block verbatim from the chosen exemplar
- Reuse class names from the exemplar — they are the public API
- Match the editorial voice
- No box-shadows, no gradients, system fonts only
- Compute SVG geometry from real data (ERD coordinates, status bars, etc.)
- Always include the auto-generated pill and footer with provenance
  (this skill's name + `changes/<name>/` + timestamp)

**Two extensions specific to changespecs:**

1. **Prose blocks** — render each resolved `prose` string (originally
   inlined or fetched from a `.md` ref) inside a panel using the
   exemplar's existing prose styling. Treat the content as markdown:
   support headings, lists, fenced code blocks, links, inline code.
   Use the same body-text type scale as the surrounding panel.
2. **Cross-references** — `R-NNN`, `ADR-NNNN`, `AC-<GROUP>-NN`, `I-NNN`
   IDs anywhere in rendered content become anchor links to the
   corresponding section within the HTML (when both endpoints render in
   the same file) or to the source filename in a sibling output. Use
   `--clay` for these links to match the exemplar's link styling.

---

## Step 5 — Output

- Write the final file at `<output_dir>/<filename>.html` (default
  output dir is the project's `architecture/review/` directory if it
  exists, otherwise the current working directory).
- Tell the user which exemplar(s) were adapted and which artifacts
  were rendered.
- Suggest the next action if obvious (e.g. "rules.yaml is empty — the
  rules registry section is omitted. Run `/sdlc:archive` on the
  in-flight change to start populating it.").

---

## Fallback when exemplars aren't cached

If `~/.claude/skills/html-reports/references/` is empty (the user
hasn't run `install-references.sh` yet), fetch the relevant exemplar
on-demand via `WebFetch` from
`https://github.com/ThariqS/html-effectiveness/blob/main/<filename>`
and proceed. Tell the user to cache the exemplars locally for next time.

---

## Conventions specific to changespecs

- **Status pills** match the AC status enum: `implemented` → olive,
  `partial` → clay (with warning border-left treatment from the
  exemplar), `specified` → gray-500. Same palette for change-meta
  `domain_impact` (`none` neutral, `additive` olive, `breaking` rust).
- **Task-done state** — render `done: true` with a check glyph + olive
  text; `done: false` with the empty-circle glyph + slate. Don't recolor
  the surrounding row.
- **Domain-impact checklist** — 9 cards in a 3×3 grid, colored
  olive when `checked: true`, neutral when false, with the optional
  `note:` field as a body line under the item name.
- **Spec-delta scenarios** — render each step as an indented row with
  the verb (GIVEN/WHEN/THEN/AND/BUT) as a small mono pill in
  `--gray-500`, followed by the predicate text in `--slate`.
- **Provenance footer** — every rendered HTML includes a footer block
  with the source path (`changes/<name>/` or `architecture/`),
  generation timestamp, and the schema versions used (read the schema
  filenames; future-proofing for when we add `$id` versioning).

---

## What this skill does NOT do

- **Author or modify YAML.** Read-only renderer for v1. Edits to a
  changespec go through the `/sdlc:*` commands.
- **Execute tests, run validators by default, or check AC gates.**
  Suggest those (the user can run `/sdlc:verify`). The renderer's job
  is faithful projection of the current state.
- **Re-state the html-reports design system.** Always read the
  exemplar(s) — they are the source of truth.

---

## Out of scope — see sibling skills

- **`html-reports`** — the parent design system. Same tokens, same
  rules, same exemplar references.
- **`changespec-schema`** (in `incunabula`) — the JSON Schemas for
  every artifact, the prose split rule, the example fixture.
- **`change-protocol`** (in `incunabula`) — lifecycle policy, when each
  artifact gets written and by which `/sdlc:*` command.
- **`solution-review-pack`** (in `incunabula`) — the curated
  three-HTML review pack (Requirements / SAD / Implementation
  Overview). Borrows this skill's design tokens and per-artifact
  projection patterns, then composes them into a reviewer-targeted
  narrative with attribution back to bootstrap answers. If a user
  asks for a "review pack" or "Solution Architecture Document",
  that skill takes precedence; this one is for per-artifact reads.
