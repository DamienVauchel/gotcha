# Reconciliation — troubleshooting

> **TL;DR** — exit code 0 does **not** mean the day reconciled: a missing
> provider report exits 0 on purpose (D-004). Check `settlement_runs.matched_at`.
> A provider charge with no local row is the dangerous direction.
>
> <sub>verified 2026-09-14 @ 3f9c2ab · scope: src/payments/reconciliation/ · synthetic example</sub>

## Map

Nightly job `src/payments/reconciliation/SettlementRun.ts:26`: pulls each
provider's D-1 settlement report and matches it against `payment_attempts`. It
resolves every `pending` attempt left by D-001.

### Swallowed errors and dropped work

- **Missing report ⇒ exit 0** (`src/payments/reconciliation/SettlementRun.ts:71`),
  retried at +4 h. Deliberate: D-004.
- **Local pending, nothing provider-side** ⇒ marked `failed`. Benign timeout case.
- **Provider charge, no local row** ⇒ alerted. Money left with no record.

### Log patterns

| Message / pattern | Emitted at | Means |
|---|---|---|
| `report not yet available` | `src/payments/reconciliation/SettlementRun.ts:71` | Exited 0 without matching; +4 h retry pending |

### Repair handles

| Handle | Repairs | Safe to re-run? |
|---|---|---|
| `npm run cli -- payments:reconcile --day=YYYY-MM-DD` | attempts left `pending` | Yes — matching is idempotent |

## Cards

### TS-010 · Reconciliation "green" but attempts still pending
<sub>keywords: reconciliation green, still pending, report not yet available, settlement · seen 2 · last 2026-07-21 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — job succeeded, `pending` attempts remain for that day.
- **Cause** — the report was not published yet; the run exited 0 (D-004).
- **Check** — `select day, matched_at from settlement_runs order by day desc limit 7` — null `matched_at` is the tell.
- **Fix** — none; it is expected until the +4 h retry.
- **Repair** — `payments:reconcile --day=YYYY-MM-DD` once the report exists.

### TS-011 · Provider charge with no local attempt row
<sub>keywords: unmatched provider charge, orphan charge, missing attempt row, pspReference · seen 1 · last 2026-04-02 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — reconciliation alert: money taken provider-side, nothing local.
- **Cause** — crash between the provider call and the attempt row commit. With
  Adyen, `pspReference` can be absent from the error response
  ([Adyen](../entities/adyen.md)).
- **Check** — find the idempotency key in the provider dashboard, then
  `select * from payment_attempts where idempotency_key = ?`.
- **Fix** — persist the attempt row **before** calling the provider.
- **Repair** — insert the attempt manually from the provider record, then reconcile the day.
