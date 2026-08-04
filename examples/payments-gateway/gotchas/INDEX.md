# Knowledge base — src/payments

Read the relevant page before searching the web or re-deriving the code.
Capture durable findings back here (`/gotcha-investigate` Phase 6).

## Core

- [Failure modes & diagnostic map](failure-modes.md) — exceptions, swallowed errors, symptom tables, log patterns, repair handles, per scope

## Entities

- [Stripe](entities/stripe.md) — webhooks can land before our own API call returns; signature tolerance is 300s
- [Adyen](entities/adyen.md) — `[accepted]` on the webhook response means nothing about our processing; `resultCode` is not an error channel

## Standards & protocols

- [PSD2 / SCA](standards/psd2-sca.md) — which exemptions we actually claim, and why a soft decline is not a failure
