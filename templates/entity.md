# <Entity name>

> **TL;DR** — what makes this one different from its siblings: the quirk that
> bites first.
>
> <sub>verified <YYYY-MM-DD> @ <sha></sub>

One file per entity (partner, provider, tenant, plugin). Every statement cites
`path/to/file.ext:line`; gaps are `_Unknown — not confirmed in code_`.

## Identity

| Field | Value |
|---|---|
| Kind | <partner \| provider \| tenant \| plugin> |
| Identifier in code | <enum case, config key or UUID, with its path> |
| Identifier in data | <the string stored in rows, mappings, payloads> |

## Authentication

Scheme, the class that builds the credentials, the env / config keys involved.

## Interface

- Base URLs and the endpoints actually called by the code
- Pagination and rate limits as handled in code — cite the limiter or cursor
- Data formats and notable payload shapes

## Flows

| Flow | Direction | Entry point |
|---|---|---|

## Configuration

Config keys, env vars, per-tenant settings, fixtures. Cite each source.

## Known quirks

The reason this page exists. What is true of this entity and not of its
siblings: undocumented responses, error codes that mean something else, ordering
constraints, silent truncation, fields that lie. Cite the code or the source.
