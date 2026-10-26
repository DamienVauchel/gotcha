<!-- gotcha:generated · sources: decisions.md · edit gotchas/ instead, this page is rebuilt -->

# Decisions

Some parts of this module look wrong on purpose. Each decision below says what
was chosen, what was rejected, and when it would be worth revisiting. **Read the
relevant one before "fixing" something.**

## No automatic retry after an unknown outcome

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart TB
  classDef service fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px,color:#1f2937
  classDef ok fill:#d5e8d4,stroke:#82b366,stroke-width:1.5px,color:#1f2937
  classDef warn fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef bad fill:#f8cecc,stroke:#b85450,stroke-width:1.5px,color:#1f2937
  classDef note fill:#ffffff,stroke:#d6b656,stroke-width:1px,stroke-dasharray:3 3,color:#4b5563

  t(["⏱️ timeout on confirm"]):::warn --> q{"Did the request<br/>reach the provider?"}:::warn
  q -->|option A| a("<b>Retry</b><br/><small>rejected</small>"):::bad
  q -->|option B| b("<b>Leave pending</b><br/><small>chosen</small>"):::ok
  a -.- ra["💬 may charge twice"]:::note
  b --> r("<b>Reconciliation</b><br/><small>settles within 24 h</small>"):::service
```

*Neither option can answer the question at the moment of the timeout — so the design
waits for one instead of guessing.*

- **Chosen** — leave the attempt `pending`; the nightly reconciliation settles it.
- **Rejected** — retrying with the same idempotency key. It is safe only if the
  first request reached the provider, which is exactly what a timeout leaves unknown.
- **Revisit if** — the 24 h delay becomes the complaint. Then add a status lookup
  at the provider **before** any retry; never a blind retry.

## Receipts and analytics are best effort

- **Chosen** — failures to send the receipt or the analytics event are logged as
  warnings and never fail the payment.
- **Why** — a mail outage must not turn a successful payment into an error; the
  money has already moved.
- **Consequence** — "charged but no receipt" leaves no error anywhere, only the
  warning `receipt dispatch failed`.
- **Revisit if** — receipts become a legal requirement in a market we serve.

## Only the webhook marks an order paid

- **Chosen** — the webhook processor is the single writer of "order paid".
- **Why** — outcomes are asynchronous (3DS, pending payments, refunds); one path
  for every outcome instead of two that could disagree.
- **Rejected** — also marking paid on a synchronous success: two writers, and the
  webhook may arrive first anyway.

## A missing settlement report is not a failure

- **Chosen** — log `report not yet available`, exit successfully, retry 4 h later.
- **Why** — providers publish at different hours; failing paged on-call every
  night for a normal situation, and real failures started being ignored.
- **Revisit if** — a provider stops publishing altogether: alert on unmatched days
  older than 24 h instead.

## Unknown webhook event types are acknowledged

- **Chosen** — log at `info` and answer 2xx.
- **Why** — providers add event types all the time; rejecting them fills their
  retry queues.
- **Revisit if** — a renamed event is missed again: alert on the rate of
  `unhandled webhook event` per type.
