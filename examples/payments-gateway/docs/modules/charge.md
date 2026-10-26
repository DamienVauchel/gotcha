<!-- gotcha:generated · sources: modules/charge.md, decisions.md, troubleshooting/charge.md · edit gotchas/ instead, this page is rebuilt -->

# Charge

`ChargeService.execute` turns "charge order X for amount Y" into a provider
charge, records the attempt, and hands over to SCA when the issuer asks for
authentication. It never marks the order paid itself — the webhook does.

## How a charge flows

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","lineColor":"#6b7280","actorBkg":"#dae8fc","actorBorder":"#6c8ebf","actorTextColor":"#1f2937","actorLineColor":"#cbd5e1","signalColor":"#4b5563","signalTextColor":"#1f2937","noteBkgColor":"#fff2cc","noteBorderColor":"#d6b656","noteTextColor":"#1f2937","activationBkgColor":"#ffe6cc","activationBorderColor":"#d79b00","labelBoxBkgColor":"#f8cecc","labelBoxBorderColor":"#b85450","loopTextColor":"#1f2937"},"sequence":{"mirrorActors":false,"messageMargin":38,"boxMargin":12,"noteMargin":12,"actorMargin":70}}}%%
sequenceDiagram
  autonumber
  participant C as 🛒 Checkout
  participant S as ChargeService
  participant V as validate
  participant DB as 🗄️ Postgres
  participant P as 🌐 Provider
  C->>S: execute(order, amount)
  S->>V: check amount and currency
  V-->>S: ok · or AmountMismatchError
  Note over S: idempotency key =<br/>hash(order_id + amount)
  S->>DB: insert attempt · pending
  S->>+P: charge
  P-->>-S: result
  Note over S: map the provider result<br/>to our outcome first
  alt soft decline
    Note over S: hand over to SCA, retry once
  else timeout
    S->>DB: stay pending — no retry
  end
```

*The first two notes on `ChargeService` are the module's invariants: how the
idempotency key is built, and mapping the result before acting on it.*

## What must stay true

> [!WARNING]
> **The idempotency key depends on `order_id + amount` only.** Anything
> time-based or random in it lets a retried request charge the customer twice.

> [!WARNING]
> **A timeout is never a failure.** The attempt stays `pending` and the nightly
> reconciliation settles it. Adding a retry here reintroduces double charges —
> see [the decision](../decisions.md#no-automatic-retry-after-an-unknown-outcome).

> [!IMPORTANT]
> **Map the provider result before branching on it.** Adyen answers HTTP 200 to
> a refused payment; the outcome is in `resultCode`.

## Changing things

| To… | Touch | Watch out for |
|---|---|---|
| add a provider | the provider registry, a client, a result mapper — and an integration page | success may not be in the status code |
| add a currency | `toMinorUnits` and the currency allowlist in `validate` | zero-decimal currencies (JPY, KRW) are charged 100× without the guard |
| change retry behaviour | read [the decision](../decisions.md#no-automatic-retry-after-an-unknown-outcome) first | double charges |

## Related

[Architecture](../architecture.md) · [Troubleshooting · Charge](../troubleshooting/charge.md) ·
[Stripe](../integrations/stripe.md) · [Adyen](../integrations/adyen.md)
