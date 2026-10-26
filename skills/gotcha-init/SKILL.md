---
name: gotcha-init
description: Build this repository's project memory — ask the human-docs language and publication channels (multiselect: docs/ folder, PDF, Claude artifact, Claude Docs, Google Drive, Notion, Confluence, GitHub wiki, …), analyse the codebase in parallel, write the base in gotchas/ pre-filled with what the code proves, then publish the human-friendly docs with diagrams. Use right after installing gotcha, when the session-start hook says there is no base, when the user asks to set up / initialize / bootstrap gotcha or the project docs, or to migrate a gotcha 0.1 base (failure-modes.md).
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
- **Existing doc tooling** — a `docs/` folder (and whether it is a MkDocs /
  Docusaurus site), links to Confluence or Notion in the README. They inform the
  defaults proposed in Phase 2.

A large monorepo gets **one base per bounded context** (`apps/billing/gotchas/`),
not one global base. Ask which one if ambiguous.

## Phase 2 — Setup questions

Ask everything in **one** round (use the question tool if available, with the
default first and marked recommended; the question tool allows 4 questions per
call: language, the two channel questions, and the plan):

1. **Language of the human docs** — `en` by default. Propose the language of the
   existing docs or commit messages if it differs.
2. **Where to publish them — multiselect, any combination.** The question tool
   caps options at 4, so split the channels over two questions (they count as
   one round). Default `docs` first, marked recommended; nothing ticked ⇒ `none`.
   - *In the repo and in Claude:* `docs/ folder` (recommended) · `PDF` (one
     bundle built from the docs) · `Claude artifact` (private page) · `Claude Docs`
   - *External tools:* `Confluence` · `Notion` · `Google Drive` · `GitHub wiki`
   - "Other" ⇒ `other:<tool>` (Outline, GitBook, Coda, …).

   Then, once, for every remote channel chosen (Confluence, Notion, Drive,
   GitHub wiki, other): ask its location (space / parent page URL, folder, …) and
   check that a matching connector is available in this session. Missing ⇒ say
   how to add it and drop that channel for now (keep it in the manifest only if
   the user insists; `/gotcha-publish` falls back to `docs` for it).
3. **The plan** — one compact table: areas, scopes → seed themes, entities,
   `autocapture` mode (default `auto`). Confirm or adjust.

These are the only questions in the whole init — make them count. The source
base in `gotchas/` stays in English unless the user asks otherwise: it is grepped
against code and log strings.

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
| `gotchas/manifest.yml` | `templates/manifest.yml` | Phase 1–2, including the `publish_*` answers (`publish_targets` as a comma-separated list; `publish_location_<channel>` per remote channel; `publish_when: manual` unless `docs` is the only channel). Every path real; `evidence:` commands only if verified |
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

## Phase 5 — First publication

Run `/gotcha-publish --all`: the human docs, with their diagrams, in the chosen
language and to every chosen channel. This is the part most people will actually look at — check
the main diagrams render and read well (`references/diagrams.md`).

## Phase 6 — Wire it up and check

1. Add to the repo's agent instruction file (`CLAUDE.md`, or `AGENTS.md`), two
   lines at most: the project memory is in `gotchas/` (start from
   `gotchas/INDEX.md`); keep it up to date in the same change set, and drop a
   `gotcha: <fact>` comment when the code teaches something mid-task.
2. Run `sh ${CLAUDE_PLUGIN_ROOT}/scripts/stats.sh gotchas` and fix every flag.
   `INDEX.md` over 60 lines on day one means the pages are too fine-grained.
3. Report: source pages created, human pages published (and where), areas
   covered, what is deliberately empty, and the `_Unknown_` count — the to-do
   list the first weeks of work will close. Say that both will now grow on their
   own: every task reads the base first, writes back what it lacked, and the
   human docs follow.

## Rules

- Every fact cites repo-relative `path/to/file.ext:line`. No citation, no entry.
- Mark every gap `_Unknown — not confirmed in code_`. Never guess partner
  behaviour, remote semantics, or intent.
- Do not restate what the code says plainly. A module page that lists every
  class is a worse `ls`. Write what a newcomer could not get from one read: the
  flow across files, the invariant, the trap, the reason.
- Prefer fewer, fuller pages. Seven solid pages beat thirty stubs.
