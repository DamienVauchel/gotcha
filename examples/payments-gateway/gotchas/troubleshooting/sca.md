# SCA — troubleshooting

> **TL;DR** — a 3-D Secure challenge takes minutes; the session must outlive it.
> "Every card challenged" means the exemption field was dropped from the payload.
> A refused exemption is the issuer's call, not a bug.
>
> <sub>verified 2026-09-14 @ 3f9c2ab · scope: src/payments/sca/ · synthetic example</sub>

## Map

Spec-side rules: [PSD2 / SCA](../standards/psd2-sca.md). Code entry
`src/payments/sca/ChallengeFlow.ts:33`; exemptions `src/payments/sca/exemptions.ts:21`.

## Cards

### TS-012 · Customer completes 3DS, returns to an expired session
<sub>keywords: session expired after 3DS, challenge timeout, logged out after payment · seen 2 · last 2026-06-18 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — challenge passed, customer lands on a login page, order unpaid.
- **Cause** — session TTL (`src/config/session.ts:14`) shorter than the challenge.
- **Check** — compare `session.expires_at` with the challenge `created_at`.
- **Fix** — extend TTL during an open challenge.
- **Repair** — the charge may have succeeded: check the attempt before asking the customer to pay again.

### TS-013 · Every card triggers a challenge
<sub>keywords: always 3DS, every payment challenged, exemption ignored · seen 1 · last 2026-01-09 · verified 2026-09-14 @ 3f9c2ab</sub>

- **Symptom** — low-value payments that should be exempt are all challenged.
- **Cause** — the exemption request was dropped from the outbound payload.
- **Check** — inspect the outbound body for the exemption field named in
  [PSD2 / SCA](../standards/psd2-sca.md). Present ⇒ the issuer refused it: normal.
- **Fix** — restore the field in `src/payments/sca/exemptions.ts:21`.
- **Repair** — none.
