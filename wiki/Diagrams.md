# Diagrams

The house style for every diagram in the human docs. A diagram is worth a thousand words only when it is **right** and **readable** — a tangled one costs more than the paragraph it replaced. Everything below was tuned by rendering it.

**Format: Mermaid**, inside the markdown. It renders natively on GitHub, GitLab and Notion, diffs line by line in a PR, lays itself out, and can be pasted into draw.io (*Arrange → Insert → Advanced → Mermaid*) to be retouched. The look is draw.io's: its default palette, rounded boxes, orthogonal edges.

The canonical copy-paste blocks live in [`references/diagrams.md`](https://github.com/DamienVauchel/gotcha/blob/main/references/diagrams.md).

## When to draw

Draw whenever the shape of the thing is a graph:

| Content | Diagram |
|---|---|
| The system and its neighbours | context flowchart: the system as **one** subgraph, actors left, externals dashed |
| Areas and how they talk | component flowchart, one node per area |
| A flow across ≥ 3 components | sequence diagram, `autonumber` |
| A lifecycle / state machine | flowchart of stadium nodes coloured by outcome |
| An integration with a partner | sequence diagram, partner as a participant |
| Troubleshooting a theme | decision tree: symptom → checks (rhombus) → causes → card |
| A decision with alternatives | small flowchart, options side by side, rejected ones in red |
| Run / test / ship | flowchart only when it branches; a numbered list otherwise |

**Do not draw:** a list (use a list), a single arrow, a table in disguise, or anything the facts do not support. Every node and edge must come from a cited fact in `gotchas/`. A diagram that invents an arrow is a confident lie.

## Shapes and colours

| Meaning | Shape | Class |
|---|---|---|
| person, caller, client | `(["…"])` stadium | `actor` — purple |
| our code: service, module, job | `("…")` rounded | `service` — blue |
| database, cache, bucket | `[("…")]` cylinder | `store` — yellow |
| queue, topic, stream | `[["…"]]` | `queue` — orange |
| third party | `["…"]` + dashed | `external` — grey |
| state / outcome | `(["…"])` | `ok` green · `warn` yellow · `bad` red |
| check in a decision tree | `{"…"}` rhombus | `warn` |
| side remark | `["💬 …"]` + dotted link `-.-` | `note` |
| start / end | `(( ))` | `term` |

Group our own code in a `subgraph` named after the directory. Arrows: `-->` synchronous call or data, `-.->` asynchronous (webhook, event, message), `-.-` attaches a note.

## Layout rules (learned from renders that went wrong)

- **≤ 12 nodes per diagram.** More ⇒ an overview plus one diagram per part.
- **Labels: 1–4 words** on edges; a bold name + one `<small>` detail line in nodes. Sentences go in the caption.
- **Number the main path** (`1 · charge`, `2 · intent`) when order matters and it is not a sequence diagram.
- **One labelled edge per node pair.** Two labelled edges converging on one node overlap.
- **No labelled self-loops** — they render broken. Use a `note` node with a dotted link.
- **Fan-out of more than 3 edges: no edge labels.** Put the text inside the target nodes.
- **Branches leaving a decision carry distinct labels** (`yes` / `no`, `option A` / `option B`).
- **A context diagram shows the system as one node.** Mixing context and internals tangles the edges.
- **Flowcharts for state machines**, not `stateDiagram` (clipped labels, no colour control).
- **No self-messages in sequence diagrams** (`S->>S`): use `Note over S: …`.
- **Direction:** `LR` for flows and pipelines, `TB` for hierarchies and decision trees.
- **Emojis as icons**, one per node at most: 🛒 actor · 🌐 external · 🗄️ database · 📨 queue · ⏰ job · 🔐 auth · 💬 note.
- **A caption after every diagram:** one italic line saying what to look at.

## Sequence diagrams

`->>` call, `-->>` response, `--)` async message. Use `alt` / `opt` for the failure branch that matters — that is usually the point — and reference the decision or card id in it (`D-001`). ≤ 6 participants, ≤ 12 messages.

## Check before publishing

```sh
sh scripts/render-diagrams.sh docs/**/*.md
sh scripts/render-diagrams.sh --out /tmp/renders --png docs/architecture.md   # keep renders to look at
```

Renders every Mermaid block with the official CLI (Node; a local `mmdc`, else `npx`). **A diagram that fails to render is a broken page on every channel.** When you can view images, open a few renders: overlapping labels and edges crossing the whole canvas are bugs too.
