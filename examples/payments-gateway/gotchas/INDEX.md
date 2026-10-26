# src/payments — project memory

Start here. One line per page: when to open it. Read the TL;DR before the body.
Errors and symptoms: grep `troubleshooting/` first. Write back what a task
taught you that these pages lacked.

## Project

- [Overview](overview.md) — the map, why the webhook (not the charge) marks orders paid, how to run / test
- [Glossary](glossary.md) — "payment" is an *attempt*, "3DS" is *SCA*, "settlement" is *reconciliation*
- [Decisions](decisions.md) — no retry on timeout, best-effort receipts, unknown webhooks acked — read before "fixing" them

## Modules

- [Charge](modules/charge.md) — attempt state machine, idempotency key invariant, adding a provider or a currency

## Entities

- [Stripe](entities/stripe.md) — webhooks can land before our own API call returns; signature tolerance is 300 s
- [Adyen](entities/adyen.md) — HTTP 200 on refusal, `resultCode` is the outcome; refunds fail hours later

## Standards & protocols

- [PSD2 / SCA](standards/psd2-sca.md) — which exemptions we claim, and why a soft decline is not a failure

## Troubleshooting

[Theme router](troubleshooting/INDEX.md) — 5 themes, 13 cards. Grep it with the error string.

- [Webhooks](troubleshooting/webhooks.md) — `SignatureVerificationError`, order unpaid after a successful charge
- [Charge](troubleshooting/charge.md) — double charge, stuck `pending`, `AmountMismatchError`, no receipt
- [Refund](troubleshooting/refund.md) — refund not received, over-refund
- [Reconciliation](troubleshooting/reconciliation.md) — green run but still pending, unmatched provider charge
- [SCA](troubleshooting/sca.md) — session expired after 3DS, every card challenged
