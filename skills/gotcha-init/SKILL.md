---
name: gotcha-init
description: Bootstrap an gotcha knowledge base in this repository — scan the code to propose scopes and entities, then scaffold gotchas/ (manifest, index, failure-modes page, entity pages) pre-filled with what the code already proves. Use when the user asks to set up gotcha, initialize a knowledge base, or when /gotcha-investigate reports no manifest.
argument-hint: "[subsystem or directory to scope the knowledge base to]"
---

# gotcha-init

Create the knowledge base. Nobody hand-writes 600 lines of failure modes, so
this pre-fills from the code and leaves explicit gaps rather than prose.

## Phase 1 — Scope the base

1. Determine the subject: the argument if given, else the repo root. A large
   monorepo gets **one base per bounded context / module**, not one global base
   (`src/Connect/_docs/`, `src/Billing/_docs/`, …). Ask which one if ambiguous.
2. Detect **scopes** — the axes a bug gets classified along. Derive them from
   the code, not from imagination: top-level directories under the subject,
   distinct integration protocols, distinct entry-point families (HTTP
   controllers, queue consumers, CLI commands, cron), external partners.
3. Detect **entities** — the recurring per-instance thing worth its own page:
   partners, integrations, providers, tenants, plugins. Usually an enum, a
   registry, a config map, or a directory of sibling adapters. No such axis in
   this repo means no entity pages — say so and skip them.
4. Show scopes + entities to the user and get confirmation before writing.

## Phase 2 — Write the manifest

Copy `templates/manifest.yml` to `gotchas/manifest.yml` and fill it from what
Phase 1 found. Every path in it must be real. Only fill `evidence:` commands
you actually verified exist (a `docker exec` line, a log query, a test runner) —
a wrong repro command is worse than a missing one.

## Phase 3 — Scaffold the pages

| File | From | Pre-fill with |
|---|---|---|
| `gotchas/INDEX.md` | `templates/INDEX.md` | one line per page, grouped by scope |
| `gotchas/failure-modes.md` | `templates/failure-modes.md` | one section per scope |
| `gotchas/entities/<name>.md` | `templates/entity.md` | one per confirmed entity |
| `gotchas/_template.md` | `templates/entity.md` | verbatim, for future entities |

Pre-fill `failure-modes.md` per scope from **evidence in the code**:

- **Exception table** — every custom exception class in the scope: name, path,
  and the condition at its throw site. Read the throw site; do not infer the
  meaning from the class name.
- **Silent-failure traps** — every `catch` that swallows (logs and continues,
  returns null/empty, `return;`) and every early `return` that drops work.
  These are the highest-value entries in the whole base: they are invisible in
  logs and cost hours per incident.
- **Entry points** — controllers, consumers, CLI commands, scheduled jobs, with
  their route/queue/command name.
- **Repair handles** — commands and endpoints that fix state (backfill, replay,
  retry, reindex, fix-*).

Leave the symptom → cause → check tables **empty with their header row**. They
fill up from real incidents via `/gotcha-investigate`; inventing rows poisons the
base with unverified guesses.

## Phase 4 — Wire it up

1. Add to the repo's agent instruction file (`CLAUDE.md`, `AGENTS.md`) a short
   pointer, two lines at most: read `gotchas/INDEX.md` before investigating;
   drop a `// gotcha: <fact>` marker when the code teaches you something, and run
   `/gotcha-capture` to route them. The SessionStart hook handles the rest.
2. Report: files created, scopes covered, and what is deliberately empty.

## Rules

- Every statement in a generated page cites `path/to/file.ext:line`. A fact
  without a citation cannot be lint-checked later, so it does not go in.
- Mark every gap `_Unknown — not confirmed in code_`. Never guess partner
  behaviour, remote semantics, or intent.
- Do not restate what the code says plainly. The base holds what is **not**
  obvious from reading the code once: swallowed errors, remote quirks,
  deliberate trade-offs, diagnostic handles.
