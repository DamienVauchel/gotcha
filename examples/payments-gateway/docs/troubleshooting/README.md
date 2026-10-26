<!-- gotcha:generated · sources: troubleshooting/charge.md, troubleshooting/webhooks.md, troubleshooting/refund.md, troubleshooting/reconciliation.md, troubleshooting/sca.md · edit gotchas/ instead, this page is rebuilt -->

# Troubleshooting

Search this folder for the exact error message or log line first — every known
problem lists the strings it shows up with. Otherwise start from what you see:

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart LR
  classDef actor fill:#e1d5e7,stroke:#9673a6,stroke-width:1.5px,color:#1f2937
  classDef service fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px,color:#1f2937

  s(["🔎 What do you see?"]):::actor
  s --> w("<b>Webhooks</b><br/><small>order unpaid · signature errors</small>"):::service
  s --> c("<b>Charge</b><br/><small>double charge · stuck pending · no receipt</small>"):::service
  s --> r("<b>Refund</b><br/><small>refund missing · refunded too much</small>"):::service
  s --> rc("<b>Reconciliation</b><br/><small>settlement · unmatched charge</small>"):::service
  s --> sc("<b>SCA</b><br/><small>3DS · session expired</small>"):::service
```

| Theme | Typical symptoms |
|---|---|
| [Webhooks](webhooks.md) | `SignatureVerificationError`, order unpaid after a successful charge, duplicate webhook |
| [Charge](charge.md) | double charge, attempt stuck `pending`, `AmountMismatchError` on JPY, no receipt |
| [Refund](refund.md) | refund never received, refunded more than captured |
| [Reconciliation](reconciliation.md) | job green but still pending, provider charge with no local record |
| [SCA](sca.md) | session expired after 3DS, every card challenged |
