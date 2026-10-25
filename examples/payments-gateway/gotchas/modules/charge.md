# Charge

> **TL;DR** — `ChargeService.execute` owns the attempt state machine. Amounts go
> through `toMinorUnits`, which is wrong for zero-decimal currencies — a guard
> catches it (TS-003). Never add a retry on timeout (D-001).
>
> <sub>verified 2026-09-14 @ 3f9c2ab · scope: src/payments/charge/ · synthetic example</sub>

## Role

Turns "charge order X for amount Y" into a provider charge, records the attempt,
and hands `requires_action` to SCA. Called by checkout; never marks the order paid
itself (D-003).

## Entry points

| Kind | Name | Location |
|---|---|---|
| Service | `ChargeService.execute` | `src/payments/charge/ChargeService.ts:41` |
| CLI | `payments:charge` | `src/cli/payments/charge.ts:10` |

## Key flows

1. **Charge** — `src/payments/charge/ChargeService.ts:41` validates
   (`src/payments/charge/validate.ts:63`) → derives the idempotency key
   (`src/payments/idempotency.ts:17`) → inserts the attempt `pending` → provider
   client `createIntent` / `charge` → maps the result
   (`src/payments/providers/adyen/mapResult.ts:12` for Adyen) → `authorized`, or
   `requires_action` to SCA.
2. **Soft decline** — `ProviderSoftDeclineError` → `src/payments/charge/ChargeService.ts:96`
   → SCA challenge → one retry.

## Invariants

- The idempotency key depends on `order_id + amount` only. Anything time-based
  produces double charges (TS-001).
- An attempt is never `failed` because of a timeout: unknown ≠ failed (D-001).
- Provider responses are mapped to our outcome **before** any branching: Adyen
  returns HTTP 200 on refusal.

## Where to change X

| To… | Touch | Watch out for |
|---|---|---|
| add a provider | `src/payments/providers/registry.ts:8`, a client, a result mapper, an entity page | success may not be in the status code |
| add a currency | `src/payments/money.ts:29`, the allowlist in `src/payments/charge/validate.ts:63` | zero-decimal currencies |
| change retry behaviour | read D-001 first | double charge |

## Related

D-001, D-002, D-003 · [Charge troubleshooting](../troubleshooting/charge.md) ·
[Stripe](../entities/stripe.md) · [Adyen](../entities/adyen.md)
