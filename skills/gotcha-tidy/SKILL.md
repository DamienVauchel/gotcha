---
name: gotcha-tidy
description: Reorganize the project memory so it stays cheap to read — split troubleshooting themes that grew too large, merge themes that stayed tiny, archive cold cards, re-sort cards by how often they resolved a task, collapse the L0 index into hubs, and write missing TL;DRs. Use when scripts/stats.sh flags a page (SPLIT, MERGE?, COLD, INDEX>60, NO_TLDR, UNINDEXED), after a capture pushed a page over its caps, or when the user asks to tidy, reorganize or restructure the knowledge base.
argument-hint: "[page or theme to limit the pass to — defaults to every flagged page]"
---

# gotcha-tidy

The base organizes itself around the problems people actually hit, not around
the code layout. This is the mechanism. It changes **structure only** — never
the facts. Rules and thresholds: `${CLAUDE_PLUGIN_ROOT}/references/organization.md`.

## 1. Measure

```sh
sh ${CLAUDE_PLUGIN_ROOT}/scripts/stats.sh gotchas
```

Work only the flagged pages (or the argument). No flag ⇒ say so and stop.

## 2. Apply, per flag

| Flag | Do |
|---|---|
| `SPLIT(cards)` | Read the theme's card headings and keyword lines only (`grep -n -A1 "^### TS-"`). Cluster by **cause** (shared cited files, shared keywords). 2–4 sub-themes named `<parent>-<facet>.md`. Move cards verbatim, split the Map with them, delete the parent |
| `SPLIT(lines)` | Same, by `##` section. A module page splits into `modules/<area>-<part>.md` |
| `MERGE?` | Append cards and Map rows to the closest theme (by keywords), delete the source. Ask first if the closest theme is not obvious |
| `COLD` | Archive cards that are cold **and** either cite missing code (`scripts/stale.sh <page>`) or were seen ≤ 1 time. Move verbatim to `troubleshooting/_archive.md` under a `## <former theme>` heading |
| `INDEX>60` | Collapse the largest `INDEX.md` section into a hub page (`modules/INDEX.md`, `entities/INDEX.md`, …) and leave one line pointing to it |
| `NO_TLDR` | Write the TL;DR from the page's own content: what it is for and its one or two most-used facts |
| `UNINDEXED` | Add its hook line to the right index, or merge it if it duplicates a page |

Then, for every theme touched: **re-sort cards by `seen` descending** (ties: most
recent `last` first), and rewrite its row in `troubleshooting/INDEX.md` — keywords
are the union of the most distinctive card keywords, card count, newest `last`.

## 3. Verify

- `scripts/stats.sh` again: no flag left on the pages you touched.
- Every card id that existed before still exists exactly once
  (`grep -rhoE "^### (TS|D)-[0-9]+" gotchas | sort | uniq -d` prints nothing).
- Every link in the indexes resolves to a file.

## 4. Report

One line per structural change: `split webhooks.md → webhooks-signature.md (6), webhooks-delivery.md (9)`.

## Rules

- **Move, never rewrite.** A card leaves a tidy pass byte-identical except for
  its position. Changing a fact is `/gotcha-capture`'s job, reviewing one is
  `/gotcha-lint`'s.
- **Never delete a card.** Archive it.
- **Ids are forever.** Cross-references are by id, so moving cards breaks
  nothing — do not renumber.
- One tidy pass per change set. Structure churn on top of fact changes makes the
  PR unreviewable; if both are big, tell the user to split them.
