---
name: html-reports
description: Use this skill whenever the user asks for an HTML report, dashboard, status update, comparison, ranked list, pivot table, incident write-up, implementation plan, slide deck, flowchart, research summary, or any other self-contained HTML data visualization that needs to look polished and production-grade. Trigger on phrases like "generate a report", "create a dashboard", "make a status update", "analyze and visualize", "summarize as HTML", or any explicit reference to the html-effectiveness style.
---

# HTML Reports Skill

Produce self-contained HTML reports that match the visual quality of github.com/ThariqS/html-effectiveness.

## How this skill works

This skill does **not** compress the design system into prose. Instead it routes the request to the right exemplar(s) in `references/` and instructs you to read them as the source of truth before generating.

## Step 1 — Pick the exemplar(s) that match the request

| User intent | Exemplar to read |
|---|---|
| Status / weekly / monthly report, KPI dashboard | `references/11-status-report.html` |
| Incident, post-mortem, outage report | `references/12-incident-report.html` |
| Implementation plan, roadmap, project plan, Gantt | `references/16-implementation-plan.html` |
| PR / change write-up, decision record, release notes | `references/17-pr-writeup.html` |
| Concept explainer, research summary, feature deep-dive | `references/15-research-concept-explainer.html` |
| Feature explainer, product spec | `references/14-research-feature-explainer.html` |
| Flowchart, architecture diagram, process diagram | `references/13-flowchart-diagram.html` |
| Slide deck, presentation, pitch | `references/09-slide-deck.html` |
| Design system showcase, style guide | `references/05-design-system.html` |
| Component variants, comparison matrix | `references/06-component-variants.html` |
| Code review, code feedback | `references/03-code-review-pr.html` |
| Code walkthrough, explain-this-code | `references/04-code-understanding.html` |
| Multiple solution exploration, options analysis | `references/01-exploration-code-approaches.html` |
| Visual design exploration | `references/02-exploration-visual-designs.html` |
| SVG illustration, diagram art | `references/10-svg-illustrations.html` |
| Triage board, kanban, work queue | `references/18-editor-triage-board.html` |
| Feature flag UI, admin panel | `references/19-editor-feature-flags.html` |
| Prompt tuning UI, config editor | `references/20-editor-prompt-tuner.html` |
| Animation prototype | `references/07-prototype-animation.html` |
| Interaction prototype | `references/08-prototype-interaction.html` |

**Common cross-cutting requests:**
- Ranked list / leaderboard → start from `11-status-report.html` (use its table component, sort by rank)
- Pivot / cross-tab table → start from `11-status-report.html` (extend the table pattern with row/col header bg `--gray-100`)
- A/B test report → combine `11-status-report.html` (stat band + chart) with `15-research-concept-explainer.html` (callout for decision)
- Financial / budget summary → start from `11-status-report.html` (stat band + chart + table)
- Survey results → combine `11-status-report.html` (structure) with `13-flowchart-diagram.html` (per-question SVG bars)

If unsure, default to `11-status-report.html` — it contains the largest set of reusable components.

## Step 2 — Read the exemplar(s) before writing any code

**Mandatory.** Before producing any HTML, use the `Read` tool on the chosen exemplar file(s). Read the full source. Internalize:
- The exact CSS custom properties in `:root`
- The component structure (HTML + class names)
- The pixel-precise spacing values
- The SVG chart geometry conventions
- The editorial voice in highlights and callouts

If you skip this step, the output will not match the design system. The whole point of this skill is that the exemplars *are* the design system.

## Step 3 — Adapt, don't re-invent

When generating the output:
- **Copy the `:root` block verbatim** from the exemplar. Do not change the color tokens or font stacks.
- **Reuse class names and selectors** from the exemplar (`.stat-card`, `.shipped` table, `.highlights`, `.carryover`, `.chart-panel`, `.risk-dot`, etc.). They are the public API of this design system.
- **Match the editorial voice** of the exemplar's text content — bold lead phrase + body sentence in highlights; short attribution in `--gray-500`; mono font for IDs, timestamps, and tags.
- **Compute SVG geometry from real data.** Bars: `bar_y = baseline_y - (value/max) * chart_height`. Never use placeholder pixel values.
- **Use the warning card pattern** (`border-left: 4px solid var(--clay); padding-left: 19px`) for any stat card that needs attention.
- **For tables, use `border-collapse: separate; border-spacing: 0`** — this is what enables the rounded panel look. Never use `border-collapse: collapse`.

## Step 4 — Honour these absolutes

- **One file, no externals.** All CSS in a `<style>` block. No CDN scripts, no Google Fonts, no Tailwind, no Chart.js.
- **No box-shadows.** This design uses borders, not shadows.
- **No gradients.** Flat colour fills only.
- **System fonts only.** `ui-serif, Georgia, serif`, `system-ui, -apple-system, sans-serif`, `ui-monospace, 'SF Mono', Menlo, monospace`.
- **No placeholder content.** Every number, label, and bullet must reflect the actual user-provided data. If a field has no data, omit it rather than inventing.
- **Always include the auto-generated pill and footer with provenance** (data source + timestamp), per the exemplar.

## Step 5 — Output

- Write the final file to the project's output directory (or `./` if none specified) with a descriptive kebab-case filename ending in `.html`.
- Mention which exemplar(s) you adapted in one short sentence after the file.

## Fallback when `references/` is empty

If the `references/` directory has no `.html` files, fall back to fetching the exemplar from GitHub via `WebFetch`:

```
https://github.com/ThariqS/html-effectiveness/blob/main/<filename>
```

Then proceed with Steps 3–5. Tell the user to run `~/.claude/skills/html-reports/install-references.sh` to cache exemplars locally.

## Design system summary (quick reference only — exemplars are the source of truth)

```
Tokens: --ivory #FAF9F5, --slate #141413, --clay #D97757, --oat #E3DACC,
        --olive #788C5D, --rust #B04A3F, --gray-{100,300,500,700}
Fonts:  --serif (ui-serif), --sans (system-ui), --mono (ui-monospace)
Panel:  border 1.5px solid var(--gray-300), radius 12px, bg --white
Page:   max-width 860px, padding 56px 24px 120px, bg --ivory
Accent: --clay for highlights/peaks/links; --olive for positive; --rust for negative
```

This summary is for sanity-checking only. Always read the exemplar file for real implementation details.
