# Agents

Three sub-agents keep bulk reading and writing **out of your main context**. They are a token-budget tool, not a ritual: below their thresholds the skills do the work inline.

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":40,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart LR
  classDef service fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px,color:#1f2937
  classDef store fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef ok fill:#d5e8d4,stroke:#82b366,stroke-width:1.5px,color:#1f2937

  code[("<b>code</b>")]:::store
  sv("<b>gotcha-surveyor</b><br/><small>read-only · one per area</small>"):::service
  init("<b>/gotcha-init</b>"):::ok
  fnd("<b>findings</b><br/><small>verified</small>"):::ok
  sc("<b>gotcha-scribe</b><br/><small>routes · dedupes · stamps</small>"):::service
  base[("<b>gotchas/</b>")]:::store
  pub("<b>gotcha-publisher</b><br/><small>narrates · draws</small>"):::service
  out[("<b>docs · remote</b>")]:::store

  code --> sv --> init
  fnd --> sc --> base
  base --> pub --> out
```

*Each agent reads in its own context and returns one line per item.*

| Agent | Tools | Spawned by | When | Returns |
|---|---|---|---|---|
| `gotcha-surveyor` | Read, Grep, Glob, Bash (**read-only**) | `/gotcha-init` | one per area, **in parallel**, when there are more than 3 areas or a large repo | a structured, fully cited findings report (≤ ~250 lines): role, entry points, flows, invariants, where to change X, conventions, decisions, exceptions, swallowed errors, log patterns, repair handles, entities, glossary, unknowns |
| `gotcha-scribe` | Read, Grep, Glob, Edit, Write, Bash | `/gotcha-capture` | ≥ 3 destinations, or target pages not yet in context | one line per write: `+ TS-031 …` · `~ modules/charge.md § Flows (fixed)` · `↑ TS-014 seen 4` · `= skipped (already in D-003)` |
| `gotcha-publisher` | Read, Grep, Glob, Write, Edit, Bash | `/gotcha-publish` | more than 2 outputs, one per group of related outputs, in parallel | one line per page: `+ docs/modules/charge.md (3 diagrams) ← modules/charge.md, decisions.md` (remote pages include id and URL) |

## `gotcha-surveyor` — how it reads

Breadth first, then depth where it pays: list the area → find entry points (routes, consumers, CLI, jobs) → follow the 2–3 most important flows end to end (hot files from `git log` first) → sweep failure semantics (`catch`, `rescue`, `|| true`, `return null`, `TODO`, `HACK`, `deliberately`) → read the throw site of every custom exception. It stops when another file would only confirm what it already knows.

> [!WARNING]
> Never infers behaviour from a name; reads the code at the citation. Never describes what one read of a file makes obvious.

## `gotcha-scribe` — what it will not do

It does **not** investigate: every finding it receives was verified by the caller. It never invents a citation or softens an `_Unknown_` into a claim, and never restructures a page beyond what a cap requires (moving cards, never rewriting them).

## `gotcha-publisher` — the per-page routine

Read the source pages and the cards they reference → plan the page as a reader meets it → **draw first** (diagrams from the [house style](Diagrams)) → write the prose around them in the target language → generated header → write the file or call the connector (update in place by remote id) → `render-diagrams.sh` until it passes.
