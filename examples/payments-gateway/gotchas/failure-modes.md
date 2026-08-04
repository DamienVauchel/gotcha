# src/payments — Failure Modes & Diagnostic Map

Offline knowledge base for investigating payment bugs without re-deriving the
codebase or searching online. Companion of the `gotcha-investigate` skill.

> Synthetic example. The cited paths do not exist — only the shape is real.

Every fact here is backed by code — cite `file:line`. When the code moves,
update this page in the same change set. Run `/gotcha-lint` to catch what drifted.

## How to use this page

1. Classify the symptom into a scope: charge, refund, webhook, reconciliation, sca.
2. Jump to that scope: known exceptions, log patterns, diagnostic entry points.
3. Use the command and repair tables at the bottom for reproduction and replay.

---

## Charge

Entry point: `src/payments/charge/ChargeService.ts:41` (`ChargeService.execute`).
State machine: `pending → authorized → captured`, with `requires_action` as a
side branch owned by the SCA scope.

### Known exceptions

| Exception | Location | Thrown when | Meaning |
|---|---|---|---|
| `ProviderDeclinedError` | `src/payments/errors.ts:12` | provider returns a hard decline code | **Terminal.** Never retry — the issuer said no. Retrying burns the idempotency key for nothing |
| `ProviderSoftDeclineError` | `src/payments/errors.ts:24` | decline code is in `SOFT_DECLINE_CODES` (`providers/codes.ts:8`) | Retryable **once, with SCA**. See `standards/psd2-sca.md` |
| `IdempotencyConflictError` | `src/payments/errors.ts:37` | provider reports the key was reused with a different payload | Two different charges tried to share a key — a bug in key derivation, not a payment problem |
| `ProviderUnavailableError` | `src/payments/errors.ts:49` | 5xx, connect timeout, or DNS failure | **Outcome unknown.** The charge may have succeeded. See the trade-off below |
| `AmountMismatchError` | `src/payments/charge/validate.ts:63` | order total ≠ requested amount after currency conversion | Usually a zero-decimal currency bug — see `Currency` below |

### Failure-handling semantics

- **Read timeout on confirm is treated as unknown, not failed** — `ChargeService`
  catches `ETIMEDOUT` on the confirm call and leaves the attempt in `pending`
  rather than marking it `failed` (`ChargeService.ts:118`). The nightly
  reconciliation resolves it. Marking it failed would let the customer retry and
  get charged twice.
- **Deliberate trade-off — no automatic retry on `ProviderUnavailableError`.**
  A retry after an unknown outcome risks a double charge; the idempotency key
  would prevent it *only* if the first request reached the provider, which is
  exactly what is unknown on a connect timeout. The decision was: leave it
  pending, let reconciliation settle it within 24h, accept the delay.
  **Do not "fix" this by adding a retry** — that reintroduces the double-charge
  it was chosen to avoid. If latency becomes the problem, the fix is a
  provider-side status lookup before retrying, not a blind retry.
- **Swallowed: post-charge receipt email.** `ChargeService.ts:154` wraps the
  receipt dispatch in a `try/catch` that logs at `warn` and continues, so a mail
  outage cannot fail a successful charge. Consequence: "customer charged but got
  no receipt" produces **no error anywhere** — only the warn line below.
- **Swallowed: analytics event.** Same pattern, `ChargeService.ts:161`. Missing
  revenue in the dashboard with correct money in the ledger starts here.
- **Currency minor units.** `toMinorUnits` (`money.ts:29`) multiplies by 100
  unconditionally. Zero-decimal currencies (JPY, KRW) are therefore charged 100×.
  Guarded by an allowlist check at `validate.ts:63` that throws
  `AmountMismatchError` — so the bug surfaces as a validation error, not as an
  overcharge. The guard is the only thing standing between us and a 100× charge;
  do not remove it without fixing `toMinorUnits`.

### Symptom → cause → check

