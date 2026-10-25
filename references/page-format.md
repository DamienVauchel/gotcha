# Page format

The single definition of what a page in `gotchas/` looks like. Every skill that
writes a page follows this file. The shape exists for two readers at once: a
human who opens the page on GitHub, and an agent that must decide **from the
first lines** whether to read the rest.

## The layout

```
gotchas/
  INDEX.md                 L0 — the router. Injected into every session. ≤ 60 lines
  manifest.yml             the only repo-specific config: scopes, routing, evidence, mode
  overview.md              what the project is, the map, how to run / test / ship
  conventions.md           the non-obvious rules of how code is written here
  glossary.md              domain words → the names they have in the code
  decisions.md             deliberate trade-offs, D-NNN cards
  modules/<area>.md        how one area works: role, flows, invariants, where to change X
  entities/<name>.md       one partner / provider / tenant / plugin each
  standards/<name>.md      the part of an external spec that actually bites here
  troubleshooting/
    INDEX.md               L1 — the theme router: keywords, card count, last seen
    <theme>.md             a failure map + TS-NNN symptom cards
    _archive.md            cold cards. Not indexed, still greppable
  _template.md             entity skeleton for the next one
  .publish-state           what the human docs were built from (publish-check.sh)
```

This is the **source**, written for the agent. The human docs are generated from
it by `/gotcha-publish` — see `publishing.md`.

Only `INDEX.md`, `manifest.yml`, `overview.md` and `troubleshooting/INDEX.md` are
mandatory. Every other page exists only when it has content. An empty page is
noise in the index that every session pays for.

## Reading tiers

Pages are built so the agent can stop as early as possible.

| Tier | What | Cost |
|---|---|---|
| L0 | `INDEX.md` — one line per page: link + **when to open it** | always in context |
| L1 | a hub (`troubleshooting/INDEX.md`) or a page's TL;DR block | ~5–15 lines |
| L2 | the section or the single card that answers | one `Read` with offset/limit |
| L3 | the cited code | only when in doubt — see the gotcha-recall skill |

## Every page

```markdown
# <Title>

> **TL;DR** — two to four lines. What this page is for and the one or two facts
> most people come here for. Written so that reading only this block is often
> enough.
>
> <sub>verified 2026-10-25 @ 3f9c2ab · scope: src/payments/charge/</sub>
```

- **The TL;DR is mandatory** (except on index pages). It is the L1 tier.
- **The stamp** — `verified <date> @ <short-sha>` — is the commit the page was
  last checked against. `scripts/stale.sh` diffs every cited file against it,
  which is how the agent knows, without reading code, whether a page can be
  trusted as-is. Update the stamp only when you actually re-checked the page.
- **Sections are `##`.** Cards are `###`. Nothing deeper — deep nesting means
  the page should be split.
- **≤ 300 lines.** Over that, split (see `organization.md`).
- **Written in the manifest's `language:`**, headings included. Identifiers,
  paths, commands and log strings stay verbatim.

## Citations

- Code facts cite **repo-relative** `path/to/file.ext:line` (or `:start-end`) in
  backticks. That exact shape is what `stale.sh` and `/gotcha-lint` parse. A
  bare `Foo.ts:12` is unlintable.
- External facts cite their source: URL, document name, or "confirmed by
  <who> on <what>".
- Unknowns are written `_Unknown — not confirmed in code_`. Never filled with a
  guess.

## Cards

Two page kinds are collections of cards: `decisions.md` and every
`troubleshooting/<theme>.md`. A card is the unit that gets found by grep, cited
by id, moved between pages by `/gotcha-tidy`, and archived. Cards keep their id
forever; **cross-reference cards by id, never by file**, so a split or a merge
breaks no link.

### Troubleshooting card

```markdown
### TS-014 · Orders unpaid although the charge succeeded
<sub>keywords: unpaid order, webhook ignored, unhandled webhook event · seen 3 · last 2026-09-14 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — what the user or the logs show, in their words.
- **Cause** — the mechanism, cited. `src/payments/webhook/WebhookProcessor.ts:37`
- **Check** — the query, command or log search that confirms it. Never empty.
- **Fix** — what stops new occurrences. Or "deliberate — see D-003".
- **Repair** — what fixes the state already damaged, if any.
```

- `keywords` carry the **literal strings** someone will paste: error messages,
  log lines, exception names, user-facing wording. They are the grep target.
- `seen` counts how many real tasks this card resolved; `last` is the latest.
  They are the self-organization signal: hot cards rise, cold cards get
  archived. Bump them when a card answers a real task — never for reading it.
- A card is ≤ 15 lines. Longer means it is two cards or a module fact.

### Decision card

```markdown
### D-003 · No automatic retry after an unknown charge outcome
<sub>keywords: retry, timeout, double charge · verified 2026-09-14 @ 3f9c2ab</sub>

- **Decision** — leave the attempt `pending`; reconciliation settles it.
- **Why** — a blind retry risks a double charge when the first request landed.
- **Rejected** — retry with the same idempotency key: safe only if the first
  request reached the provider, which is exactly what is unknown.
- **Revisit if** — latency becomes the complaint: add a status lookup first.
- **Where** — `src/payments/charge/ChargeService.ts:118`
```

The **Rejected** and **Revisit if** lines are the point. The code keeps the
decision and destroys the reason; without them the next person "fixes" it.

## Theme pages

A `troubleshooting/<theme>.md` has two parts, in this order:

1. **Map** — reference tables derived from the code: exceptions and their throw
   conditions, swallowed errors and dropped work, log patterns, repair handles.
   `/gotcha-init` fills it. It answers "what can fail here".
2. **Cards** — `TS-NNN` cards, hottest first. Real incidents only; never
   invented. They answer "this happened, what is it".

## Index lines

L0 and L1 lines are **hooks, not summaries**: they say when to open the page.

- ✗ `- [Stripe](entities/stripe.md) — Stripe integration`
- ✓ `- [Stripe](entities/stripe.md) — webhook can beat our own API response; signature tolerance 300 s`

## Dates

Dates are metadata, never narrative. They appear in exactly two places: the
`verified` stamp (with its sha — the sha is what makes it useful) and the
`seen`/`last` counters on troubleshooting cards. No "added on", no changelog
inside pages, no ticket numbers: git already holds the story.
