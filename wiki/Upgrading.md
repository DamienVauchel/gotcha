# Upgrading

## From an early 0.3 build — `publish_target` → `publish_targets`

Publishing now supports several channels at once. In `gotchas/manifest.yml`:

```yaml
# before
publish_target: confluence
publish_location: ENG / Platform

# after
publish_targets: docs,confluence
publish_location_confluence: ENG / Platform
```

- The value becomes a comma-separated list (no spaces).
- `publish_location` becomes `publish_location_<channel>`, one per remote channel.
- Add `docs` if you still want the repository copy: the Stop hook's automatic publish only drives the `docs` channel.
- Then run `/gotcha-publish`. `.publish-state` rows written by the old single-target flow stay valid for their outputs.

## From 0.1 — `failure-modes.md`

Run `/gotcha-init` again. It detects `failure-modes.md`, turns each scope section into `troubleshooting/<scope>.md` (tables → **Map**, symptom rows → `TS-NNN` cards with `seen 1`), then surveys for the new page kinds (modules, entities, decisions, standards).

Also: the hook moved from `plugin.json` to `hooks/hooks.json`.

## Re-running init on a current base

`/gotcha-init` on a repo that already has `gotchas/manifest.yml` offers **refresh** (re-survey and fill gaps — never overwriting a human-written fact) or stop. Use it to pick up new areas, or to add a channel (you can also just edit `publish_targets` and run `/gotcha-publish`).
