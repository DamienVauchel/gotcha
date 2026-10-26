# Commands

Seven skills. Most run on their own — the commands exist for when you want to drive.

| Command | Argument | Does |
|---|---|---|
| [`/gotcha-init`](#gotcha-init) | `[subsystem or directory]` | build the memory from the code and publish the docs |
| [`/gotcha-recall`](#gotcha-recall) | `<question, symptom, error, area>` | look something up at the lowest token cost |
| [`/gotcha-investigate`](#gotcha-investigate) | `<symptom, error, entity, ticket>` | diagnose a bug against the cards first, write the card back |
| [`/gotcha-capture`](#gotcha-capture) | `[branch, path or diff range]` | write back what a task taught |
| [`/gotcha-publish`](#gotcha-publish) | `[--all or a source page]` | rebuild the human docs that are behind |
| [`/gotcha-tidy`](#gotcha-tidy) | `[page or theme]` | split · merge · archive · re-sort · re-index |
| [`/gotcha-lint`](#gotcha-lint) | `[page or scope]` | find rot |

## `/gotcha-init`

Asks the language and the publication channels (multiselect), surveys the code with one parallel agent per area, writes `gotchas/`, publishes the docs to every channel, wires `CLAUDE.md`. Re-run on an existing base ⇒ **refresh** (fills gaps, never overwrites a human-written fact) or stop. Re-run on a 0.1 base ⇒ migrates. → [Getting Started](Getting-Started)

## `/gotcha-recall`

The cheap lookup protocol: route → grep cards → TL;DR → decide whether to trust it → code only if needed. Normally triggered on its own. → [Recall and Investigation](Recall-and-Investigation)

## `/gotcha-investigate`

Bug, incident, failing integration, pasted stack trace. Cards first, evidence second, root cause with a refutation attempt, report **without applying a fix**, then a mandatory write-back. → [Recall and Investigation](Recall-and-Investigation)

## `/gotcha-capture`

Collect candidates (this task, `gotcha:` markers, the diff) → durability filter → route and dedupe → write or propose → organize → publish. Normally triggered by the Stop hook. → [Capture Contract](Capture-Contract)

## `/gotcha-publish`

Runs once per channel in `publish_targets`, `docs` first. Incremental. `--all` rebuilds everything; a source page rebuilds only its outputs. → [Publishing](Publishing)

## `/gotcha-tidy`

Reads `stats.sh`, works only the flagged pages. Structure only, never the facts. → [Self-Organization](Self-Organization)

## `/gotcha-lint`

Ten truth checks; reports first, fixes only what you confirm. → [Linting](Linting)
