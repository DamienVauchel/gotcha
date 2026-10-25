<!-- gotcha:generated · sources: troubleshooting/sca.md · edit gotchas/ instead, this page is rebuilt -->

# Troubleshooting · SCA

See [PSD2 / SCA](../standards/psd2-sca.md) for why challenges happen at all.

## Known problems

### Customer passes 3DS, comes back to an expired session

- **You see** — the challenge succeeded, the customer lands on a login page, the order looks unpaid.
- **Check** — compare the session expiry with the time the challenge started.
- **Fix** — keep the session alive while a challenge is open — challenges take minutes.
- **Repair** — the charge may have succeeded: check the attempt before asking the customer to pay again.

### Every card triggers a challenge

- **You see** — small payments that should be exempt are all challenged.
- **Check** — inspect the outgoing payment request for the exemption field. Present ⇒ the issuer refused it, which is normal.
- **Fix** — restore the exemption field in the request.
