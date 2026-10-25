# Organization rules

How the base keeps itself small enough to be cheap. Applied by `/gotcha-tidy`,
and checked by `gotcha-capture` after every write. `scripts/stats.sh` reports
which rule a page breaks, so nobody has to read pages to find out.

The goal is a fixed cost per question: one index line, one hub line, one card —
whatever the size of the base.

## Thresholds

| Rule | Threshold | Action | `stats.sh` flag |
|---|---|---|---|
| L0 index too long | `INDEX.md` > 60 lines | collapse a section into a hub page, link the hub | `INDEX>60` |
| Page too long | > 300 lines | split by section into sibling pages | `SPLIT(lines)` |
| Theme too large | > 15 cards | split into 2–4 sub-themes | `SPLIT(cards)` |
| Theme too small | < 3 cards and nothing seen for 6 months | merge into the closest theme | `MERGE?` |
| Cold cards | `last` older than 12 months | move to `troubleshooting/_archive.md` | `COLD` |
| Missing TL;DR | no `> **TL;DR**` block | write it | `NO_TLDR` |
| Orphan page | not linked from any index | link it, or merge it | `UNINDEXED` |

The numbers can be overridden with environment variables (`GOTCHA_INDEX_MAX`,
`GOTCHA_PAGE_MAX`, `GOTCHA_CARDS_MAX`, `GOTCHA_CARDS_MIN`, `GOTCHA_COLD_DAYS`).
Do not tune them per page.

## Splitting a theme

Themes grow from the symptoms people actually hit, not from the code layout.
`/gotcha-init` seeds one theme per scope; real incidents decide the rest.

1. Cluster the cards by **cause**, not by symptom wording. Use keywords and the
   cited files: cards citing the same mechanism belong together.
2. Two to four clusters. A cluster of one stays with its nearest neighbour.
3. Name each new theme after what the reader is facing, kebab-case, prefixed by
   the parent: `webhooks-signature.md`, `webhooks-delivery.md`.
4. Split the **Map** too: each exception / log pattern goes with the cards that
   cite it. Shared entries go to the most specific theme and get a one-line
   pointer elsewhere.
5. Cards keep their ids. Delete the parent page. Update
   `troubleshooting/INDEX.md`, and `INDEX.md` if it listed the parent.

## Merging

The inverse: append the cards and map rows to the target theme, union the
keywords in the hub line, delete the source page.

## Archiving

Archive a card — never delete it — when it is cold **and** at least one of:
its cited code is gone (`stale.sh` says `missing`), or it has been seen at most
once. A cold card whose code is still there and which was seen often stays: it
is a rare but real failure, which is exactly what the base is for.

`_archive.md` is not indexed and costs nothing until someone greps it. A card
that resolves a task again moves back to a live theme with `seen` bumped.

## Ordering

Inside a theme, cards are sorted by `seen` descending, so the first card read is
the most likely answer. Only `/gotcha-tidy` re-sorts: capture appends, so
ordinary diffs stay small.

## Hubs

When a section of `INDEX.md` outgrows its share (more than ~10 lines),
replace it with a single line pointing to a hub page that holds the full list.
`troubleshooting/INDEX.md` is the hub that always exists. Create `modules/INDEX.md`
or `entities/INDEX.md` the same way when needed. Never nest hubs more than one
level: L0 → hub → page.
