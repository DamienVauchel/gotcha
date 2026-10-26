# Capture contract

The single definition of what goes into the base and where. Every write path
follows this file: `/gotcha-capture`, `/gotcha-investigate` phase 6, the Stop
hook's write-back nudge, the `gotcha-scribe` agent. Do not restate its rules in
a skill — point at it. Page shapes live in `page-format.md`, size rules in
`organization.md`.

## The durability test

A finding is captured only if **all three** hold:

1. **Not derivable from reading the code once.** If a competent reader of the
   current code would reach the same conclusion in a minute, the code is
   already the documentation.
2. **Still true next month.** Not an incident narrative, not a ticket state,
   not "currently broken".
3. **Would have saved time today.** If knowing it in advance would have changed
   nothing, it is trivia.

Anything failing one of the three is left out. A small trusted base beats a
large one nobody reads — and the index is injected into every session, so bulk
has a running cost.

There is one more test, cheaper than the three: **did the docs fail me this
turn?** If you had to open several code files to answer something the base
should have told you, the answer is a capture candidate. If the base answered
and was right, there is nothing to write except a `seen` bump.

## What qualifies, by trigger

### From any task — the everyday loop

- **The answer you had to dig for.** You read five files to find where X is
  decided, how Y flows, why Z exists. Write the map, not the walk: the entry
  point, the hops that matter, the invariant. Goes to the module page.
- **A doc that was wrong or stale.** Fix it in place, cite the code that
  disproves it, re-stamp `verified`. This is the highest-trust capture there is.
- **A convention you had to infer** from several files and that a reviewer would
  reject you for breaking. Goes to `conventions.md`.
- **A domain word** whose code name differs from what people call it. Goes to
  `glossary.md`.

### From investigation

- A new **symptom → cause → check** card, proven by this incident. The check is
  the valuable half.
- A failure mode the theme map did not list, with its diagnostic handle.
- A log pattern or query that located the problem.
- A repair handle for state already corrupted.
- Behaviour confirmed from an online source or a user-supplied doc — capture it
  so no future session needs that search.
- An existing card that matched: **bump `seen` and `last`**, sharpen its check
  if this incident showed a faster one. No new card.

### From feature work

Stricter, because building generates many tempting candidates that are simply
the code being readable.

- **What the external world taught you** — a partner returns 200 on refusal, a
  spec forbids something, an id is absent from error responses. Nobody recovers
  this without redoing the integration.
- **A deliberate trade-off, with the alternatives you rejected and why.** A
  `D-NNN` card. The code preserves the decision and destroys the reason.
- **A swallowed error or dropped path you just introduced.** You are creating a
  future silent failure while you still understand it. It goes in the theme
  map now. This is the highest-value capture in the whole system and the one
  nobody remembers to make.
- **A new entity** — provider, partner, tenant, plugin: its page, at
  integration time, not after the first incident.
- **A new area** — a module page when the work created one.
- **Anything that cost more than ~30 minutes** and is not visible in the code.

### Never captured

- What the code now plainly states — the endpoint exists, the class does X
- The ticket narrative, dates, who did what. Git holds the story
- How you built it, step by step. The base is read by someone about to work or
  debug, not by someone replaying your session
- Preferences of the current user. That is auto memory, not the team's base
- Anything you did not verify

## Routing

Follow `gotchas/manifest.yml` `routing:` literally. Default shape:

| Finding | Destination |
|---|---|
| How an area works, where to change X, an invariant | `gotchas/modules/<area>.md` |
| Project-wide map, commands to run / test / ship | `gotchas/overview.md` |
| A rule of how code is written here | `gotchas/conventions.md` |
| A domain term ↔ code name | `gotchas/glossary.md` |
| A deliberate trade-off | `D-NNN` card in `gotchas/decisions.md` |
| Specific to one entity | `gotchas/entities/<name>.md` |
| A symptom, failure mode, log pattern, repair handle | the matching `gotchas/troubleshooting/<theme>.md` |
| Behaviour of an external standard or protocol | `gotchas/standards/<name>.md` |
| A new page of any kind | plus its line in `INDEX.md` (or in its hub) |

Pick the troubleshooting theme from `troubleshooting/INDEX.md` keywords. No
theme fits ⇒ add the card to the closest one; let `/gotcha-tidy` split later.
Do not create a theme for a single card.

A finding that fits two destinations goes in **one** — the most specific — and
gets a cross-reference from the other (by card id when it is a card).
Duplicated facts drift apart and then two pages disagree.

## Writing rules

- **Cite repo-relative `path/to/file.ext:line`.** No citation, no entry.
- **External facts cite their source.**
- **Mark gaps `_Unknown — not confirmed in code_`.**
- **The check line of a card is never empty.**
- **Write the fact, not the story.** One or two sentences. Tables where the
  shape is a table.
- **New card ids** come from `scripts/stats.sh` (`next ids:`). Never reuse one.
- **Stamp what you verified**: `verified <today> @ <git rev-parse --short HEAD>`
  on the card, or on the page's TL;DR when you re-checked the page.
- **Keep the TL;DR true.** If the new fact is one of the two most useful on the
  page, it belongs in the TL;DR.
- **Add, do not restructure.** Restructuring is `/gotcha-tidy`'s job.

## After writing

Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/stats.sh`. If a page you touched is now
flagged `SPLIT`, `INDEX>60` or `UNINDEXED`, apply `/gotcha-tidy` to that page
only. A capture that leaves the base over its caps is not finished.

## Modes

`manifest.yml` `autocapture:`

| Value | Behaviour |
|---|---|
| `auto` (default) | write directly; report the pages touched in one line. The PR is the review |
| `propose` | list findings with their destination, write after the user confirms |
| `off` | no Stop-hook nudge; capture only on explicit `/gotcha-capture` |

In every mode the writes land in the **working tree**, next to the code change,
so a human reviews each fact in the PR before it becomes doctrine.

## The `gotcha:` marker

At the end of a task you have forgotten half of what you learned, and mid-task
you do not want to stop and edit a doc. Drop a comment where you learn it:

```ts
// gotcha: Adyen signals refusal in resultCode, HTTP is 200 either way
```

- One line, one fact. A note to the harvester, not documentation.
- `/gotcha-capture` harvests markers, routes them per the table above, and
  **deletes the marker** once the fact is in the base.
- A marker whose fact is already in the base is deleted without writing.
- Unharvested markers accumulating mean the loop is not running —
  `scripts/stats.sh` counts them and `/gotcha-lint` lists them.
- Never commit a marker as permanent documentation. If it belongs next to the
  code forever, write a real comment instead.
