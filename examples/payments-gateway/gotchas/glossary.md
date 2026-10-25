# Glossary

> **TL;DR** — "payment" in conversation is an **attempt** in the code; "3DS" is
> **SCA** / `requires_action`; "settlement" is **reconciliation**.
>
> <sub>verified 2026-09-14 @ 3f9c2ab · synthetic example</sub>

| Term people use | Name in code | Meaning | Where |
|---|---|---|---|
| payment | `PaymentAttempt` | one try to charge an order; an order can have several | `src/payments/charge/PaymentAttempt.ts:8` |
| 3DS, challenge | `requires_action`, `ChallengeFlow` | the SCA step where the customer authenticates | `src/payments/sca/ChallengeFlow.ts:33` |
| settlement | `SettlementRun` | nightly match against the provider's report | `src/payments/reconciliation/SettlementRun.ts:26` |
| PSP ref | `provider_ref` / `pspReference` | the provider's id for a charge | `src/payments/providers/adyen/mapResult.ts:12` |
