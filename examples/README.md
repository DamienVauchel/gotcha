# Examples

## `payments-gateway/`

The project memory of a fictional payments module — a TypeScript service that
charges cards through Stripe and Adyen. The code it cites does not exist.
Everything else is written exactly as `/gotcha-init` and a few months of
write-backs would produce it on a real repo.

It exists because "capture durable findings" is useless advice until you see
what a good entry looks like. Read it for the shape, not the content.

What to look at, in order:

| File | Shows |
|---|---|
| `gotchas/INDEX.md` | what the SessionStart hook injects — hooks, not summaries |
| `gotchas/overview.md` | the map a newcomer needs on day one, with verified commands |
| `gotchas/modules/charge.md` | flows across files, invariants, "where to change X" |
| `gotchas/decisions.md` | trade-offs with what was **rejected** — the part the code destroys |
| `gotchas/troubleshooting/INDEX.md` | the theme router: literal error strings, card counts, last seen |
| `gotchas/troubleshooting/webhooks.md` | a theme: failure map derived from code, then cards sorted by `seen` |
| `gotchas/entities/adyen.md` | an entity page carrying quirks its sibling does not have |
| `gotchas/standards/psd2-sca.md` | external-spec knowledge: only the part that actually bites |

Run the scripts against it to see what the skills see:

```sh
cd examples/payments-gateway
sh ../../scripts/stats.sh gotchas     # sizes, cards, flags, next ids
sh ../../scripts/stale.sh             # every citation reports `missing` — the code is fictional
```

Three things to notice, because they are the rules people break first:

1. **Every card has a Check line and it is never vague.** Symptom → cause with
   no verification step is a rumour that sends the next person down the wrong
   path with more confidence than they had before.
2. **`_Unknown — not confirmed in code_` appears several times.** A base that
   admits what it does not know stays trusted.
3. **Cards are referenced by id** (`TS-007`, `D-001`), never by file. That is
   what lets `/gotcha-tidy` split and merge themes without breaking a link.
