# Hooks

Reference for the three hooks in [`hooks/hooks.json`](https://github.com/DamienVauchel/gotcha/blob/main/hooks/hooks.json). All are POSIX `sh`, 5-second timeout, and degrade silently: `jq` is used when present and never required. The conceptual view is in [How It Works](How-It-Works).

| Hook | Matcher | Script | Blocks? |
|---|---|---|---|
| `SessionStart` | — | `hooks/session-start.sh` | no |
| `PostToolUse` | `Read\|Edit\|Write\|MultiEdit\|NotebookEdit` | `hooks/track.sh` | no |
| `Stop` | — | `hooks/stop.sh` | **yes, once per turn at most** |

## `session-start.sh`

Fires on startup, resume, clear and compact.

- **No `gotchas/INDEX.md`** → in a git repo, emits a `<gotcha-setup>` note offering `/gotcha-init` — **once per repository** (recorded in `${XDG_STATE_HOME:-~/.local/state}/gotcha/offered`). Outside a git repo, nothing.
- **A base exists** → emits `<gotcha-memory mode="…">` with the three-step loop, the `gotcha:` marker convention, how many source pages are behind the human docs (with the configured channels and language), and the first 80 lines of `INDEX.md`.

## `track.sh`

After every file `Read`/`Edit`/`Write`, appends `op<TAB>kind<TAB>path` to a per-session scratch file under `${TMPDIR:-/tmp}/gotcha-<uid>/<session_id>/turn`:

- `kind = base` for anything under `gotchas/`, `code` for anything else in the project, nothing for files outside the project (plans, scratch, memory).
- `op = read` for reads, `edit` for everything else.

It never blocks and never prints.

## `stop.sh`

Reads the turn file and decides. First match wins:

| # | Condition | Outcome |
|---|---|---|
| 1 | no base, or already continuing because of this hook (`stop_hook_active`), or no turn file | exit — never loops |
| 2 | the turn **edited the base** and `publish_when: on-change` and `docs` ∈ `publish_targets` and pages are behind | block: "publish the changed pages only, report in one line" |
| 3 | the turn edited the base otherwise | pass |
| 4 | `autocapture: off` (or `GOTCHA_AUTOCAPTURE=off`) | pass |
| 5 | code edits ≥ `nudge_min_edits` **or** distinct code reads ≥ `nudge_min_reads` | block: apply the capture skill; `propose` ⇒ list and ask, `auto` ⇒ write, no durable finding ⇒ reply exactly `gotcha: nothing durable` |
| 6 | otherwise | pass |

The turn file is deleted at every exit, so state never leaks between turns.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| nothing is injected at session start | no `gotchas/INDEX.md` at the project root (hooks look only there), or the plugin is not enabled |
| the setup offer never reappears | by design — once per repo; delete the line from the `offered` file to see it again |
| the Stop hook never nudges | `autocapture: off`, thresholds too high, or the turn already touched `gotchas/` |
| the Stop hook asks for a publish you do not want | set `publish_when: manual` |
