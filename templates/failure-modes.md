# <subject> — Failure Modes & Diagnostic Map

Offline knowledge base for investigating bugs without re-deriving the codebase
or searching online. Companion of the `gotcha-investigate` skill.

Every fact here is backed by code — cite `file:line`. When the code moves,
update this page in the same change set. Run `/gotcha-lint` to catch what drifted.

## How to use this page

1. Classify the symptom into a scope.
2. Jump to that scope: known exceptions, log patterns, diagnostic entry points.
3. Use the command and queue tables at the bottom for reproduction and replay.

---

## <Scope name>

Entry points and framework: `<path/to/entry.ext:line>`.

### Known exceptions

| Exception | Location | Thrown when | Meaning |
|---|---|---|---|

### Failure-handling semantics

<!-- What happens on failure, and whether it is a bug. The high-value entries:
     - errors caught and swallowed (logged and continued, null returned)
     - work silently dropped (early return, skipped item, unhandled branch)
     - retried vs. not retried, and where the retry budget is spent
     - deliberate trade-offs — record them AS deliberate, with the reason,
       or someone will "fix" them and reintroduce what they solved -->

### Symptom → cause → check

<!-- Filled from real incidents by /gotcha-investigate. Never invent rows. -->

| Symptom | Likely cause | How to check |
|---|---|---|

### Log patterns

| Message / pattern | Emitted by | Means |
|---|---|---|

---

## Commands

| Command | Purpose | Notes |
|---|---|---|

## Queues / async entry points

| Queue or topic | Consumer | Failure destination |
|---|---|---|

## Repair handles

<!-- The urgent half of any incident: what fixes state already corrupted, as
     opposed to the code fix that stops new damage. -->

| Handle | Repairs | Safe to re-run? |
|---|---|---|
