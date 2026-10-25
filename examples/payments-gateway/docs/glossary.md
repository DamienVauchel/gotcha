<!-- gotcha:generated · sources: glossary.md · edit gotchas/ instead, this page is rebuilt -->

# Glossary

| People say | The code says | Meaning |
|---|---|---|
| payment | `PaymentAttempt` | one try to charge an order — an order can have several |
| 3DS, challenge | `requires_action`, `ChallengeFlow` | the step where the customer authenticates with their bank |
| settlement | `SettlementRun`, reconciliation | the nightly match against each provider's report |
| PSP reference | `provider_ref`, `pspReference` | the provider's id for a charge |
