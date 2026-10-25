<!-- gotcha:generated · sources: troubleshooting/webhooks.md · edit gotchas/ instead, this page is rebuilt -->

# Troubleshooting · Webhooks

The webhook is what marks an order paid, so **any lost or ignored webhook looks
like a failed payment** to the business.

## Diagnose

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart TB
  classDef actor fill:#e1d5e7,stroke:#9673a6,stroke-width:1.5px,color:#1f2937
  classDef warn fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef bad fill:#f8cecc,stroke:#b85450,stroke-width:1.5px,color:#1f2937

  s(["🔎 Webhook problem"]):::actor
  s --> q1{"Signature errors<br/>since a deploy?"}:::warn
  q1 -->|yes| q2{"Clock delta in the<br/>log line > 300 s?"}:::warn
  q2 -->|yes| skew(["⏱️ Clock skew"]):::bad
  q2 -->|no| secret(["🔑 Secret rotated<br/>in one env only"]):::bad
  q1 -->|no| q3{"Order unpaid after<br/>a successful charge?"}:::warn
  q3 -->|yes| q4{"DLQ empty?"}:::warn
  q4 -->|no| dlq(["📨 Lost in the DLQ → replay"]):::bad
  q4 -->|yes| renamed(["🏷️ Event renamed,<br/>acked as unknown"]):::bad
  q3 -->|ledger doubled| dup(["♊ Upsert key mismatch"]):::bad
```

*Two questions settle most webhook incidents: is it the signature, and did the
event reach a handler at all?*

## Known problems

### Signature errors right after a deploy

- **You see** — every webhook of one provider fails with `SignatureVerificationError` / `signature verification failed`.
- **Check** — the log line carries the clock delta. Over 300 s ⇒ clock skew. Otherwise compare the deployed secret with the one in the provider dashboard.
- **Fix** — fix the host clock (NTP), or align the secret. **Never rotate the secret before checking the skew.**
- **Repair** — providers retry on their own; replay what reached the dead-letter queue.

### Order unpaid although the charge succeeded

- **You see** — money captured, order still unpaid, usually for one provider only.
- **Check** — the dead-letter queue first; then search `unhandled webhook event` grouped by event type — a type appearing in volume is the answer.
- **Fix** — register a handler for the renamed or new event.
- **Repair** — `payments:webhook:replay --event-id=<id>` for each affected event.

### Webhook processed twice

- **You see** — two ledger entries for one provider event.
- **Check** — look for duplicated `provider_event_id` in `webhook_events`.
- **Fix** — normalize the provider id before the upsert.


> [!NOTE]
> Unknown event types are acknowledged on purpose — see
> [Decisions](../decisions.md#unknown-webhook-event-types-are-acknowledged).
