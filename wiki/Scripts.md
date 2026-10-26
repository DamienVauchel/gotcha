# Scripts

Four POSIX `sh` helpers in [`scripts/`](https://github.com/DamienVauchel/gotcha/tree/main/scripts). They cost **no reading**: the skills run them instead of opening pages to decide what to do. Run them from the repository root.

| Script | Question it answers |
|---|---|
| [`stats.sh`](#statssh) | Is any page over its caps? What are the next card ids? |
| [`stale.sh`](#stalesh) | Which cited files changed since the fact was verified? |
| [`publish-check.sh`](#publish-checksh) | Which human pages are behind their source? |
| [`render-diagrams.sh`](#render-diagramssh) | Does every Mermaid block render? |

## `stats.sh`

```sh
sh scripts/stats.sh [base-dir]        # default: gotchas
```

One line per page — lines, cards, cold cards, `verified` date, flags — then the next free ids and the number of unharvested `gotcha:` markers.

```
page                                          lines cards  cold verified    flags
overview.md                                      64     -     -  2026-09-14
troubleshooting/webhooks.md                     212    16     2  2026-09-14  SPLIT(cards) COLD

next ids: TS-031 D-004 · unharvested gotcha: markers: 0
```

Flags: `INDEX>60` · `SPLIT(lines)` · `SPLIT(cards)` · `MERGE?` · `COLD` · `NO_TLDR` · `UNINDEXED`. Thresholds are overridable ([Configuration](Configuration#environment-variables)); rules in [Self-Organization](Self-Organization).

## `stale.sh`

```sh
sh scripts/stale.sh [page…]           # default: every page under gotchas/
```

For every `` `path:line` `` citation, compares the cited file against the commit in the `verified … @ sha` stamp of its card (else of its page). Prints only what needs a look:

| Output | Meaning |
|---|---|
| `missing` | the file is gone |
| `changed` | the file changed since the fact was verified — re-check the claim |
| `unpinned` | no verified sha above the citation, so freshness is unknown |

## `publish-check.sh`

```sh
sh scripts/publish-check.sh                          # list changed / new / removed sources, hand-edited outputs
sh scripts/publish-check.sh --count                  # one number: sources behind (used by hooks)
sh scripts/publish-check.sh --record OUT REMOTE SRCS # after writing OUT
```

State lives in `gotchas/.publish-state` (committed; tab-separated `src` and `out` rows). Hashes ignore `<sub>` lines, so a `seen` bump or a re-stamp does not trigger a rebuild. `--record`'s `REMOTE` is the remote page id, or `-` for local files; `SRCS` is a comma-separated list of paths relative to `gotchas/`. Remote outputs are recorded as `<channel>:<page name>`.

| Report | Meaning |
|---|---|
| `new` | a source was never published |
| `changed` | a source changed ⇒ rebuild its outputs (listed after `→`) |
| `removed` | a source was deleted ⇒ delete its outputs (local) or report (remote) |
| `edited` | someone hand-edited a generated page ⇒ port the correction into `gotchas/` first |
| `missing` | a recorded local output is gone |
| `fresh` | nothing to do |

## `render-diagrams.sh`

```sh
sh scripts/render-diagrams.sh [--out DIR] [--png] FILE.md…
```

Renders every `` ```mermaid `` block with the official CLI; a block that fails here is a broken diagram on every channel. `--out` keeps the renders (`<file>-<n>.svg`, or `.png` with `--png`) — for Confluence/Drive attachments or to look at them. Needs Node; uses a local `mmdc`, else `npx` (network).
