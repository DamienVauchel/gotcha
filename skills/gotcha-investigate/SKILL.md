---
name: gotcha-investigate
description: Investigate a bug or dysfunction against the local gotcha knowledge base first, diagnose from evidence, then write every durable finding back into the knowledge base. Use when the user reports a bug, an incident, a failing integration, an unexplained behaviour, or asks why something broke.
argument-hint: "<symptom, error message, entity name, or ticket id>"
---

# gotcha-investigate

Diagnosis first, fix second. Never apply a fix before the root cause is
established and the user asked for one.

Read `gotchas/manifest.yml` first — it holds this repo's scopes, page paths,
routing table and evidence commands. No manifest ⇒ run `/gotcha-init`, or fall
back to `docs/`-style pages and say the base is missing.

**Local knowledge first.** Do not search the web, partner docs or specs before
exhausting Phase 1. If an online lookup does turn out to be necessary, its
result MUST land in the knowledge base in Phase 6 so the next investigation
does not need it. That write-back is the whole point: it is what makes the
second occurrence of a bug cheap.

## Phase 1 — Classify and load

1. Classify the symptom into one or more `scopes` from the manifest.
2. Read, in this order, stopping when you have enough:
   - `gotchas/failure-modes.md` — the scope section: exceptions, log
     patterns, silent-failure traps, repair handles
   - the entity page when the symptom names one (`gotchas/entities/<x>.md`)
   - any scope-specific rule or doc the manifest points to
3. Check the symptom tables before anything else. A large share of reported
   "bugs" are **documented deliberate behaviour** — rate-limit cursor saves,
   fire-and-forget deliveries, skipped malformed input, disabled features. If
   the symptom matches one, say so and stop; that is a successful outcome.

## Phase 2 — Gather evidence

Facts, not hypotheses. Rough priority:

1. **Exact error** — quote the message and stack verbatim. Map it to the
   exception table. Locate the throw site in code.
2. **Logs** — build the query from the manifest's `evidence.logs` pattern and
   the documented log messages. No access to the log platform from this
   context ⇒ output the exact query for the user to run, do not guess its
   result.
3. **State** — the rows, cursors, cache keys, dead-letter queues and config
   values that the failing path reads. Query them explicitly; never assume.
4. **Reproduction** — prefer an existing test next to the failing flow, or the
   manifest's `evidence.repro` command.

State plainly which of these you could not obtain. An investigation with
missing evidence is fine; one that hides which evidence is missing is not.

## Phase 3 — Trace the path

Follow the flow end to end: entry point → application layer → domain →
external adapter. At every hop note four things: what is validated, what is
caught and swallowed, what is retried, what is logged. The gap between "what
is logged" and "what happened" is where the root cause hides. Cite
`file:line` at each hop.

## Phase 4 — Hypothesis and refutation

1. State the root cause with its evidence chain, `file:line` cited.
2. **Try to refute it.** What else produces this exact symptom? Rule out the
   competing families explicitly: config vs. code vs. data vs. remote side vs.
   infrastructure. A hypothesis that survived no refutation attempt is a guess.
3. Verify by reproduction where feasible.

## Phase 5 — Report

**Symptom → Evidence → Root cause → Blast radius → Proposed fix (not applied)
→ Repair path for existing bad state.**

The repair path is separate from the fix and is often the urgent half: the code
fix stops new damage, the repair handles the rows already corrupted.

Wait for an explicit request before changing code.

## Phase 6 — Capture (mandatory)

Every durable fact this investigation produced that the base did not already
contain gets written back **in the same change set**. This phase is not
optional, including for anything learned from a web search — that is what makes
the second occurrence of this bug cheap.

Follow `${CLAUDE_PLUGIN_ROOT}/references/capture-contract.md`: the durability
test, the routing table, and the writing rules all live there. The
investigation-specific shapes are listed under "From investigation".

The two entries worth insisting on here:

- **A new symptom → cause → how to check row.** This incident just proved one.
  The check column is the valuable half.
- **The repair handle**, if you found or built one. It is the urgent half of the
  next occurrence: the code fix stops new damage, the repair handle fixes the
  state already corrupted.

List the pages you touched at the end of the report.
