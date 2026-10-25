<!-- gotcha:generated · sources: overview.md, modules/charge.md, decisions.md · edit gotchas/ instead, this page is rebuilt -->

# Architecture

## The areas

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart LR
  classDef actor fill:#e1d5e7,stroke:#9673a6,stroke-width:1.5px,color:#1f2937
  classDef service fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px,color:#1f2937
  classDef store fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef external fill:#f5f5f5,stroke:#666666,stroke-width:1.5px,stroke-dasharray:5 4,color:#1f2937

  shop(["🛒 Checkout"]):::actor
  psp["🌐 Stripe · Adyen"]:::external

  subgraph payments["📦 src/payments"]
    charge("<b>Charge</b><br/><small>ChargeService</small>"):::service
    sca("<b>SCA</b><br/><small>ChallengeFlow</small>"):::service
    webhook("<b>Webhook</b><br/><small>verify → enqueue → process</small>"):::service
    recon("<b>Reconciliation</b><br/><small>⏰ nightly job</small>"):::service
    db[("<b>Postgres</b><br/><small>payment_attempts</small>")]:::store
  end

  shop -->|1 · charge| charge
  charge -->|2 · intent| psp
  charge -.->|requires_action| sca
  psp -->|3 · webhook| webhook
  webhook -->|4 · order paid| db
  charge --> db
  psp -->|D-1 report| recon
  recon -->|settle pending| db
```

*Follow the numbers: the charge starts the payment, the webhook finishes it.
Reconciliation is the safety net for everything in between.*

| Area | Responsibility | Read more |
|---|---|---|
| **Charge** | turns "charge order X" into a provider charge; owns the attempt lifecycle | [Charge](modules/charge.md) |
| **SCA** | runs the 3-D Secure challenge when the issuer asks for it | [PSD2 / SCA](standards/psd2-sca.md) |
| **Webhook** | verifies provider events, queues them, and is the **only** writer of "order paid" | [Troubleshooting · Webhooks](troubleshooting/webhooks.md) |
| **Refund** | full and partial refunds, always asynchronous at the provider | [Troubleshooting · Refund](troubleshooting/refund.md) |
| **Reconciliation** | nightly match against each provider's settlement report | [Troubleshooting · Reconciliation](troubleshooting/reconciliation.md) |

## The main flow

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","lineColor":"#6b7280","actorBkg":"#dae8fc","actorBorder":"#6c8ebf","actorTextColor":"#1f2937","actorLineColor":"#cbd5e1","signalColor":"#4b5563","signalTextColor":"#1f2937","noteBkgColor":"#fff2cc","noteBorderColor":"#d6b656","noteTextColor":"#1f2937","activationBkgColor":"#ffe6cc","activationBorderColor":"#d79b00","labelBoxBkgColor":"#f8cecc","labelBoxBorderColor":"#b85450","loopTextColor":"#1f2937"},"sequence":{"mirrorActors":false,"messageMargin":38,"boxMargin":12,"noteMargin":12,"actorMargin":70}}}%%
sequenceDiagram
  autonumber
  participant C as 🛒 Checkout
  participant S as Charge
  participant P as 🌐 Provider
  participant W as Webhook
  participant DB as 🗄️ Postgres
  C->>S: charge(order, amount)
  S->>DB: insert attempt · pending
  S->>+P: create + confirm intent
  P--)W: payment succeeded
  Note over P,W: may arrive before the<br/>confirm call returns
  W->>DB: mark order paid
  P-->>-S: result
  S->>DB: attempt · authorized
```

*The webhook can overtake the API response. Nothing in the flow may assume the
attempt row is already updated when the webhook lands.*

## The payment lifecycle

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart LR
  classDef ok fill:#d5e8d4,stroke:#82b366,stroke-width:1.5px,color:#1f2937
  classDef warn fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef bad fill:#f8cecc,stroke:#b85450,stroke-width:1.5px,color:#1f2937
  classDef note fill:#ffffff,stroke:#d6b656,stroke-width:1px,stroke-dasharray:3 3,color:#4b5563
  classDef term fill:#374151,stroke:#374151,color:#ffffff

  start(( )):::term --> pending
  pending(["⏳ pending"]):::warn -->|provider OK| authorized(["✅ authorized"]):::ok
  pending -->|soft decline| ra(["🔐 requires_action"]):::warn
  ra -->|3DS passed| authorized
  pending -->|hard decline| failed(["⛔ failed"]):::bad
  pending -.- n1["💬 timeout → stays <b>pending</b><br/><small>no retry · settled overnight</small>"]:::note
  authorized -->|capture| captured(["💰 captured"]):::ok
```

*`pending` is not an error state: after a timeout it is the deliberate answer to
"we don't know yet" — see [Decisions](decisions.md#no-automatic-retry-after-an-unknown-outcome).*

## Stack

| Layer | Choice |
|---|---|
| Runtime | Node 22, TypeScript |
| Storage | Postgres — `payment_attempts`, `refunds`, `webhook_events`, `settlement_runs` |
| Queues | `payments.webhooks` (DLQ after 5 attempts), `payments.receipts` (best effort) |
| Providers | Stripe, Adyen |
