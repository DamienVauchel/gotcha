<!-- gotcha:generated · sources: overview.md · edit gotchas/ instead, this page is rebuilt -->

# Getting started

1. **Configure sandbox credentials.** Put the Stripe and Adyen sandbox keys
   (`STRIPE_*`, `ADYEN_*`) in `.env`.
2. **Run it.** `npm run dev`
3. **Run the tests.** `npm test -- src/payments` — provider calls are replayed
   from recorded fixtures in `test/fixtures/providers/`, so no network is needed.

## Everyday commands

| To… | Run | Safe? |
|---|---|---|
| reproduce a charge without moving money | `npm run cli -- payments:charge --dry-run` | yes |
| re-deliver one stored webhook | `npm run cli -- payments:webhook:replay --event-id=<id>` | yes — idempotent |
| re-run one settlement day | `npm run cli -- payments:reconcile --day=YYYY-MM-DD` | yes — idempotent |
| resend a receipt | `npm run cli -- payments:receipt:resend --attempt=<id>` | sends a duplicate if the first arrived |

> [!TIP]
> On call for reconciliation, the runbook is `docs/runbooks/nightly-settlement.md`.
