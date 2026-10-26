# Configuration

`gotchas/manifest.yml` is **the only file that knows about the repository**. Everything else in the plugin is generic. `/gotcha-init` generates it; you can edit it by hand.

> [!NOTE]
> Hooks read **flat top-level scalars** only (`key: value`, one line). Lists such as `publish_targets` are therefore comma-separated on one line, without spaces.

## Full reference

```yaml
subject: src/payments            # module or bounded context this base covers

language: en                     # language of the source base (grepped against code and logs)

# ── Human docs ──────────────────────────────────────────────
publish_targets: docs,notion     # docs | pdf | artifact | claude-docs | drive | notion |
                                 # confluence | github-wiki | other:<tool> | none
publish_language: en             # language of the human docs
publish_dir: docs                # output folder for docs and pdf
publish_location_notion: https://www.notion.so/…
publish_location_confluence: ENG / Platform / Payments
publish_when: on-change          # on-change | manual

# ── Write-back ──────────────────────────────────────────────
autocapture: auto                # auto | propose | off
nudge_min_edits: 1               # Stop hook: code files edited…
nudge_min_reads: 6               # …or distinct code files read, without touching gotchas/

# ── Structure ───────────────────────────────────────────────
scopes:                          # axes a bug is classified along — one troubleshooting theme each
  - http
  - queue-consumers
areas:                           # documented under modules/
  - charge: src/payments/charge
entities:                        # the recurring per-instance thing; delete the key if none
  kind: provider
  source: src/payments/providers/registry.ts
  members: [stripe, adyen]

routing:                         # where a finding goes — every write path follows it literally
  module: gotchas/modules/{area}.md
  overview: gotchas/overview.md
  convention: gotchas/conventions.md
  term: gotchas/glossary.md
  decision: gotchas/decisions.md
  entity_specific: gotchas/entities/{entity}.md
  troubleshooting: gotchas/troubleshooting/{theme}.md
  standard: gotchas/standards/{name}.md
  index: gotchas/INDEX.md
  troubleshooting_index: gotchas/troubleshooting/INDEX.md
  entity_template: gotchas/_template.md

evidence:                        # ONLY commands you have verified exist
  logs: '@service:{service} status:error'
  repro: make repro
  tests: npm test -- payments
  state: psql -c 'select …'

scope_docs:                      # existing docs the skills should read for a scope (optional)
  http: docs/api.md
```

## Publishing keys

| Key | Values | Default |
|---|---|---|
| `publish_targets` | comma-separated, any mix of `docs` · `pdf` · `artifact` · `claude-docs` · `drive` · `notion` · `confluence` · `github-wiki` · `other:<tool>` — or `none` | `docs` |
| `publish_language` | any language code | `en` |
| `publish_dir` | output folder for `docs` and `pdf` | `docs` |
| `publish_location_<channel>` | per remote channel: space + parent page URL, Notion parent URL, Drive folder… | — |
| `publish_when` | `on-change` — the Stop hook asks for a `docs` publish after any turn that changed the source · `manual` | `on-change` for `docs`, `manual` otherwise |

`publish_targets: none` makes `/gotcha-publish` stop immediately and silences the "docs are behind" notices.

## Write-back keys

| Key | Values | Default |
|---|---|---|
| `autocapture` | `auto` · `propose` · `off` — see [How It Works](How-It-Works#autocapture-modes) | `auto` |
| `nudge_min_edits` | code files edited before the Stop hook nudges | `1` |
| `nudge_min_reads` | distinct code files read before the Stop hook nudges | `6` |

## Environment variables

| Variable | Used by | Effect |
|---|---|---|
| `GOTCHA_AUTOCAPTURE` | Stop hook | overrides `autocapture:` for the session |
| `GOTCHA_BASE_DIR` | `publish-check.sh` | base directory (default `gotchas`) |
| `GOTCHA_INDEX_MAX` · `GOTCHA_PAGE_MAX` · `GOTCHA_CARDS_MAX` · `GOTCHA_CARDS_MIN` · `GOTCHA_COLD_DAYS` | `stats.sh` | organization thresholds (60 · 300 · 15 · 3 · 365). Global, never per page |
| `CLAUDE_PROJECT_DIR` | hooks | project root (falls back to the current directory) |
| `CLAUDE_PLUGIN_ROOT` | hooks, skills | where the plugin is installed |

## Rules of thumb

- **`evidence:` only holds commands you have verified.** A wrong repro command costs more than a missing one.
- **Every path in `areas:` and `routing:` must be real.**
- **Keep `language: en`** unless the team insists: the source base is grepped against English code and log strings. Translate through `publish_language` instead.
