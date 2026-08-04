# <Entity name>

> One file per entity (partner, provider, tenant, plugin). Every statement must
> be backed by code — cite `file:line`. Mark gaps
> `_Unknown — not confirmed in code_` rather than guessing.

## Identity

| Field | Value |
|---|---|
| Kind | <partner \| provider \| tenant \| plugin> |
| Identifier in code | <enum case, config key or UUID, with its path> |
| Identifier in data | <the string stored in rows, mappings, payloads> |

## Authentication

How this codebase authenticates against it: scheme, the class that builds the
credentials, the env/config keys involved.

## Interface

- Base URLs and the endpoints actually called by the code
- Pagination and rate limits as handled in code — cite the limiter or cursor
- Data formats and notable payload shapes

## Flows

| Flow | Direction | Entry point |
|---|---|---|

## Configuration

Config keys, env vars, per-tenant settings, fixtures. Cite each source.

## Implementation map

The classes specific to this entity, with paths.

## Known quirks

The reason this page exists. Behaviours that are true of this entity and not of
its siblings: undocumented remote responses, error codes that mean something
else, ordering constraints, silent truncation, fields that lie. Cite the code
that proves each one, or the source that confirmed it.
