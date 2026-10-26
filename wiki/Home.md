# gotcha

**The project memory your codebase earned** — written by the agent, reviewed in PR, published as docs people actually read.

gotcha is a [Claude Code](https://claude.com/claude-code) plugin. It gives a repository a memory that maintains itself: the agent reads it before every task, writes back what the task taught, and the human docs follow.

```mermaid
%%{init: {"theme":"base","fontFamily":"Inter, Helvetica, Arial, sans-serif","themeVariables":{"fontFamily":"Inter, Helvetica, Arial, sans-serif","fontSize":"14px","lineColor":"#6b7280","primaryColor":"#dae8fc","primaryBorderColor":"#6c8ebf","primaryTextColor":"#1f2937","clusterBkg":"#f8fafc","clusterBorder":"#cbd5e1","edgeLabelBackground":"#ffffff"},"flowchart":{"curve":"step","padding":18,"nodeSpacing":45,"rankSpacing":70,"htmlLabels":true}}}%%
flowchart LR
  classDef actor fill:#e1d5e7,stroke:#9673a6,stroke-width:1.5px,color:#1f2937
  classDef service fill:#dae8fc,stroke:#6c8ebf,stroke-width:1.5px,color:#1f2937
  classDef store fill:#fff2cc,stroke:#d6b656,stroke-width:1.5px,color:#1f2937
  classDef external fill:#f5f5f5,stroke:#666666,stroke-width:1.5px,stroke-dasharray:5 4,color:#1f2937

  task(["🧑‍💻 any task"]):::actor
  mem[("<b>gotchas/</b><br/><small>memory · for the agent</small>")]:::store
  agent("<b>Claude</b><br/><small>recall · act · write back</small>"):::service
  docs[("<b>docs/</b><br/><small>for people</small>")]:::store
  remote["🌐 PDF · Drive · Notion<br/>Confluence · Wiki"]:::external

  task --> agent
  mem -->|read first| agent
  agent -->|write back| mem
  mem -->|/gotcha-publish| docs
  mem -.-> remote
```

*Two layers, one source of truth: the memory is written for the agent, the docs are generated for people.*

## Start here

| I want to… | Read |
|---|---|
| install it and run it once | [Getting Started](Getting-Started) |
| understand the loop and the hooks | [How It Works](How-It-Works) |
| know what files get written | [Memory Layout](Memory-Layout) |
| see what a page and a card look like | [Page Format](Page-Format) |
| know what is worth writing down | [Capture Contract](Capture-Contract) |
| publish to Notion, Confluence, Drive, a PDF… | [Publishing](Publishing) and [Publishing Channels](Publishing-Channels) |
| change a setting | [Configuration](Configuration) |
| use a command | [Commands](Commands) |
| keep the base small and true | [Self-Organization](Self-Organization) and [Linting](Linting) |
| draw diagrams in the house style | [Diagrams](Diagrams) |
| run the helper scripts | [Scripts](Scripts) |
| answer "why not just…?" | [FAQ](FAQ) |
| upgrade | [Upgrading](Upgrading) |
| contribute | [Contributing](Contributing) |

## The ideas in one minute

- **Plain markdown in git.** No server, no embeddings. Reviewed in a PR like any change.
- **Cheap to read.** Index → TL;DR → one card. The code is the last resort.
- **Cited and pinned.** Every fact carries `path/to/file.ext:line`, and every page a `verified <date> @ <sha>` stamp, so rot is measurable.
- **Self-feeding.** A Stop hook asks every turn that learned something what it learned.
- **Self-organizing.** Themes split, merge and archive around the problems people actually hit.
- **Published, not duplicated.** Human docs are generated from the memory, on every channel you pick.

See the [payments-gateway example](https://github.com/DamienVauchel/gotcha/tree/main/examples/payments-gateway) for both layers filled in.
