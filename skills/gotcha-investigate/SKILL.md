---
name: gotcha-investigate
description: Investigate a bug or dysfunction against the project memory first (troubleshooting cards, theme maps, entity pages), diagnose from evidence, then write every durable finding back — a new symptom card, a bumped seen counter, a repair handle. Use when the user reports a bug, an incident, a failing integration, an unexplained behaviour, pastes an error or a stack trace, or asks why something broke.
argument-hint: "<symptom, error message, entity name, or ticket id>"
---

# gotcha-investigate

Diagnosis first, fix second. Never apply a fix before the root cause is
established and the user asked for one.

Read `gotchas/manifest.yml` first — scopes, routing, evidence commands. No
manifest ⇒ run `/gotcha-init`, or proceed without a base and say it is missing.

**Local knowledge first.** Do not search the web, partner docs or specs before
exhausting Phase 1. If an online lookup does turn out to be necessary, its
result MUST land in the base in Phase 6 so the next investigation does not need
it. That write-back is what makes the second occurrence of a bug cheap.

## Phase 1 — Recall

Follow the gotcha-recall procedure, symptom path:

1. **Grep the cards** with the distinctive fragment of the error or symptom
   (`grep -rniF -e "<fragment>" gotchas/troubleshooting`). Read only the
   matching cards.
2. **A card matches** ⇒ run its **Check**. Confirmed ⇒ you have the cause; go
   to Phase 5 with the card's Fix and Repair. Bump the card in Phase 6.
3. No card ⇒ classify into a theme via `troubleshooting/INDEX.md`, read that
   theme's **Map** (exceptions, swallowed errors, log patterns, repair handles),
   then the entity page if the symptom names one.
4. Check `decisions.md` for the behaviour. A large share of reported "bugs" are
   **documented deliberate behaviour** — rate-limit cursor saves,
   fire-and-forget deliveries, skipped malformed input. If it matches, say so
   and stop; that is a successful outcome.

## Phase 2 — Gather evidence

Facts, not hypotheses. Rough priority:

1. **Exact error** — quote it verbatim. Map it to the theme Map. Locate the
   throw site.
2. **Logs** — build the query from the manifest's `evidence.logs` and the
   documented log patterns. No access from here ⇒ give the exact query to run,
   do not guess its result.
3. **State** — the rows, cursors, cache keys, dead-letter queues and config the
   failing path reads. Query them; never assume.
4. **Reproduction** — an existing test next to the flow, or `evidence.repro`.

State plainly which evidence you could not obtain.

## Phase 3 — Trace the path

Entry point → application → domain → external adapter. At every hop note what
is validated, caught and swallowed, retried, logged. The gap between "what is
logged" and "what happened" is where the root cause hides. Cite `file:line`.

## Phase 4 — Hypothesis and refutation

1. State the root cause with its evidence chain, cited.
2. **Try to refute it.** What else produces this exact symptom? Rule out config
   vs. code vs. data vs. remote side vs. infrastructure explicitly.
3. Verify by reproduction where feasible.

## Phase 5 — Report

**Symptom → Evidence → Root cause → Blast radius → Proposed fix (not applied)
→ Repair path for existing bad state.**

The repair path is often the urgent half: the code fix stops new damage, the
repair handle fixes the rows already corrupted. Wait for an explicit request
before changing code.

## Phase 6 — Write back (mandatory)

In the same change set, per `${CLAUDE_PLUGIN_ROOT}/references/capture-contract.md`
("From investigation"):

- **A card matched** ⇒ bump `seen` and `last`; sharpen its Check if you found a
  faster one; re-stamp `verified` if you re-checked the cause in code.
- **No card matched** ⇒ write a new `TS-NNN` card in the theme (id from
  `scripts/stats.sh`). Keywords = the literal strings the reporter pasted. The
  Check line is the valuable half.
- **New failure mode, log pattern or repair handle** ⇒ the theme's Map.
- **The doc was wrong** ⇒ fix it in place, cite the proof.
- **Learned it online** ⇒ capture it with its source.

Then run `scripts/stats.sh` and tidy any page you pushed over its caps. List the
pages touched at the end of the report.
