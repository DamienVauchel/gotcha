<!-- gotcha:generated · sources: troubleshooting/reconciliation.md · edit gotchas/ instead, this page is rebuilt -->

# Troubleshooting · Reconciliation

Every night, each provider's settlement report for the previous day is matched
against our attempts. This is what settles every payment left `pending`.

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart LR
  classDef service fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px,color:#1f2937
  classDef ok fill:#d5e8d4,stroke:#82b366,stroke-width:1.5px,color:#1f2937
  classDef warn fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef bad fill:#f8cecc,stroke:#b85450,stroke-width:1.5px,color:#1f2937

  job("<b>⏰ Settlement run</b><br/><small>nightly</small>"):::service --> q{"Report<br/>available?"}:::warn
  q -->|no| later(["exit 0 · retry in 4 h"]):::warn
  q -->|yes| m("<b>Match</b><br/><small>report ↔ attempts</small>"):::service
  m --> a(["local pending, nothing at provider<br/>→ failed · benign"]):::ok
  m --> b(["provider charge, no local row<br/>→ alert · money left unrecorded"]):::bad
```

*A green run is not a reconciled day: when the report is late the job succeeds
without matching anything.*

## Known problems

### Job green, attempts still pending

- **You see** — the settlement job succeeded but `pending` attempts remain for that day.
- **Check** — the latest `settlement_runs` rows: an empty `matched_at` means the report was not there yet.
- **Fix** — nothing — expected until the 4-hour retry.
- **Repair** — `payments:reconcile --day=YYYY-MM-DD` once the report exists.

### Provider charge with no local record

- **You see** — reconciliation alert: money taken at the provider, no attempt on our side.
- **Check** — find the idempotency key in the provider dashboard, then look it up in `payment_attempts`.
- **Fix** — persist the attempt **before** calling the provider.
- **Repair** — insert the attempt from the provider record, then re-run the day.
