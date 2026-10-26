# Decisions

> **TL;DR** — deliberate trade-offs. Before "fixing" something that looks wrong,
> grep its keyword here. The one most often "fixed" by mistake: D-001, no retry
> after a timeout.
>
> <sub>verified 2026-09-14 @ 3f9c2ab · synthetic example</sub>

### D-001 · No automatic retry after an unknown charge outcome
<sub>keywords: retry, timeout, ProviderUnavailableError, pending, double charge · verified 2026-09-14 @ 3f9c2ab</sub>

- **Decision** — on `ProviderUnavailableError` or a confirm timeout, leave the
  attempt `pending`; nightly reconciliation settles it within 24 h.
- **Why** — a retry after an unknown outcome risks a double charge.
- **Rejected** — retry with the same idempotency key: safe only if the first
  request reached the provider, which is exactly what a connect timeout leaves unknown.
- **Revisit if** — the 24 h delay becomes the complaint: add a provider-side
  status lookup **before** any retry. Never a blind retry.
- **Where** — `src/payments/charge/ChargeService.ts:118`

### D-002 · Receipt and analytics are best-effort
<sub>keywords: receipt, email, analytics, swallowed, best effort · verified 2026-09-14 @ 3f9c2ab</sub>

- **Decision** — receipt dispatch and analytics are wrapped in `try/catch`, logged
  at `warn`, and never fail a charge. The `payments.receipts` queue drops after 3 attempts.
- **Why** — a mail outage must not turn a successful payment into an error.
- **Rejected** — failing the charge: the money already moved.
- **Revisit if** — receipts become a legal requirement in a market we serve.
- **Where** — `src/payments/charge/ChargeService.ts:154`, `src/payments/charge/ChargeService.ts:161`

### D-003 · The order is marked paid by the webhook, not by the charge call
<sub>keywords: order paid, webhook, source of truth, async outcome · verified 2026-09-14 @ 3f9c2ab</sub>

- **Decision** — only `WebhookProcessor` transitions an order to paid.
- **Why** — outcomes are asynchronous (3DS, Adyen `Pending`, refunds); one code
  path for every outcome instead of two that can disagree.
- **Rejected** — marking paid on a synchronous success: two writers, and the
  webhook can arrive first ([Stripe](entities/stripe.md)).
- **Revisit if** — never without replacing the webhook as the single writer.
- **Where** — `src/payments/webhook/WebhookProcessor.ts:22`

### D-004 · A missing settlement report exits 0
<sub>keywords: reconciliation, exit 0, report not yet available · verified 2026-09-14 @ 3f9c2ab</sub>

- **Decision** — log `report not yet available`, exit 0, let the +4 h run match.
- **Why** — providers publish at different hours; a non-zero exit paged on-call nightly for a normal condition.
- **Rejected** — failing the run: alert fatigue, real failures got ignored.
- **Revisit if** — a provider stops publishing altogether: alert on `matched_at` null after 24 h instead.
- **Where** — `src/payments/reconciliation/SettlementRun.ts:71`

### D-005 · Unknown webhook event types are acked
<sub>keywords: UnknownEventTypeError, unhandled webhook event, ack · verified 2026-09-14 @ 3f9c2ab</sub>

- **Decision** — catch `UnknownEventTypeError`, log at `info`, return 2xx.
- **Why** — providers add event types constantly; rejecting them fills their retry queues.
- **Rejected** — 4xx on unknown types.
- **Revisit if** — a renamed event is missed again (TS-007): alert on the rate of the log line per type.
- **Where** — `src/payments/webhook/WebhookProcessor.ts:37`
