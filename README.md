# gotcha

**The gotchas your codebase earned — in git, reviewed in PR, shared by the team.**

Every codebase has facts that cost someone an afternoon and live nowhere: the
exception that gets swallowed, the partner that returns 200 on refusal, the
timeout that was chosen over a retry for a reason nobody wrote down. Agents
re-derive them every session. So do new hires.

gotcha puts them in your repo as markdown: read before the work starts, written
back when it ends. Greppable, diffable, reviewed in a pull request like any other
change. No server, no embeddings, no vector store.

The point is not that your agent remembers. It is that **your team** remembers,
and that a human approved every fact before it became doctrine.

```
/gotcha-init          scaffold the base from the code
/gotcha-investigate   local knowledge first, diagnose, write back
/gotcha-capture       harvest what building it taught you
/gotcha-lint          find the rot before you stop trusting the base
```

## Install

```
/plugin marketplace add DamienVauchel/gotcha
/plugin install gotcha
```

Then, in your repo:

```
/gotcha-init
```

See [`examples/payments-gateway/`](examples/payments-gateway/) for a filled-in
base — synthetic, but written the way a real one looks after a few incidents.

## How it works

`/gotcha-init` scans the subject you point it at and generates `gotchas/`:

```
gotchas/
  manifest.yml        the only repo-specific file — scopes, paths, routing, repro commands
  INDEX.md            one line per page; injected into every session by a hook
  failure-modes.md    exceptions, silent-failure traps, log patterns, repair handles, per scope
  entities/<name>.md  one page per partner / provider / tenant / plugin
```

It pre-fills what the code proves — every custom exception with its throw
condition, every `catch` that swallows, every entry point, every repair command
— and leaves the symptom tables **empty on purpose**. Those fill from real
incidents. Invented rows poison the base.

`/gotcha-investigate <symptom>` then runs a fixed loop:

1. classify into a scope, read the matching pages
2. gather evidence — exact error, logs, state, reproduction
3. trace the path, noting what is validated, swallowed, retried, logged
4. state the root cause, then **try to refute it**
5. report symptom → evidence → root cause → blast radius → fix → repair path
6. **write every durable finding back**, routed by the manifest, cited by `file:line`

Step 6 is the product. Everything else is a good investigation protocol; the
write-back is what makes the second occurrence cheap. It is a mandatory phase,
not a suggestion — including for anything learned from a web search, so the next
investigation does not need that search.

### Building teaches more than debugging

Debugging is the loudest source of knowledge, not the biggest. The partner that
signals refusal with HTTP 200, the timeout chosen over a retry to avoid a double
charge, the error you decided to swallow — you learn all of that while building,
and an investigation report is not there to catch it. Debugging ends in a
report; building ends in a merge, and what the integration taught you evaporates.

So drop a marker where you learn it:

```ts
// gotcha: Adyen signals refusal in resultCode, HTTP is 200 either way
```

`/gotcha-capture` then harvests the markers, scans the diff for what you did *not*
note — new swallowed errors, unexplained constants, workarounds shaped "the
remote does X so we must Y" — routes each finding, and deletes the marker. One
line where you learn it, no interruption; the routing happens later.

Both paths share one [capture contract](references/capture-contract.md): the same
durability test, the same routing table, the same writing rules. Duplicating that
contract per skill would let the two halves drift, which is precisely what
`/gotcha-lint` exists to catch.

`/gotcha-lint` audits the base: citations pointing at moved code, uncited claims,
duplicated facts, pages that contradict each other, unresolved unknowns, index
drift, and `gotcha:` markers nobody harvested. Without it the base rots quietly and
then nobody trusts it.

## Design rules

- **Every fact cites `file:line`.** No citation, no entry — and no way to lint
  it later.
- **Gaps are marked, never filled with guesses.** `_Unknown — not confirmed in
  code_` is a valid, useful entry.
- **Deliberate trade-offs are recorded as deliberate**, with the reason.
  Otherwise the next person "fixes" them and reintroduces what they solved.
- **Facts, not narratives.** No ticket numbers, dates, or who did what — git
  already holds the story. The base holds the reusable part.
- **Symptom rows need a check column.** Symptom → cause without "how to
  verify" is a rumour.

## Isn't this what auto memory does?

Claude Code writes its own notes now, debugging insights included. That covers a
different problem. Auto memory is a private notebook; gotcha is a team artifact.

|  | auto memory | gotcha |
|---|---|---|
| Reach | machine-local, not synced | in the repo, cloned by everyone |
| Review | none | a pull request |
| Shape | flat prose | routed per scope, entity, standard |
| Provenance | asserted | `file:line` cited, so it can be lint-checked |
| Scope | anything | gotchas, trade-offs, repair handles |
| Reader | the agent | the agent, and the human debugging at 3am |

The two compose. Let auto memory keep your preferences and this session's
context; put in gotcha the facts a teammate would need at 3am. The dividing line
is simple: if losing it would cost someone else an afternoon, it belongs in the
repo, not in a notebook on your laptop.

## Relation to spec-driven tools

Complementary, opposite direction:

|  | Direction | Artifact |
|---|---|---|
| Spec-driven (OpenSpec, spec-kit, …) | **prospective** — the spec before the code, the agent executes it | change proposals |
| gotcha | **retrospective** — the fact after the debug, the agent accumulates it | knowledge base |

Run both. One tells the agent what to build, the other what already bit you.

## Prior art

Not a new idea, a packaged one. The write-back loop appears as
Reflexion (verbal lessons into episodic memory), Voyager (a skill library the
agent grows on disk), ExpeL (insights extracted from trajectories), MemGPT/Letta
(self-editing memory blocks), and Generative Agents (reflection over a memory
stream). Mem0, Letta and Zep ship it as a service.

gotcha's bet is different: the store is your repo. Which means a human reviews
every fact the agent decided to remember, in a PR, before it becomes doctrine.

## License

MIT
