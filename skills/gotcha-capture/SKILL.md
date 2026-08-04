---
name: gotcha-capture
description: Harvest what a piece of work taught you into the gotcha knowledge base — collects `gotcha:` markers left in the code, scans the change set for durable findings, routes each one per the capture contract, and deletes the harvested markers. Use at the end of a feature, an integration, or any task that touched an external system; also when the user asks to capture, harvest, or write findings to the knowledge base.
argument-hint: "[branch, path or diff range to harvest from — defaults to the uncommitted change set]"
---

# gotcha-capture

Feature work is the richest source of knowledge in the system and the one that
loses it. Debugging at least ends in a report; building ends in a merge, and what
the integration taught you evaporates.

Read `gotchas/manifest.yml` for routing and
`${CLAUDE_PLUGIN_ROOT}/references/capture-contract.md` for the durability test,
the per-trigger filters and the writing rules. Apply that contract — it is the
authority, this skill is only the procedure.

No manifest ⇒ run `/gotcha-init` first.

## Phase 1 — Harvest the markers

Search the change set (or the whole subject if no diff is given) for `gotcha:`
markers in any comment syntax:

```
grep -rn "gotcha:" <subject> --include=* | grep -v "^.*gotchas/"
```

Each marker is a **pending** capture. For each one: read the surrounding code so
the fact gets a real `file:line` citation rather than a paraphrase of the note.

## Phase 2 — Scan the change set

Markers catch what you remembered to note. This catches what you did not.

Review the diff for the shapes the contract lists under "From feature work". In
practice, look for:

- a new `catch` that logs and continues, a new early `return` that drops work, a
  new default that hides an absent value — every one is a future silent failure
- a value chosen for a non-obvious reason: a timeout, a batch size, a tolerance,
  a retry count. Why *that* number?
- a new external integration, endpoint, or provider — its quirks belong on an
  entity page now
- a workaround: anything shaped "the remote side does X so we have to Y"
- an alternative you considered and rejected. If the diff looks like it argued
  with itself, the argument is the knowledge

Do not invent. A finding you cannot cite or verify is not captured — at most it
becomes `_Unknown — not confirmed in code_` on the relevant page.

## Phase 3 — Filter

Run every candidate through the three-part durability test in the contract. Be
ruthless: most of a feature diff is code being readable, which is the opposite of
something worth remembering.

Discarding a candidate is the normal outcome. A capture run that writes nothing
is a valid run — say so and stop.

## Phase 4 — Propose

Show the user, before writing anything:

| Finding | Destination | Source |
|---|---|---|
| one line | page per the routing table | marker at `file:line`, or diff |

Plus the markers you will delete, and the candidates you discarded with a
one-word reason. The discard list matters: it is how the user catches a filter
that is too aggressive.

Get confirmation.

## Phase 5 — Write

1. Apply each finding to its page per the contract's writing rules.
2. Delete every harvested marker from the code.
3. Update `gotchas/INDEX.md` if a page was added.
4. Report the pages touched and the markers removed.

Everything lands in the **current change set**, so a human reviews each fact in
the PR before it becomes doctrine. That review is the point — never write to the
base outside a change the user is about to look at.

## Rules

- Never fabricate a citation. If the fact came from a partner conversation or a
  web page, cite that instead.
- Never delete a marker without either writing its fact or confirming the fact is
  already in the base.
- Do not restructure existing pages. Add to them.
