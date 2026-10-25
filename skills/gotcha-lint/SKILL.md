---
name: gotcha-lint
description: Audit the project memory for rot — citations pointing at code changed or deleted since the fact was verified, uncited claims, duplicated or contradictory facts, unresolved unknowns, unharvested gotcha markers, and index drift. Use when the user asks to lint, audit, verify or clean the knowledge base, after a large refactor, or before trusting the base for a risky change.
argument-hint: "[page or scope to limit the audit to]"
---

# gotcha-lint

A base nobody prunes becomes a base nobody trusts. This finds the rot. Report
first, fix only what the user confirms. Structure problems (size, index length)
belong to `/gotcha-tidy`; this skill is about **truth**.

## Checks

**1. Stale citations** — run first, it is mechanical:

```sh
sh ${CLAUDE_PLUGIN_ROOT}/scripts/stale.sh            # or: stale.sh gotchas/<page>.md
```

| Output | Verdict | Do |
|---|---|---|
| `missing` | file gone | the fact may be obsolete or moved — find where, re-verify |
| `changed` | file changed since the fact's `verified` sha | `git diff <sha> -- <path>`; does the claim still hold? Fix the line number or the claim, re-stamp |
| `unpinned` | no usable sha above the citation | verify the claim now and stamp it |

A drifted line number is a cheap fix. A changed claim needs re-verification —
never silently re-point a citation at whatever now sits on that line.

**2. Uncited claims** — an assertion about behaviour with no `path:line`, no
external source. Find its proof or mark it `_Unknown — not confirmed in code_`.

**3. Duplicates** — the same fact on two pages. Keep it where the routing table
says it belongs, replace the other with a cross-reference.

**4. Contradictions** — two pages making incompatible claims, or a page
contradicting the code. Never silently pick a side: quote both, propose which is
right and why, let the user arbitrate.

**5. Unresolved unknowns** — every `_Unknown — not confirmed in code_`, ranked
by how cheap it looks to resolve with a quick code read.

**6. Cards without a check** — a troubleshooting card with an empty or vague
**Check** line is a rumour. Sharpen it or downgrade it to `_Unknown_`.

**7. Empty scaffolding** — theme pages whose **Cards** section is still empty
months after init. Either that area never breaks (merge the Map elsewhere) or
nobody writes back for it — flag the second as a process problem.

**8. Unharvested `gotcha:` markers** — `git grep -n "gotcha:" -- . ':(exclude)gotchas'`.
Markers piling up mean the loop is not running. List them, offer `/gotcha-capture`.

**9. Index truth** — index lines whose hook no longer matches the page (a
quick TL;DR read each). `stats.sh` already covers orphans and missing pages.

**10. Human docs** — `sh ${CLAUDE_PLUGIN_ROOT}/scripts/publish-check.sh`.
`edited` outputs are corrections made by hand in the generated docs: each one
is either a fact to port into `gotchas/` (then republish) or a mistake to
revert — never let the next publish erase it unseen. `changed` / `new` ⇒ offer
`/gotcha-publish`. Run `scripts/render-diagrams.sh` on the generated pages: a
diagram that no longer renders is a broken page.

## Report

Group by check, most severe first: stale citations, contradictions, then the
rest. Per finding: page, line, what is wrong, proposed fix.

Ask what to apply. Batch the mechanical fixes (line numbers, re-stamps,
cross-references) into one change set; leave every claim that needs
re-verification as an explicit decision.

## Rules

- Never delete a fact because its citation broke. A broken citation means the
  code moved, which is exactly when the fact matters most — re-verify it.
- Re-stamp `verified` only on what you actually re-checked.
- Do not "improve" prose. Rot is the target, not style.
