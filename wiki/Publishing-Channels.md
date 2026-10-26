# Publishing Channels

`/gotcha-init` asks the channels as a **multiselect**: tick any combination. Each channel is independent — its own location, its own rows in `.publish-state`, its own failure mode.

```yaml
# gotchas/manifest.yml
publish_targets: docs,notion,confluence
publish_location_notion: https://www.notion.so/acme/Engineering-Docs-…
publish_location_confluence: ENG / Platform / Payments
```

## At a glance

| Channel | Output | Remote id | Diagrams | Needs |
|---|---|---|---|---|
| `docs` | markdown under `publish_dir` | — | Mermaid (renders on GitHub/GitLab) | nothing |
| `pdf` | `<publish_dir>/pdf/<project>.pdf` | — | rendered SVG | a markdown-to-PDF tool; `docs` channel |
| `artifact` | private Claude artifact page(s) | artifact URL | Mermaid via the page | Claude Code |
| `claude-docs` | Claude Docs documents | doc id | diagram blocks, else Mermaid code | Claude Docs connector |
| `drive` | Google Docs in `publish_location_drive` | file id | rendered PNG/SVG | Google Drive connector |
| `notion` | one page per output under `publish_location_notion` | page id | `mermaid` code blocks (Notion renders them) | Notion connector |
| `confluence` | one page per output under `publish_location_confluence` | page id | SVG attachments, or a Mermaid macro | Atlassian connector |
| `github-wiki` | pages pushed to `<repo>.wiki.git` | page name | Mermaid (GitHub renders it) | push access to the wiki repo |
| `other:<tool>` | Outline, GitBook, Coda… | page id | Mermaid if rendered, else SVG/PNG | a connector |
| `none` | nothing | | | |

## Per-channel notes

### `docs` *(default)*

Markdown committed with the change and **reviewed in the same PR as the source**. Renders on GitHub / GitLab as-is, diagrams included. Works with MkDocs (`pymdownx.superfences` mermaid) or Docusaurus (`@docusaurus/theme-mermaid`) if you want a site. Output folder: `publish_dir` (default `docs`).

### `pdf`

One bundle built from the generated `docs` pages — home first, then the page-map order — with whatever markdown-to-PDF tool is installed (pandoc, mdbook, a headless browser). Diagrams are SVGs from `render-diagrams.sh --out`. Rebuilt whenever any `docs` page is. Gitignore it unless the team wants it committed.

### `artifact`

One private Artifact per output (or one multi-section page for a small base). **Private until you share it.** The artifact URL is the remote id, so republishing updates in place.

### `claude-docs`

One Claude Docs document per output through the connector. Updated in place by id.

### `drive`

Google Docs in the folder named by `publish_location_drive`. Diagrams go in as rendered images (Docs does not render Mermaid).

### `notion`

One Notion page per output under `publish_location_notion`, same hierarchy as `docs/`. Mermaid goes in `mermaid` code blocks. GitHub alerts become callouts.

### `confluence`

One page per output under `publish_location_confluence`. Confluence does not render Mermaid natively: diagrams are rendered to SVG (`render-diagrams.sh --out <dir>`) and **attached** when the tool can upload attachments; otherwise a `mermaid` code block is used if your instance has a Mermaid macro, and the run says which. GitHub alerts become info / warning / note panels.

### `github-wiki`

Markdown pages pushed to `<repo>.wiki.git`; GitHub renders Mermaid. Page names mirror the page map. Pushing is outward-facing, so only from the default branch, after merge. (The wiki you are reading is maintained as plain files in the repo's [`wiki/`](https://github.com/DamienVauchel/gotcha/tree/main/wiki) folder and synced to the wiki repo.)

### `other:<tool>`

Any document tool reachable through a connector (Google Docs, Outline, GitBook, Coda…). Same rules: one remote page per output, update in place by the id in `.publish-state`, Mermaid if the tool renders it, else rendered SVG / PNG.

## Rules for every remote channel

- **Publish from the default branch, after the PR is merged.** Publishing from a feature branch puts unreviewed facts in front of the whole company. On another branch: warn and ask.
- **Update pages in place.** Never delete a remote page without asking.
- **No connector available ⇒ say so**, explain how to add it, skip that channel for this run and make sure `docs` is published.

## Adding or removing a channel later

1. Edit `publish_targets` (and `publish_location_<channel>`) in `manifest.yml`.
2. Run `/gotcha-publish`. A channel with no rows in `.publish-state` is published in full; the other channels are untouched.
3. Removing a channel only stops future publishes — nothing remote is deleted.
