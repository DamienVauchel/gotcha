<!-- gotcha:generated · sources: troubleshooting/charge.md · edit gotchas/ instead, this page is rebuilt -->

# Troubleshooting · Charge

## Diagnose

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart TB
  classDef actor fill:#e1d5e7,stroke:#9673a6,stroke-width:1.5px,color:#1f2937
  classDef warn fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef bad fill:#f8cecc,stroke:#b85450,stroke-width:1.5px,color:#1f2937

  s(["🔎 Charge problem"]):::actor
  s --> q1{"Customer charged twice?"}:::warn
  q1 -->|yes| key(["🔑 Idempotency key<br/>not deterministic"]):::bad
  q1 -->|no| q2{"Attempt pending<br/>for more than 24 h?"}:::warn
  q2 -->|yes| recon(["🌙 Reconciliation did not match<br/>→ Reconciliation"]):::bad
  q2 -->|no| q3{"AmountMismatchError<br/>on JPY / KRW?"}:::warn
  q3 -->|yes| minor(["💴 Zero-decimal currency"]):::bad
  q3 -->|no| receipt(["✉️ No receipt?<br/>Swallowed on purpose"]):::warn
```

*A charge that "failed" after a timeout is usually not failed: it is `pending`
on purpose and settles overnight.*

## Known problems

### Customer charged twice for one order

- **You see** — two captured charges at the provider for the same order.
- **Check** — two different idempotency keys stored for that order in `payment_attempts`.
- **Fix** — the key must hash `order_id + amount` only — remove anything time-based or random.
- **Repair** — refund the duplicate from the provider dashboard; the ledger follows through the refund webhook.

### Customer charged, no receipt, no error

- **You see** — the payment is fine, the customer never received the email, error logs are clean.
- **Check** — search `receipt dispatch failed` — it is the only trace.
- **Fix** — none on our side; check the mail provider for that time window.
- **Repair** — `payments:receipt:resend --attempt=<id>`.

### Attempt stuck `pending` for more than 24 h

- **You see** — an attempt is still `pending` the next day.
- **Check** — the last settlement runs: a missing `matched_at` means the day did not reconcile.
- **Fix** — see [Reconciliation](reconciliation.md).
- **Repair** — `payments:reconcile --day=YYYY-MM-DD`.

### `AmountMismatchError` on JPY or KRW only

- **You see** — every order in a zero-decimal currency fails validation.
- **Check** — reproduce with `--currency=JPY`: the rejected amount is exactly 100× the order total.
- **Fix** — make `toMinorUnits` currency-aware. **Keep the guard** — it is what prevents a 100× charge.


> [!WARNING]
> Never add a retry after a timeout — see
> [Decisions](../decisions.md#no-automatic-retry-after-an-unknown-outcome).
