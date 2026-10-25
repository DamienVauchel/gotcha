# Charge — troubleshooting

> **TL;DR** — a timeout leaves the attempt `pending` on purpose (D-001): never
> retry it by hand. Double charges come from a non-deterministic idempotency key.
> A missing receipt leaves no error, only a `warn` line.
>
> <sub>verified 2026-09-14 @ 3f9c2ab · scope: src/payments/charge/ · synthetic example</sub>

## Map

Entry point `src/payments/charge/ChargeService.ts:41` (`ChargeService.execute`).
State machine `pending → authorized → captured`, with `requires_action` as a side
branch owned by [SCA](sca.md).

### Exceptions

| Exception | Location | Thrown when | Meaning |
|---|---|---|---|
| `ProviderDeclinedError` | `src/payments/errors.ts:12` | provider returns a hard decline code | **Terminal.** Never retry — the issuer said no |
| `ProviderSoftDeclineError` | `src/payments/errors.ts:24` | code in `SOFT_DECLINE_CODES` (`src/payments/providers/codes.ts:8`) | Retry **once, with SCA** — see [PSD2](../standards/psd2-sca.md) |
| `IdempotencyConflictError` | `src/payments/errors.ts:37` | key reused with a different payload | Bug in key derivation, not a payment problem |
| `ProviderUnavailableError` | `src/payments/errors.ts:49` | 5xx, connect timeout, DNS failure | **Outcome unknown** — the charge may have succeeded. See D-001 |
| `AmountMismatchError` | `src/payments/charge/validate.ts:63` | order total ≠ requested amount after conversion | Usually the zero-decimal bug, TS-003 |

### Swallowed errors and dropped work

- **Read timeout on confirm → `pending`, not `failed`**
  (`src/payments/charge/ChargeService.ts:118`). Deliberate: D-001.
- **Receipt email** — `try/catch`, logs `warn`, continues
  (`src/payments/charge/ChargeService.ts:154`). Deliberate: D-002. "Charged, no
  receipt" produces no error anywhere.
- **Analytics event** — same pattern (`src/payments/charge/ChargeService.ts:161`).
  Missing revenue in the dashboard with a correct ledger starts here.
- **Zero-decimal currencies** — `toMinorUnits` (`src/payments/money.ts:29`)
  multiplies by 100 unconditionally. Only the allowlist guard at
  `src/payments/charge/validate.ts:63` stops a 100× charge. **Do not remove the
  guard without fixing `toMinorUnits`.**

### Log patterns

| Message / pattern | Emitted at | Means |
|---|---|---|
| `receipt dispatch failed` (warn) | `src/payments/charge/ChargeService.ts:156` | Charge succeeded, email did not. Only trace of it |
| `charge outcome unknown, leaving pending` | `src/payments/charge/ChargeService.ts:120` | Timeout path. Reconciliation will settle it |
| `soft decline, escalating to SCA` | `src/payments/charge/ChargeService.ts:96` | Normal PSD2 flow, not an incident |

### Repair handles

| Handle | Repairs | Safe to re-run? |
|---|---|---|
| `npm run cli -- payments:receipt:resend --attempt=<id>` | missing receipt after a swallowed dispatch | Yes — duplicates if the first arrived |
| `npm run cli -- payments:charge --dry-run` | nothing — reproduces a charge without moving money | Yes |

## Cards

### TS-001 · Customer charged twice, one order
<sub>keywords: double charge, charged twice, duplicate payment, idempotency key · seen 4 · last 2026-09-14 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — two captured charges at the provider for one order.
- **Cause** — the client retried after a timeout with a **regenerated** idempotency
  key. `src/payments/idempotency.ts:17` must hash `order_id + amount` only.
- **Check** — `select idempotency_key from payment_attempts where order_id = ?` —
  two distinct keys for one order confirms it.
- **Fix** — remove any timestamp / random part from key derivation.
- **Repair** — refund the duplicate from the provider dashboard; the ledger
  follows via the refund webhook.

### TS-004 · Customer charged, no receipt, no error
<sub>keywords: no receipt, receipt missing, email not sent, receipt dispatch failed · seen 3 · last 2026-08-02 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — payment fine, customer never got the email, nothing in error logs.
- **Cause** — swallowed receipt dispatch, deliberate (D-002).
  `src/payments/charge/ChargeService.ts:154`
- **Check** — `service:payments "receipt dispatch failed"` — nothing else records it.
- **Fix** — none; check the mail provider's status for the time window.
- **Repair** — `payments:receipt:resend --attempt=<id>`.

### TS-002 · Attempt stuck `pending` for more than 24 h
<sub>keywords: stuck pending, pending payment, charge outcome unknown · seen 2 · last 2026-07-21 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — attempt still `pending` the day after.
- **Cause** — the timeout path (D-001) relies on reconciliation, which did not
  match that day. See TS-010.
- **Check** — `select day, matched_at from settlement_runs order by day desc limit 3`.
- **Fix** — none at charge level; it is a reconciliation problem.
- **Repair** — `payments:reconcile --day=YYYY-MM-DD`.

### TS-003 · `AmountMismatchError` on JPY / KRW orders only
<sub>keywords: AmountMismatchError, JPY, KRW, zero-decimal, amount mismatch · seen 2 · last 2026-05-30 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — every order in a zero-decimal currency fails validation.
- **Cause** — `toMinorUnits` multiplies by 100 unconditionally
  (`src/payments/money.ts:29`); the guard at `src/payments/charge/validate.ts:63`
  catches it. The error is the guard **working**.
- **Check** — reproduce with `--currency=JPY`: the thrown amount is exactly 100×
  the order total.
- **Fix** — currency-aware `toMinorUnits`. Keep the guard.
- **Repair** — none needed: no money moved.
