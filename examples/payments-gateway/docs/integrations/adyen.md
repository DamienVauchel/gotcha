<!-- gotcha:generated · sources: entities/adyen.md · edit gotchas/ instead, this page is rebuilt -->

# Adyen

Adyen looks like Stripe from our side — same client interface — but it signals
failure differently. **An HTTP 200 can be a refused payment**, and **refunds can
fail hours after the API accepted them**.

## How a charge and a refund talk to Adyen

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","lineColor":"#6b7280","actorBkg":"#dae8fc","actorBorder":"#6c8ebf","actorTextColor":"#1f2937","actorLineColor":"#cbd5e1","signalColor":"#4b5563","signalTextColor":"#1f2937","noteBkgColor":"#fff2cc","noteBorderColor":"#d6b656","noteTextColor":"#1f2937","activationBkgColor":"#ffe6cc","activationBorderColor":"#d79b00","labelBoxBkgColor":"#f8cecc","labelBoxBorderColor":"#b85450","loopTextColor":"#1f2937"},"sequence":{"mirrorActors":false,"messageMargin":38,"boxMargin":12,"noteMargin":12,"actorMargin":70}}}%%
sequenceDiagram
  autonumber
  participant S as Our code
  participant API as 🌐 Adyen API
  participant WH as Webhook endpoint
  S->>+API: POST /payments
  API-->>-S: HTTP 200 · resultCode
  alt resultCode = Refused
    Note over S: declined — not a success
  end
  S->>+API: POST /payments/:psp/refunds
  API-->>-S: received
  API--)WH: REFUND notification · hours later
  WH-->>API: [accepted]
  Note over WH,API: acknowledges receipt,<br/>not processing
```

*Read the outcome in `resultCode` (step 2), and the refund result in the
notification (step 5), never in the HTTP status.*

## Watch out for

> [!WARNING]
> **HTTP 200 does not mean success.** The outcome is `resultCode`: `Authorised`,
> `Refused`, `Error`, `Pending`, `RedirectShopper`. Code branching on the status
> code alone treats a refusal as a successful charge.

- **Refunds are always asynchronous.** The API response only says the request was
  recorded; the `REFUND` notification can say `success: false` hours later.
- **Answer `[accepted]` only after the event is safely queued.** Adyen will not
  retry an event it considers delivered.
- **`pspReference` is the only durable id** — and some error responses omit it,
  which can leave a charge impossible to link (see
  [Troubleshooting · Reconciliation](../troubleshooting/reconciliation.md)).
- **Two webhook credentials**: HMAC signature *and* basic auth, the latter set in
  the Adyen dashboard. A webhook 401 is not necessarily our bug.
- **Live URLs are per merchant.** A hardcoded live base URL works in test and
  fails in production.
- **Refund window: 13 months** — but our shared check rejects after 180 days.
  Known gap.

> [!NOTE]
> Not confirmed yet: whether our processor reads every item of a batched
> notification or only the first one; and Adyen's idempotency key retention.

## Configuration

| Variable | Purpose |
|---|---|
| `ADYEN_API_KEY` | API calls (`X-API-Key`) |
| `ADYEN_HMAC_KEY` | webhook signatures |
| `ADYEN_MERCHANT_ACCOUNT` | required on every request, differs per region |
| `ADYEN_ENVIRONMENT` | `test` or `live` |
