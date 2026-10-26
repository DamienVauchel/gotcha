# Refund — troubleshooting

> **TL;DR** — refunds are asynchronous at both providers: the API response
> means "recorded", not "done". Concurrent partial refunds can race the
> over-refund guard (known gap).
>
> <sub>verified 2026-09-14 @ 3f9c2ab · scope: src/payments/refund/ · synthetic example</sub>

## Map

Entry point `src/payments/refund/RefundService.ts:28`.

### Exceptions

| Exception | Location | Thrown when | Meaning |
|---|---|---|---|
| `RefundExceedsCapturedError` | `src/payments/errors.ts:61` | sum of refunds > captured amount | Our ledger is the source of truth, not the provider's |
| `RefundWindowClosedError` | `src/payments/errors.ts:70` | capture older than 180 days | Hardcoded for all providers (`src/payments/refund/window.ts:11`) — wrong for Adyen, see [Adyen](../entities/adyen.md) |

### Swallowed errors and dropped work

- **Partial refunds are not serialized.** One provider request per call
  (`src/payments/refund/RefundService.ts:44`); the guard reads committed rows
  without a lock. **Known gap, unfixed.** `_Unknown — not confirmed in code_`
  whether either provider rejects the over-refund as a backstop.

## Cards

### TS-006 · Refund "succeeded", money never returned
<sub>keywords: refund not received, refund pending, refund failed later, REFUND notification · seen 2 · last 2026-08-19 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — refund marked done, customer says nothing arrived.
- **Cause** — the provider queued it and failed it later; the outcome arrives by
  webhook, sometimes hours after. See [Adyen](../entities/adyen.md) quirks.
- **Check** — look for the refund webhook (`webhook_events` by `provider_ref`),
  not the API response.
- **Fix** — mark refunds done from the webhook only.
- **Repair** — re-issue the refund once the failure reason is known.

### TS-005 · Refunded more than was captured
<sub>keywords: over-refund, RefundExceedsCapturedError not thrown, double refund · seen 1 · last 2026-03-11 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — refunds total exceeds the captured amount.
- **Cause** — two concurrent partial refunds both passed the unlocked guard.
  `src/payments/refund/RefundService.ts:44`
- **Check** — `select amount, created_at from refunds where attempt_id = ?` —
  two rows sub-second apart confirm the race.
- **Fix** — row lock or serialized queue per attempt.
- **Repair** — `_Unknown — not confirmed in code_`; handled manually with finance.
