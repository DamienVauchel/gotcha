# Page Format

The single definition of what a page in `gotchas/` looks like. It serves two readers at once: a human opening the page on GitHub, and an agent deciding **from the first lines** whether to read the rest.

## Anatomy of a page

```markdown
# Charge

> **TL;DR** — `ChargeService.execute` owns the attempt state machine. Never add
> a retry on timeout (D-001).
>
> <sub>verified 2026-09-14 @ 3f9c2ab · scope: src/payments/charge/</sub>

## Flows
…
```

- **TL;DR first** — the two most useful facts. Written *last*, once the body exists. Kept true on every write-back.
- **The stamp** — `verified <date> @ <short-sha>` — is the commit the page was last checked against. [`stale.sh`](Scripts) diffs every cited file against it, which is how the agent knows, without reading code, whether the page can be trusted as-is. **Update the stamp only when you actually re-checked.**
- **Sections are `##`, cards are `###`.** Nothing deeper — deep nesting means the page should be split.
- **≤ 300 lines.** Over that, split ([Self-Organization](Self-Organization)).
- **Written in the manifest's `language:`**, headings included. Identifiers, paths, commands and log strings stay verbatim.

## Reading tiers

| Tier | What | Cost |
|---|---|---|
| L0 | `INDEX.md` — link + **when to open it** | always in context |
| L1 | a hub (`troubleshooting/INDEX.md`) or a page's TL;DR | ~10 lines |
| L2 | one section or one card | ~15 lines |
| L3 | the code | only when in doubt |

## Citations

- Code facts cite **repo-relative** `path/to/file.ext:line` (or `:start-end`) in backticks. That exact shape is what `stale.sh` and `/gotcha-lint` parse. A bare `Foo.ts:12` is unlintable.
- External facts cite their source: URL, document name, or "confirmed by *who* on *what*".
- Unknowns are written `_Unknown — not confirmed in code_`. Never filled with a guess.

## Cards

Two page kinds are collections of cards: `decisions.md` and every `troubleshooting/<theme>.md`. A card is the unit that gets found by grep, cited by id, moved between pages by `/gotcha-tidy`, and archived.

> [!IMPORTANT]
> Cards keep their id forever. **Cross-reference cards by id, never by file**, so a split or merge breaks no link. New ids come from `stats.sh` (`next ids:`) — never reuse one.

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

| Field | Rule |
|---|---|
| `keywords` | the **literal strings** someone will paste: error messages, log lines, exception names, user wording. The grep target |
| `seen` / `last` | how many real tasks the card resolved, and the latest. Bump them when a card answers a real task — **never for merely reading it** |
| **Check** | never empty. A symptom → cause without "how to verify" is a rumour |
| length | ≤ 15 lines. Longer means it is two cards, or a module fact |

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

The **Rejected** and **Revisit if** lines are the point. The code keeps the decision and destroys the reason; without them the next person "fixes" it.

## Dates: only two kinds

Dates are metadata, never narrative — no "added on", no changelog inside pages, no ticket numbers; git holds the story.

1. **`verified <date> @ <sha>`** — the sha is the useful half; the date is for the human glancing at the page.
2. **`seen N · last <date>`** on troubleshooting cards — the self-organization signal.

## Index lines

L0 and L1 lines are **hooks, not summaries**: they say when to open the page. See [Memory Layout](Memory-Layout).
