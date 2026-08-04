# Stripe

> Synthetic example. The cited paths do not exist — only the shape is real.

## Identity

| Field | Value |
|---|---|
| Kind | provider |
| Identifier in code | `PROVIDERS.stripe` (`src/payments/providers/registry.ts:8`) |
| Identifier in data | `'stripe'` in `payment_attempts.provider` |

## Authentication

Secret key from `STRIPE_SECRET_KEY`, sent as bearer by
`StripeClient` (`src/payments/providers/stripe/StripeClient.ts:22`). Webhook
signatures verified against `STRIPE_WEBHOOK_SECRET` — a **different** secret,
and a distinct one per endpoint. Rotating one without the other is the usual
cause of a signature-error burst.

## Interface

- `POST /v1/payment_intents`, `POST /v1/payment_intents/:id/confirm`,
  `POST /v1/refunds` — the only endpoints called (`StripeClient.ts:40-102`)
- Idempotency via the `Idempotency-Key` header, derived at
  `src/payments/idempotency.ts:17`. Stripe retains keys **24h**; after that the
  same key is a fresh request, not a replay
- Amounts in minor units; zero-decimal currencies are the trap documented in
  `failure-modes.md` under Currency
- Pagination on list endpoints not used by our code

## Flows

| Flow | Direction | Entry point |
|---|---|---|
| Charge (intent + confirm) | us → Stripe | `StripeClient.createIntent` (`StripeClient.ts:40`) |
| Refund | us → Stripe | `StripeClient.refund` (`StripeClient.ts:88`) |
| Payment events | Stripe → us | `POST /webhooks/stripe` (`WebhookController.ts:19`) |

## Configuration

`STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_API_VERSION`
(pinned — `StripeClient.ts:26`). The pinned version matters: event payload
shapes change between versions, and the webhook is delivered in the version
pinned **on the endpoint in the dashboard**, not the one our client sends.
Those two drifting apart is invisible until a field goes missing.

## Known quirks

- **The webhook can arrive before our own API call returns.** Stripe dispatches
  `payment_intent.succeeded` as soon as the intent settles, which is routinely
  before the confirm response reaches us. The processor therefore tolerates an
  absent attempt row (`WebhookProcessor.ts:58`). Any code that assumes
  "our row exists by the time the webhook lands" is wrong here.
- **Signature tolerance is 300s** (`verify.ts:38`). Container clock skew above
  five minutes fails every webhook with `SignatureVerificationError`, which
  reads exactly like a wrong secret. **Check skew before rotating anything.**
- **`charge.refunded` fires for partial refunds too**, with no field
  distinguishing partial from full — the amounts must be compared against our
  ledger. Treating the event as "fully refunded" over-credits.
- **Refund window: 180 days** after capture, enforced provider-side. Our
  `RefundWindowClosedError` uses the same 180 days (`refund/window.ts:11`), so a
  mismatch after a Stripe policy change would surface as their rejection, not
  ours.
- **Hard vs. soft decline codes** are not flagged as such in the response; the
  mapping lives in our own `SOFT_DECLINE_CODES` (`providers/codes.ts:8`) and was
  built by hand. `_Unknown — not confirmed in code_` whether that list is
  complete against Stripe's current decline-code catalogue.
