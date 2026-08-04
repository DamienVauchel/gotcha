# Capture contract

The single definition of what goes into the knowledge base and where. Both
`/gotcha-investigate` (Phase 6) and `/gotcha-capture` follow this file — do not
restate its rules in a skill, point at it.

## The durability test

A finding is captured only if **all three** hold:

1. **Not derivable from reading the code once.** If a competent reader of the
   current code would reach the same conclusion in a minute, the code is already
   the documentation.
2. **Still true next month.** Not an incident narrative, not a ticket state, not
   "currently broken".
3. **Would have saved time today.** If knowing it in advance would have changed
   nothing, it is trivia.

Anything failing one of the three is left out. A small trusted base beats a
large one nobody reads — and the index is injected into every session, so bulk
has a running cost.

## What qualifies, by trigger

The three tests above are the gate. These are the recurring shapes that pass it.

### From investigation

- A failure mode the base did not list, with its diagnostic handle
- A new **symptom → cause → how to check** row, proven by this incident
- A log pattern or query that located the problem
- A repair handle for state already corrupted
- Behaviour confirmed from an online source or a user-supplied doc — capture it
  so no future session needs that search

### From feature work

Stricter, because building generates many tempting candidates that are simply
the code being readable.

- **What the external world taught you** — a partner returns 200 on refusal, a
  spec forbids something, an id is absent from error responses. Nobody recovers
  this without redoing the integration.
- **A deliberate trade-off, with the alternatives you rejected and why.** The
  code preserves the decision and destroys the reason; without the reason
  someone "fixes" it and reintroduces exactly what it avoided. Record it **as
  deliberate**.
- **A swallowed error or dropped path you just introduced.** You are creating a
  future silent failure while you still understand it. This is the highest-value
  capture in the whole system and the one nobody remembers to make.
- **A new entity** — new provider, partner, tenant, plugin: its page, at
  integration time, not after the first incident.
- **Anything that cost more than ~30 minutes to work out and is not visible in
  the code.** The only empirical test that survives contact with real work.

### Never captured

- What the code now plainly states — the endpoint exists, the class does X
- The ticket narrative, dates, who did what. Git holds the story
- How you built it. The base is read by someone debugging, not rebuilding
- Anything you did not verify

## Routing

Follow `gotchas/manifest.yml` `routing:` literally. Default shape:

| Finding | Destination |
|---|---|
| Specific to one entity | `gotchas/entities/<name>.md` |
| Cross-cutting failure mode, symptom row, log pattern, repair handle | `gotchas/failure-modes.md` |
| Behaviour of an external standard or protocol | `gotchas/standards/<name>.md` |
| A new page of any kind | plus a line in `gotchas/INDEX.md` |

A finding that fits two destinations goes in **one** — the most specific — and
gets a cross-reference from the other. Duplicated facts drift apart and then two
pages disagree.

## Writing rules

- **Cite `file:line`.** No citation, no entry: an uncitable claim cannot be
  lint-checked later, so it is unmaintainable by construction.
- **External facts cite their source** — URL, doc name, or "confirmed by
  partner support on <what>".
- **Mark gaps `_Unknown — not confirmed in code_`.** A base that admits what it
  does not know stays trusted. One that papers over gaps gets abandoned the
  first time it is confidently wrong.
- **Symptom rows need the check column filled.** Symptom → cause without a
  verification step is a rumour that sends the next reader down the wrong path
  with more confidence than they had before.
- **Write the fact, not the story.** One or two sentences. Prose is not the
  deliverable.
- **Update `INDEX.md`** when adding a page — the hook injects the index, so a
  page missing from it is invisible.

## The `gotcha:` marker

The gap this closes: at the end of a task you have already forgotten half of
what you learned, and mid-task you do not want to stop and edit a doc.

Drop a comment where you learn it, in the code's comment syntax:

```ts
// gotcha: Adyen signals refusal in resultCode, HTTP is 200 either way
```

```php
// gotcha: deliberate — no retry on unknown outcome, double-charge risk > latency
```

Rules:

- One line, one fact. It is a note to the harvester, not documentation.
- `/gotcha-capture` harvests markers, routes them per the table above, and
  **deletes the marker** once the fact is in the base. A marker left in place
  gets re-harvested forever.
- A marker whose fact is already in the base is deleted without writing.
- A marker is a **pending** capture. Unharvested markers accumulating in the
  codebase mean the loop is not running — `/gotcha-lint` reports them.
- Never commit a marker as permanent documentation. If it belongs next to the
  code forever, write a real comment instead.
