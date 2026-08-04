# <Entity name>

> One file per entity (partner, provider, tenant, plugin). Every statement must
> be backed by code — cite `file:line`. Mark gaps
> `_Unknown — not confirmed in code_` rather than guessing.

## Identity

| Field | Value |
|---|---|
| Kind | provider |
| Identifier in code | <`PROVIDERS.x` in `src/payments/providers/registry.ts`> |
| Identifier in data | <the string stored in `payment_attempts.provider`> |

## Authentication

Scheme, the class that builds the credentials, the env keys involved. Note when
webhook credentials are separate from API credentials — rotating one and not the
other is a recurring incident.

## Interface

- Endpoints actually called by the code
- Idempotency mechanism and its **retention window**
- Amount representation and minor-unit handling
- Pagination and rate limits as handled in code

## Flows

| Flow | Direction | Entry point |
|---|---|---|

## Configuration

Env vars, per-region accounts, pinned API versions. Cite each source.

## Implementation map

The classes specific to this provider, with paths.

## Known quirks

The reason this page exists. What is true of this provider and not of its
siblings: success signalled somewhere other than the status code, async
outcomes reported as sync, ids missing from error responses, windows and
tolerances that differ, batched deliveries. Cite the code or the source that
proves each one.
