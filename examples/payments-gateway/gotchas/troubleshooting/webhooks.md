# Webhooks — troubleshooting

> **TL;DR** — the **order is marked paid by the webhook**, not by the charge
> call (D-003): any lost webhook looks like a failed payment. Unknown event types
> are acked silently. Signature errors after a deploy: check clock skew first.
>
> <sub>verified 2026-09-14 @ 3f9c2ab · scope: src/payments/webhook/ · synthetic example</sub>

## Map

`src/payments/webhook/WebhookController.ts:19` verifies and enqueues to
`payments.webhooks`; `src/payments/webhook/WebhookProcessor.ts:22` processes.
DLQ `payments.webhooks.dlq` after 5 attempts.

### Exceptions

| Exception | Location | Thrown when | Meaning |
|---|---|---|---|
| `SignatureVerificationError` | `src/payments/webhook/verify.ts:31` | HMAC mismatch or timestamp outside tolerance | Attack, clock skew, or rotated secret — check skew first |
| `UnknownEventTypeError` | `src/payments/webhook/registry.ts:44` | no handler for the event type | Harmless for new events; see below |

### Swallowed errors and dropped work

- **Unknown event types are acked** (`src/payments/webhook/WebhookProcessor.ts:37`,
  logged at `info`). Deliberate for new events (D-005); catastrophic when a
  provider **renames** an event we depend on.
- **Verification runs before parsing** (`src/payments/webhook/WebhookController.ts:24`):
  a malformed body from a valid signer 400s and the provider retries it forever.
  Check the provider's retry queue, not only ours.
- **Out-of-order delivery is tolerated**: upsert by provider event id, attempt
  row may not exist yet (`src/payments/webhook/WebhookProcessor.ts:58`).

### Log patterns

| Message / pattern | Emitted at | Means |
|---|---|---|
| `unhandled webhook event` (info) | `src/payments/webhook/WebhookProcessor.ts:39` | Acked without processing. **Watch the rate, not the line** |
| `signature verification failed` (error) | `src/payments/webhook/verify.ts:33` | Includes computed vs received prefix and the clock delta |

### Repair handles

| Handle | Repairs | Safe to re-run? |
|---|---|---|
| `npm run cli -- payments:webhook:replay --event-id=<id>` | order not marked paid after a lost or DLQ'd webhook | Yes — upsert by provider event id |

## Cards

### TS-008 · `SignatureVerificationError` burst right after a deploy
<sub>keywords: SignatureVerificationError, signature verification failed, webhook 400, invalid signature · seen 5 · last 2026-09-14 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — every webhook of one provider fails verification from one deploy on.
- **Cause** — container clock skew > 300 s (`src/payments/webhook/verify.ts:38`),
  or the webhook secret rotated in one environment only.
- **Check** — the log line carries the clock delta: > 300 s ⇒ skew. Otherwise
  compare the deployed secret's fingerprint with the provider dashboard.
- **Fix** — NTP on the hosts, or align the secret. Never rotate before checking skew.
- **Repair** — providers retry; replay what reached the DLQ.

### TS-007 · Orders unpaid although the charge succeeded
<sub>keywords: order unpaid, payment succeeded order pending, unhandled webhook event, webhook ignored · seen 3 · last 2026-08-27 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — money captured, order still unpaid, usually one provider only.
- **Cause** — the webhook was lost, DLQ'd, or acked as unknown after a provider
  renamed or gated an event type. `src/payments/webhook/WebhookProcessor.ts:37`
- **Check** — DLQ depth first; then `service:payments "unhandled webhook event"`
  grouped by `@event_type` — a type appearing in volume is the answer.
- **Fix** — register a handler for the new event name.
- **Repair** — `payments:webhook:replay --event-id=<id>` for each affected event.

### TS-009 · Webhook processed twice, ledger doubled
<sub>keywords: duplicate webhook, processed twice, ledger doubled, provider_event_id · seen 1 · last 2026-02-04 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — two ledger entries for one provider event.
- **Cause** — the upsert key does not match that provider's id format.
- **Check** — `select provider_event_id, count(*) from webhook_events group by 1 having count(*) > 1`.
- **Fix** — normalize the id before upsert.
- **Repair** — delete the duplicate ledger rows; `_Unknown — not confirmed in code_` whether a script exists.
