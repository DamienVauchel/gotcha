---
name: gotcha-init
description: Build this repository's project memory — analyse the codebase (in parallel, one surveyor per area), then write the base docs in gotchas/ (overview, modules, conventions, glossary, decisions, entities, troubleshooting themes) pre-filled with what the code proves. Use right after installing gotcha, when the session-start hook says there is no base, when the user asks to set up / initialize / bootstrap gotcha or the project docs, or to migrate a gotcha 0.1 base (failure-modes.md).
argument-hint: "[subsystem or directory to scope the base to — defaults to the repo]"
---

# gotcha-init

Write the first version of the project memory from the code. Nobody hand-writes
a base, so this one is generated — and it must be **trustworthy from day one**:
everything cited, gaps marked, nothing invented.

Read first, they are the authority on shape and rules:

- `${CLAUDE_PLUGIN_ROOT}/references/page-format.md`
- `${CLAUDE_PLUGIN_ROOT}/references/capture-contract.md` (durability test, writing rules)
- `${CLAUDE_PLUGIN_ROOT}/references/organization.md` (size caps)

Templates live in `${CLAUDE_PLUGIN_ROOT}/templates/`.

## Phase 0 — What is already there

- `gotchas/manifest.yml` exists ⇒ this is a re-run. Ask: **refresh** (re-survey
  and fill gaps, never overwrite a human-written fact) or **stop**.
- `gotchas/failure-modes.md` exists ⇒ a gotcha 0.1 base. Migrate: each scope
  section becomes `troubleshooting/<scope>.md` (tables → **Map**, symptom rows →
  `TS-NNN` cards with `seen 1`), then survey for the new page kinds.
- Existing docs (`README`, `docs/`, ADRs, `CONTRIBUTING`, `CLAUDE.md`) are
  **inputs**: link to them, extract the non-obvious facts, do not copy them.

## Phase 1 — Cheap reconnaissance (main context, ~10 tool calls)

Read only what describes the repo, not the code itself:

1. The tree, two levels deep, ignoring vendored and generated dirs.
2. Package / build manifests (`package.json`, `pyproject.toml`, `go.mod`,
   `composer.json`, `Cargo.toml`, `pom.xml`, …), `Makefile`, `docker-compose*`,
   CI config. They give the stack, the commands, the services.
3. `README` and the docs index.
4. `git log --oneline -n 300 --name-only | …` to see which areas churn — the
   hot areas deserve the deepest survey.

Derive:

- **Areas** — the 3–12 units a newcomer must understand: bounded contexts,
  top-level modules, apps in a monorepo. Not one per directory.
- **Scopes** — the axes a bug gets classified along: entry-point families
  (HTTP, queue consumers, CLI, cron), integration protocols, partners.
- **Entities** — the recurring per-instance thing worth its own page
  (partners, providers, tenants, plugins). Usually an enum, a registry, a config
  map or a directory of sibling adapters. No such axis ⇒ no entity pages.
- **Language** — the language of the existing docs and commit messages; ask if
  unclear. The base is written in it.

A large monorepo gets **one base per bounded context** (`apps/billing/gotchas/`),
not one global base. Ask which one if ambiguous.

## Phase 2 — Confirm the plan

Show the user, in one compact table: areas, scopes → seed themes, entities,
language, `autocapture` mode (default `auto`). Get confirmation. This is the only
question in the whole init — make it count.

## Phase 3 — Survey in parallel

Spawn one `gotcha-surveyor` agent per area, **in the same message** so they run
in parallel. Give each: the area path, the scopes it touches, the language, and
the plugin root. Each returns a structured findings report and keeps the code
reading out of your context. Small repo (≤ 3 areas, a few thousand lines) ⇒
survey inline instead; the agents are a token budget tool, not a ritual.

While they run, survey the cross-cutting parts yourself: conventions (lint
config, formatter, test layout, error-handling style, naming), the commands to
run / test / build / deploy (verify each one exists), and the glossary.

## Phase 4 — Write the base

| File | From | Fill with |
|---|---|---|
| `gotchas/manifest.yml` | `templates/manifest.yml` | Phase 1–2. Every path real; `evidence:` commands only if verified |
| `gotchas/overview.md` | `templates/overview.md` | purpose, stack, map of areas (mermaid if it helps), how to run / test / ship |
| `gotchas/modules/<area>.md` | `templates/module.md` | surveyor report: role, entry points, flows, invariants, where to change X |
| `gotchas/conventions.md` | `templates/conventions.md` | only rules that are **not** enforced by a linter and **not** obvious |
| `gotchas/glossary.md` | `templates/glossary.md` | domain terms whose code name differs |
| `gotchas/decisions.md` | `templates/decisions.md` | `D-NNN` cards for trade-offs the code or its comments state ("deliberately", "on purpose", "we don't X because", `HACK`, `workaround`) |
| `gotchas/entities/<name>.md` | `templates/entity.md` | one per confirmed entity |
| `gotchas/troubleshooting/<theme>.md` | `templates/theme.md` | **Map** from the code; **Cards** section empty |
| `gotchas/troubleshooting/INDEX.md` | `templates/troubleshooting-INDEX.md` | one row per theme, keywords from the Map |
| `gotchas/INDEX.md` | `templates/INDEX.md` | one hook line per page |
| `gotchas/_template.md` | `templates/entity.md` | verbatim, if there are entities |

Pre-fill each troubleshooting **Map** from evidence in the code:

- **Exceptions** — every custom exception in the scope: name, path, and the
  condition at its throw site. Read the throw site; never infer meaning from the
  class name.
- **Swallowed errors and dropped work** — every `catch` that logs and continues,
  returns null / empty, and every early `return` that drops work. The highest-value
  entries in the base: invisible in logs, hours per incident.
- **Log patterns** — the messages an on-call person will search for.
- **Repair handles** — commands and endpoints that fix state (backfill, replay,
  retry, reindex, fix-*), and whether they are safe to re-run.

Leave the **Cards** sections empty. Cards come from real incidents; an invented
card poisons the base with a confident guess.

Stamp every page `verified <today> @ <git rev-parse --short HEAD>`. Write every
TL;DR last, once the page body exists.

## Phase 5 — Wire it up and check

1. Add to the repo's agent instruction file (`CLAUDE.md`, or `AGENTS.md`), two
   lines at most: the project memory is in `gotchas/` (start from
   `gotchas/INDEX.md`); keep it up to date in the same change set, and drop a
   `gotcha: <fact>` comment when the code teaches something mid-task.
2. Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/stats.sh gotchas` and fix every flag.
   `INDEX.md` over 60 lines on day one means the pages are too fine-grained.
3. Report: pages created, areas covered, what is deliberately empty, and the
   `_Unknown_` count — the to-do list the first weeks of work will close. Say
   that the base will grow on its own from now on: every task reads it first and
   writes back what it lacked.

## Rules

- Every fact cites repo-relative `path/to/file.ext:line`. No citation, no entry.
- Mark every gap `_Unknown — not confirmed in code_`. Never guess partner
  behaviour, remote semantics, or intent.
- Do not restate what the code says plainly. A module page that lists every
  class is a worse `ls`. Write what a newcomer could not get from one read: the
  flow across files, the invariant, the trap, the reason.
- Prefer fewer, fuller pages. Seven solid pages beat thirty stubs.
