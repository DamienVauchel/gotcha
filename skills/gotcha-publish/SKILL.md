---
name: gotcha-publish
description: Rebuild the human-friendly docs from the project memory — narrative markdown with diagrams, translated to the configured language, written to docs/ by default or published to any mix of channels (PDF, Claude artifact, Claude Docs, Drive, Notion, Confluence, GitHub wiki, …). Incremental, only pages whose source changed. Use when the gotcha Stop or session-start hook says the human docs are behind, after /gotcha-init, or when the user asks to publish, regenerate, translate or sync the docs.
argument-hint: "[--all to rebuild everything | a source page to rebuild]"
---

# gotcha-publish

`gotchas/` is written for the agent. This turns it into docs people want to
read — explained in order, in their language, with a diagram wherever the shape
of the thing is a graph. One-way: the human docs are a **view**, never a second
source.

Authorities — read them, this skill is only the procedure:

- `${CLAUDE_PLUGIN_ROOT}/references/publishing.md` — targets, page map, ownership, freshness
- `${CLAUDE_PLUGIN_ROOT}/references/diagrams.md` — when to draw, the house style, copy-paste blocks

Settings come from `gotchas/manifest.yml`: `publish_targets` (a comma-separated
list of channels), `publish_language`, `publish_dir`, `publish_location_<channel>`,
`publish_when`. Missing ⇒ `docs`, `en`, `docs`. `publish_targets: none` ⇒ say so
and stop. Every step below runs **once per channel**, in the order listed, `docs`
first (the other channels reuse its pages).

## 1. What changed

```sh
sh ${CLAUDE_PLUGIN_ROOT}/scripts/publish-check.sh
```

- `fresh` ⇒ say so and stop.
- `edited <output>` ⇒ someone corrected a generated page by hand. Diff it against
  what the source says, port the correction **into `gotchas/`** (it is a capture:
  cite it), then rebuild. Never overwrite a hand edit silently.
- `changed` / `new` / `removed` ⇒ the outputs to rebuild, create or delete.
- `--all` or no `.publish-state` yet ⇒ every output in the page map.
- A channel with no `out` row in `.publish-state` (newly added to the manifest)
  ⇒ every output, for that channel only.

## 2. Check the target

- `docs`, `pdf` ⇒ nothing to check (`pdf` needs a markdown-to-PDF tool; none ⇒ say so, skip it).
- `artifact` ⇒ the Artifact tool. Pages are private until the user shares them.
- Remote (`claude-docs`, `drive`, `notion`, `confluence`, `github-wiki`,
  `other:<tool>`) ⇒ a matching connector / MCP tool (or, for the wiki, push access
  to `<repo>.wiki.git`) must be available in this session. Not there ⇒ tell the
  user which connector to add, skip that channel for this run, and make sure
  `docs` was published. On a branch other than the default
  one ⇒ warn that unreviewed facts would go public, and ask.

## 3. Generate

**Few outputs (≤ 2)** ⇒ write them inline.
**More** ⇒ delegate to `gotcha-publisher` agents — one per group of related
outputs, launched in the same message so they run in parallel. Give each: the
outputs to write, their source pages, the language, the target and location,
the plugin root. Each returns one line per page written. This keeps the source
pages and the diagram drafting out of your context.

The writing rules, inline or delegated, are in `publishing.md` and `diagrams.md`.
The ones most often broken:

- **Every fact comes from the source.** Publishing never adds knowledge.
- **Draw by default** wherever the content is a flow, a lifecycle, a map, an
  integration or a diagnosis. Follow the house style exactly — it is what makes
  the diagrams look like draw.io instead of a default render.
- **Narrate.** A human page reads top to bottom: what it is, why it matters, how
  it works (diagram), what to watch out for (callouts), where to go next.
- **Translate** prose and diagram labels to `publish_language`. Identifiers,
  paths, commands, log strings and error messages stay verbatim.
- **The generated header** on every page, listing its sources.

## 4. Verify

```sh
sh ${CLAUDE_PLUGIN_ROOT}/scripts/render-diagrams.sh <every page written>
```

A failing diagram is fixed before anything is recorded. If you can view images,
render with `--out <scratch dir> --png` and look at the main diagrams: labels
overlapping, edges crossing the whole canvas, more than ~12 nodes ⇒ redraw.

Links between generated pages resolve. Pages for removed sources are deleted
(local) or reported (remote — never delete a remote page without asking).

## 5. Record

For each output written, on each channel (the output name is the file path for
`docs`/`pdf`, `<channel>:<page name>` for the others):

```sh
sh ${CLAUDE_PLUGIN_ROOT}/scripts/publish-check.sh --record <output> <remote-id|-> <source,source>
```

Then `publish-check.sh` again must print `fresh`. Report in one line:
`published: <n> pages → <channels> (<language>)`, plus the remote links if any.