| Symptom | Likely cause | How to check |
|---|---|---|
| Customer charged twice, one attempt row | Client retried after a timeout with a **regenerated** idempotency key | `select idempotency_key from payment_attempts where order_id = ?` — two rows for one order means key derivation is not deterministic (`idempotency.ts:17` must hash `order_id + amount`, not include a timestamp) |
| Attempt stuck `pending` > 24h | Reconciliation never ran, or it ran before the provider's report was ready | `select count(*) from settlement_runs where day = ?`; then check the run's log for `report not yet available` |
| `AmountMismatchError` on JPY orders only | Zero-decimal currency hitting `toMinorUnits` | Reproduce with `--currency=JPY`; the thrown amount will be exactly 100× the order total |
| Charge succeeds, order stays unpaid | Webhook not processed — the order is marked paid by the webhook, not by the charge call | See the Webhook scope. Check the DLQ first |
| Customer charged, no receipt, no error | Swallowed receipt dispatch | `service:payments "receipt dispatch failed"` in logs — nothing else records it |

### Log patterns

| Message / pattern | Emitted by | Means |
|---|---|---|
| `receipt dispatch failed` (warn) | `ChargeService.ts:156` | Charge succeeded, email did not. Only trace of it |
| `charge outcome unknown, leaving pending` | `ChargeService.ts:120` | Timeout path taken. Expect reconciliation to settle it |
| `soft decline, escalating to SCA` | `ChargeService.ts:96` | Normal PSD2 flow, not an incident |

---

## Refund

Entry point: `src/payments/refund/RefundService.ts:28`.

### Known exceptions

| Exception | Location | Thrown when | Meaning |
|---|---|---|---|
| `RefundExceedsCapturedError` | `src/payments/errors.ts:61` | sum of refunds > captured amount | Guard against double refund; our ledger is the source of truth, not the provider's |
| `RefundWindowClosedError` | `src/payments/errors.ts:70` | capture older than the provider's window | Provider-specific window — see the entity pages |

### Failure-handling semantics

- **Partial refunds are not aggregated before sending.** Each call is one
  provider request (`RefundService.ts:44`). Two concurrent partial refunds can
  both pass the `RefundExceedsCapturedError` check and over-refund — the check
  reads committed rows without a lock. **Known gap, unfixed.**
  `_Unknown — not confirmed in code_` whether either provider rejects the
  over-refund on their side as a backstop.

### Symptom → cause → check

| Symptom | Likely cause | How to check |
|---|---|---|
| Refunded more than captured | Concurrent partial refunds racing the guard | `select sum(amount) from refunds where attempt_id = ?` vs `captured_amount`; check the two rows' `created_at` — sub-second apart confirms the race |
| Refund shows as succeeded, money not returned | Provider queued it; refunds are asynchronous at both providers | Check for the refund webhook, not the API response |

---

## Webhook

Entry point: `src/payments/webhook/WebhookController.ts:19`. Verified, enqueued
to `payments.webhooks`, processed by `WebhookProcessor.ts:22`. The **order is
marked paid here**, not in the charge call — so any webhook loss looks like a
charge failure to the business.

### Known exceptions

| Exception | Location | Thrown when | Meaning |
|---|---|---|---|
| `SignatureVerificationError` | `src/payments/webhook/verify.ts:31` | HMAC mismatch or timestamp outside tolerance | Could be an attack, a clock skew, or a rotated secret. Check skew before assuming attack |
| `UnknownEventTypeError` | `src/payments/webhook/registry.ts:44` | event type has no registered handler | Provider added an event. Harmless, but see the trap below |

### Failure-handling semantics

- **Swallowed: unknown event types.** `WebhookProcessor.ts:37` catches
  `UnknownEventTypeError`, logs `info`, and **acks**. Correct for genuinely new
  provider events; catastrophic when a provider *renames* an event we depend on,
  because the payment silently stops being recorded and nothing alerts.
  Diagnostic signature: a rising count of `unhandled webhook event` at `info`.
- **Verification runs before parsing** (`WebhookController.ts:24`), so a
  malformed body from a valid signer still 400s and the provider retries it
  forever. Check the provider dashboard's retry queue, not just ours.
- **Out-of-order delivery is expected.** `payment_intent.succeeded` can arrive
  before our own charge call returns (see `entities/stripe.md`). The processor
  upserts by provider event id and tolerates the attempt row not existing yet
  (`WebhookProcessor.ts:58`).

