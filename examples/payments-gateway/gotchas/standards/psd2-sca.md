# PSD2 / Strong Customer Authentication

> Synthetic example. The cited paths do not exist — only the shape is real.

Scope of this page: the parts of SCA that change how our code behaves. Not a
summary of the directive — read the regulation for that.

## What it forces on us

Card payments where both the customer's bank and ours are in the EEA require
two-factor authentication, delivered in practice as a 3-D Secure challenge. The
consequence for the code: **a charge has a third outcome besides success and
failure** — `requires_action`, meaning "redirect the customer and come back".
Anything modelling payment as a boolean is wrong under SCA.

## The soft decline is not a failure

An issuer that wants authentication returns a decline whose code means "retry
this with 3DS", not "no". Our `SOFT_DECLINE_CODES` list
(`src/payments/providers/codes.ts:8`) captures those, and `ChargeService` routes
them into the challenge flow rather than to the customer as a failure
(`ChargeService.ts:96`).

Getting this wrong is expensive and invisible: every soft decline treated as a
hard one is a lost sale that shows up in no error dashboard, only in conversion.

## Exemptions we claim

| Exemption | Claimed when | Where |
|---|---|---|
| Low value (< €30) | amount below threshold, counter permitting | `sca/exemptions.ts:21` |
| Recurring / MIT | subsequent charge of a stored mandate | `sca/exemptions.ts:34` |
| TRA | not claimed | — |

Two limits on the low-value exemption that the code must respect: it is capped
at **five consecutive uses** or **€100 cumulative** per card, whichever comes
first, and the counter is **held by the issuer, not by us**. So the exemption
can be refused at any time for reasons we cannot see locally. A refused
exemption looks like a random challenge on a payment that "should" have been
exempt — it is correct behaviour, not a bug.

`_Unknown — not confirmed in code_`: whether we track our own approximation of
that counter, or simply claim the exemption and let the issuer decide.

## Liability shift

A completed challenge moves fraud-chargeback liability to the issuer. Claiming
an exemption keeps it with us. So the SCA path is not only a compliance
constraint — skipping a challenge is a deliberate trade of conversion against
chargeback exposure. Any change to `exemptions.ts` is a financial decision, not
a technical one.

## Operational consequence

A challenge is a **human-latency** step: the customer switches to a banking app,
possibly on another device. Minutes, not seconds. The session TTL must exceed
the challenge lifetime — the mismatch is the "customer completes 3DS, returns to
an expired session" row in `failure-modes.md`.
