<!-- gotcha:generated · sources: troubleshooting/refund.md · edit gotchas/ instead, this page is rebuilt -->

# Troubleshooting · Refund

Refunds are asynchronous at both providers: the API answer means **recorded**,
not **done**. The real outcome comes later, by webhook.

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","lineColor":"#6b7280","actorBkg":"#dae8fc","actorBorder":"#6c8ebf","actorTextColor":"#1f2937","actorLineColor":"#cbd5e1","signalColor":"#4b5563","signalTextColor":"#1f2937","noteBkgColor":"#fff2cc","noteBorderColor":"#d6b656","noteTextColor":"#1f2937","activationBkgColor":"#ffe6cc","activationBorderColor":"#d79b00","labelBoxBkgColor":"#f8cecc","labelBoxBorderColor":"#b85450","loopTextColor":"#1f2937"},"sequence":{"mirrorActors":false,"messageMargin":38,"boxMargin":12,"noteMargin":12,"actorMargin":70}}}%%
sequenceDiagram
  autonumber
  participant R as RefundService
  participant P as 🌐 Provider
  participant W as Webhook
  R->>+P: refund
  P-->>-R: received
  Note over R: not done yet
  P--)W: refund result · minutes to hours later
  alt success: false
    Note over W: refund failed —<br/>customer not repaid
  end
```

*Only the notification (step 3) tells whether the customer was repaid.*

## Known problems

### Refund "succeeded", money never returned

- **You see** — the refund shows as done, the customer says nothing arrived.
- **Check** — look for the refund webhook for that payment, not the API response.
- **Fix** — mark refunds done from the webhook only.
- **Repair** — re-issue the refund once the failure reason is known.

### Refunded more than was captured

- **You see** — the refunds add up to more than the captured amount.
- **Check** — two refund rows for the same attempt created less than a second apart.
- **Fix** — serialize refunds per attempt (row lock or queue) — the current guard reads without a lock. **Known gap.**


> [!NOTE]
> Our refund window check uses 180 days for every provider. That is right for
> Stripe and too strict for Adyen (13 months).
