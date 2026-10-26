# FAQ

## Isn't this what auto memory does?

Auto memory is a private notebook; gotcha is a team artifact.

|  | Auto memory | gotcha |
|---|---|---|
| Reach | machine-local, not synced | in the repo, cloned by everyone |
| Review | none | a pull request |
| Shape | flat prose | routed by area, theme, entity, decision |
| Provenance | asserted | `file:line` cited, pinned to a sha, lint-checked |
| Reader | the agent | the agent, the new hire, and the human debugging at 3am |

They compose: auto memory keeps your preferences and this session's context; gotcha keeps what a teammate would need. *If losing it would cost someone else an afternoon, it belongs in the repo.*

## How does it relate to spec-driven tools (OpenSpec, spec-kit…)?

Spec-driven tools are **prospective** — the spec before the code. gotcha is **retrospective** — what the code and its incidents taught. Run both: one tells the agent what to build, the other what is already there.

## Why no vector store?

Because the base is meant to be read by humans, reviewed in PRs, and grepped. Cards carry the literal strings people paste; a `grep` on 2–5 words lands on a 15-line card. Embeddings would add a server, an index to keep fresh, and opaque retrieval, for a corpus that is deliberately small.

## What if the agent writes something wrong?

Three safeguards: every fact must cite `file:line` (no citation, no entry); every write lands in the working tree so **a human reviews it in the PR**; and [`/gotcha-lint`](Linting) plus `stale.sh` find facts whose cited code has changed since they were verified. For extra caution set `autocapture: propose`.

## Will it bloat my repo and my context?

No — that is the central design constraint. The index is capped at 60 lines and injected every session; pages cap at 300 lines; troubleshooting themes at 15 cards; cold cards go to an unindexed archive. Capture is filtered by the [durability test](Capture-Contract#the-durability-test), and discarding everything is the *normal* outcome of a small task.

## Why is `gotchas/` in English if my docs are in French?

The source base is grepped against code identifiers and log strings, which are English in most repos. The **human docs** are translated at publication (`publish_language`), with identifiers, paths, commands and log strings kept verbatim.

## Can I publish to several places at once?

Yes — `publish_targets` is a list. See [Publishing Channels](Publishing-Channels).

## Someone edited a generated page by hand. Is it lost?

No. `publish-check.sh` reports it as `edited`; the correction is ported into `gotchas/` (as a cited capture), then the page is rebuilt. Generated pages say so in their header.

## Why publish remote channels only after merge?

Publishing from a feature branch puts unreviewed facts in front of the whole company. Remote channels are always manual and from the default branch.

## Does it work in a monorepo?

One base per bounded context (`apps/billing/gotchas/`), chosen at init. Note that the hooks currently look for `gotchas/` at the project root only.

## I do not want a Stop-hook nudge

`autocapture: off` in the manifest (or `GOTCHA_AUTOCAPTURE=off` for one session). Explicit `/gotcha-capture` still works. To stop the publish nudge only: `publish_when: manual`.

## Why are there dates in the pages?

Only two kinds, both useful: `verified <date> @ <sha>` (the sha lets `stale.sh` tell without reading code whether a fact may have rotted) and `seen N · last <date>` on cards (the self-organization signal). Everything else — "added on…", changelogs — is noise; git holds the story.

## Prior art?

Reflexion, Voyager, ExpeL, MemGPT/Letta, Generative Agents — and services like Mem0, Letta and Zep. gotcha's bet is different: **the store is your repo**, and a human reviews every fact the agent decided to remember before it becomes doctrine.
