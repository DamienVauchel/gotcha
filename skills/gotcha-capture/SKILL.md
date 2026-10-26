---
name: gotcha-capture
description: Write back into the project memory (gotchas/) what a task taught you that the docs did not hold — answers you had to dig for in the code, docs found wrong, conventions, trade-offs, external quirks, new entities, `gotcha:` markers left in the code. Routes each finding per the capture contract, stamps it, and keeps the base within its size caps. Use at the end of any task that changed code or required exploring it, when the gotcha Stop hook asks for a write-back, or when the user asks to capture, harvest, document, or update the docs.
argument-hint: "[branch, path or diff range to harvest from — defaults to this task and the uncommitted change set]"
---

# gotcha-capture

The write-back half of the loop. It runs after most tasks, so it must be **fast
when there is nothing to write** and **precise when there is**.

The authority is `${CLAUDE_PLUGIN_ROOT}/references/capture-contract.md`
(durability test, triggers, routing, writing rules, modes). Page shapes are in
`page-format.md`. This skill is only the procedure.

No `gotchas/manifest.yml` ⇒ suggest `/gotcha-init` and stop.

## Phase 1 — Collect candidates

From three sources, cheapest first:

1. **This task.** What you just did: what the base lacked (you had to read the
   code for it), what it got wrong, which card answered, what trade-off you
   made, what the external system did that surprised you.
2. **`gotcha:` markers** in the change set (or the subject if a range is given):
   `git grep -n "gotcha:" -- . ':(exclude)gotchas'`. Read around each marker so
   the fact gets a real `file:line`, not a paraphrase of the note.
3. **The diff** (`git diff`, or the given range), for what nobody noted: a new
   `catch` that logs and continues, a new early `return` that drops work, a
   constant chosen for a non-obvious reason (why *that* timeout?), a new
   integration, a workaround shaped "the remote does X so we must Y", an
   alternative visibly considered and rejected.

Do not invent. A finding you cannot cite or verify is not captured — at most it
becomes `_Unknown — not confirmed in code_` on the relevant page.

## Phase 2 — Filter

Run every candidate through the durability test. Be ruthless: most of what a
task touches is code being readable.

**Discarding everything is the normal outcome of a small task.** If nothing
passes, reply `gotcha: nothing durable` and stop — no table, no explanation.

## Phase 3 — Route and dedupe

For each survivor, pick the destination from the routing table. Before writing,
check it is not already there:

```sh
grep -rniF -e "<key term>" gotchas/
```

- Already present and right ⇒ nothing to write (a card ⇒ bump `seen` / `last`).
- Present and wrong or stale ⇒ **fix in place**, cite the proof, re-stamp.
- Absent ⇒ add it.

## Phase 4 — Write (or propose)

Mode is `manifest.yml` `autocapture:` — `auto` unless set.

- **`propose`** — show one table first, then write what the user accepts:

  | Finding | Destination | Source |
  |---|---|---|
  | one line | page § section, or new card | marker at `file:line`, diff, or this task |

  Plus the discarded candidates with a one-word reason — how the user catches a
  filter that is too aggressive.
- **`auto`** — write directly. The PR is the review.

Writing:

1. Read only the target section (`grep -n "^## \|^### "` for offsets), not the
   whole page.
2. Apply the writing rules. New card ids come from
   `sh ${CLAUDE_PLUGIN_ROOT}/scripts/stats.sh gotchas` (`next ids:`).
   Stamp `verified <today> @ $(git rev-parse --short HEAD)`.
3. Delete every harvested marker from the code.
4. A new page ⇒ its line in `INDEX.md` or its hub.

**Many findings, or target pages not yet in context** (≥ 3 destinations) ⇒
delegate the writing to the `gotcha-scribe` agent with the list of findings
(fact, citation, destination). It reads the pages in its own context and returns
one line per write; yours stays clean.

## Phase 5 — Keep it organized

Run `scripts/stats.sh`. If a page you touched is flagged `SPLIT`, `INDEX>60`,
`NO_TLDR` or `UNINDEXED`, apply `/gotcha-tidy` to that page only.

## Phase 6 — Keep the human docs in step

`manifest.yml` `publish_when: on-change` (the default when `docs` is a channel; remote
channels are always manual) ⇒ run `/gotcha-publish` for the pages you changed,
`docs` channel only. `manual` ⇒ skip; the
session-start hook will mention the pages behind.

Report in one line: `gotcha: <n> facts → <pages>` (plus markers removed, plus
`published: <n> pages` if any).

## Rules

- Never fabricate a citation. If the fact came from a conversation or a web
  page, cite that instead.
- Never delete a marker without either writing its fact or confirming it is
  already in the base.
- Never write the base outside the current change set: the review in PR is what
  turns an agent's note into team doctrine.
