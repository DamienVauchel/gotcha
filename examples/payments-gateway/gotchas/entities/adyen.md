# Adyen

> Synthetic example. The cited paths do not exist — only the shape is real.

## Identity

| Field | Value |
|---|---|
| Kind | provider |
| Identifier in code | `PROVIDERS.adyen` (`src/payments/providers/registry.ts:14`) |
| Identifier in data | `'adyen'` in `payment_attempts.provider` |

## Authentication

API key in the `X-API-Key` header (`AdyenClient.ts:19`). Webhooks authenticated
by **HMAC signature plus basic auth** — two mechanisms, both required, and the
basic-auth credentials are configured in the Adyen dashboard rather than in our
config. A webhook 401 is therefore not necessarily our bug.

## Interface

- `POST /payments`, `POST /payments/:pspReference/refunds` (`AdyenClient.ts:34-91`)
- Idempotency via the `Idempotency-Key` header. Retention window
  `_Unknown — not confirmed in code_`; do not assume it matches Stripe's 24h
- Amounts as `{ value, currency }` in minor units
- `merchantAccount` is required on every request and differs per region
  (`config/adyen.ts:9`)

## Flows

| Flow | Direction | Entry point |
|---|---|---|
| Charge | us → Adyen | `AdyenClient.charge` (`AdyenClient.ts:34`) |
| Refund | us → Adyen | `AdyenClient.refund` (`AdyenClient.ts:91`) |
| Payment events | Adyen → us | `POST /webhooks/adyen` (`WebhookController.ts:31`) |

## Configuration

`ADYEN_API_KEY`, `ADYEN_HMAC_KEY`, `ADYEN_MERCHANT_ACCOUNT`,
`ADYEN_ENVIRONMENT` (`test` | `live`). Live traffic uses a **per-merchant
endpoint prefix**, so the live base URL is not a constant — built at
`AdyenClient.ts:24`. A hardcoded live URL works in test and fails in production.

## Known quirks

- **HTTP 200 does not mean success.** The outcome is in `resultCode`
  (`Authorised`, `Refused`, `Error`, `Pending`, `RedirectShopper`). Mapped at
  `providers/adyen/mapResult.ts:12`. Any code branching on the status code alone
  treats a refusal as a successful charge.
- **The webhook response body must be exactly `[accepted]`** — this acknowledges
  *receipt*, not successful processing (`WebhookController.ts:44`). Returning it
  before the work is committed silently drops events with no provider retry.
  We enqueue first, then return it (`WebhookController.ts:41`).
- **Refunds are always asynchronous.** The API response only confirms the
  request was recorded; the real outcome arrives as a `REFUND` notification,
  which can be `success: false` **hours later**. A refund marked done from the
  API response alone is a lie the customer eventually discovers.
- **`pspReference` is the only durable id** and it is absent from some error
  responses — so a failed charge can be unlinkable to anything provider-side.
  This is the reconciliation "unmatched provider charge" case in
  `failure-modes.md`.
- **Refund window: 13 months**, far longer than Stripe's 180 days. Our shared
  `RefundWindowClosedError` check does **not** vary by provider
  (`refund/window.ts:11` hardcodes 180 days), so Adyen refunds legal at the
  provider are rejected locally between day 181 and month 13. Known gap.
- **Notifications may be batched** — one HTTP request can carry several
  `notificationItems`. `_Unknown — not confirmed in code_` whether
  `WebhookProcessor` iterates the array or reads only the first item; verify
  before trusting single-event delivery.