### Symptom → cause → check

| Symptom | Likely cause | How to check |
|---|---|---|
| Orders unpaid despite successful charges, one provider only | Renamed or newly-gated event type being acked as unknown | `service:payments "unhandled webhook event"` grouped by `@event_type` — a type appearing in volume is the answer |
| `SignatureVerificationError` in bursts after a deploy | Secret rotated in one environment only | Compare the deployed secret's fingerprint against the provider dashboard; check container clock skew before blaming the secret |
| Webhooks processed twice, ledger doubled | Upsert key wrong for that provider's id format | `select count(*), provider_event_id from webhook_events group by 2 having count(*) > 1` |

### Log patterns

| Message / pattern | Emitted by | Means |
|---|---|---|
| `unhandled webhook event` (info) | `WebhookProcessor.ts:39` | Acked without processing. **Watch the rate, not the line** |
| `signature verification failed` (error) | `verify.ts:33` | Includes computed vs. received prefix and the clock delta |

---

## Reconciliation

Nightly job: `src/payments/reconciliation/SettlementRun.ts:26`. Pulls each
provider's settlement report for D-1 and matches it against `payment_attempts`.
This is what resolves every `pending` attempt left by an unknown outcome.

### Failure-handling semantics

- **A missing report is not a failure.** Providers publish at different hours;
  `SettlementRun.ts:71` logs `report not yet available` and exits 0 so the retry
  at +4h picks it up. A run that exits 0 therefore does **not** mean the day
  reconciled — check `settlement_runs.matched_at`, not the exit code.
- **Unmatched provider-side charges are the dangerous direction.** Money taken
  with no local attempt row means the charge left our system and we lost the
  record. Alerted on. The reverse (local pending, nothing provider-side) is the
  benign timeout case and gets marked `failed`.

### Symptom → cause → check

| Symptom | Likely cause | How to check |
|---|---|---|
| Run "green" but attempts still pending | Report was not available; run exited 0 without matching | `select day, matched_at from settlement_runs order by day desc limit 7` — null `matched_at` is the tell |
| Unmatched provider charge | Crash between provider call and attempt row commit | Look for the idempotency key in the provider dashboard, then `select * from payment_attempts where idempotency_key = ?` |

---

## SCA

See `gotchas/standards/psd2-sca.md` for the spec-side rules. Code entry:
`src/payments/sca/ChallengeFlow.ts:33`.

### Symptom → cause → check

| Symptom | Likely cause | How to check |
|---|---|---|
| Customer completes 3DS, returns to an expired session | Challenge redirect outlives the session TTL (challenges can take minutes) | Compare `session.expires_at` against the challenge's `created_at`; TTL is at `config/session.ts:14` |
| Every card triggers a challenge | Exemption request dropped from the payload | Inspect the outbound body for the exemption field named in `standards/psd2-sca.md` |

---

## Commands

| Command | Purpose | Notes |
|---|---|---|
| `npm run cli -- payments:charge --dry-run` | Reproduce a charge without money moving | Requires provider sandbox credentials |
| `npm run cli -- payments:webhook:replay --event-id=<id>` | Re-deliver one stored webhook through the processor | Idempotent |
| `npm run cli -- payments:reconcile --day=YYYY-MM-DD` | Re-run one settlement day | Safe to re-run; matching is idempotent |

## Queues / async entry points

| Queue | Consumer | Failure destination |
|---|---|---|
| `payments.webhooks` | `WebhookProcessor` | `payments.webhooks.dlq` after 5 attempts |
| `payments.receipts` | `ReceiptDispatcher` | dropped after 3 attempts — receipts are best-effort by design |

## Repair handles

| Handle | Repairs | Safe to re-run? |
|---|---|---|
| `payments:webhook:replay` | Order not marked paid after a lost or DLQ'd webhook | Yes — upsert by provider event id |
| `payments:reconcile --day=` | Attempts left `pending` by an unknown outcome | Yes |
| `payments:receipt:resend --attempt=` | Missing receipt after a swallowed dispatch | Yes — sends a duplicate if the first arrived |
