# Examples

## `payments-gateway/`

A knowledge base for a fictional payments module — a TypeScript service that
charges cards through Stripe and Adyen. The code it cites does not exist.
Everything else is written exactly as `/gotcha-init` and `/gotcha-investigate`
would produce it on a real repo.

It exists because "capture durable findings" is useless advice until you see
what a good entry looks like next to a bad one. Read it for the shape, not the
content.

What to look at, in order:

| File | Shows |
|---|---|
| `gotchas/manifest.yml` | the only repo-specific file — scopes, entities, routing, verified repro commands |
| `gotchas/failure-modes.md` | the payload: swallowed errors, symptom rows with a **check** column, deliberate trade-offs recorded as deliberate, repair handles |
| `gotchas/entities/stripe.md` | an entity page carrying quirks its sibling does not have |
| `gotchas/entities/adyen.md` | the sibling — same interface, opposite failure semantics |
| `gotchas/standards/psd2-sca.md` | external-spec knowledge: only the part that actually bites |
| `gotchas/INDEX.md` | what the SessionStart hook injects — hooks, not summaries |

Two things to notice, because they are the rules people break first:

1. **The symptom tables have a "how to check" column and it is never empty.**
   Symptom → cause with no verification step is a rumour that will send the
   next person down the wrong path with more confidence than they had before.
2. **`_Unknown — not confirmed in code_` appears several times.** A base that
   admits what it does not know stays trusted. One that papers over gaps gets
   abandoned the first time it is confidently wrong.
