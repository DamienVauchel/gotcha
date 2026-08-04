---
name: gotcha-lint
description: Audit the gotcha knowledge base for rot — citations pointing at moved or deleted code, duplicated facts, uncited claims, unresolved unknowns, and an index out of sync with the pages. Use when the user asks to lint, audit, or clean the knowledge base, or on a schedule after a large refactor.
argument-hint: "[page or scope to limit the audit to]"
---

# gotcha-lint

A knowledge base nobody prunes becomes a knowledge base nobody trusts. This
finds the rot. Report first, fix only what the user confirms.

Read `gotchas/manifest.yml`, then every page it declares (or just the
argument's scope).

## Checks

**1. Stale citations** — the expensive one, run it first. For every
`path/to/file.ext:line` in the base: does the file exist? Does the cited line
still contain the symbol or construct the claim is about? Classify:

| Result | Verdict |
|---|---|
| File gone | **stale** — the fact may be obsolete or may have moved |
| File there, cited construct elsewhere in it | **drifted** — fix the line number |
| File there, construct gone | **stale** — re-verify the claim, do not just re-point it |
| File and construct match | ok |

A drifted line number is a cheap fix. A stale claim needs re-verification
against the current code — never silently re-point a citation at whatever now
sits on that line.

**2. Uncited claims** — any assertion about behaviour with no `file:line` and
no external source. Either find its proof or mark it
`_Unknown — not confirmed in code_`.

**3. Duplicates** — the same fact on two pages. Keep it where the routing
table says it belongs, replace the other with a cross-reference. Duplicated
facts drift apart, and then two pages disagree.

**4. Contradictions** — two pages making incompatible claims about the same
behaviour. Never silently pick a side: quote both, name both files, propose
which is right and why, let the user arbitrate. Then fix the loser.

**5. Unresolved unknowns** — every `_Unknown — not confirmed in code_`. Many
are cheap to close now with a quick code read. List them ranked by how easy
they look to resolve.

**6. Index sync** — pages present but not in `INDEX.md`, entries in `INDEX.md`
with no page, and index lines whose description no longer matches the page.

**7. Empty scaffolding** — scope sections still holding only their template
header rows, months after `/gotcha-init`. Either the scope never breaks (drop
the section) or nobody captures for it (the write-back loop is not running —
worth flagging as a process problem, not a doc problem).

**8. Unharvested `gotcha:` markers** — `grep -rn "gotcha:"` over the subject. Each
marker is a **pending** capture, not documentation; it stays in the code only
until `/gotcha-capture` routes it. Markers piling up mean the loop is not running,
which is worse than a stale page: the knowledge is still in someone's head and
nobody knows it is missing. List them and offer to run `/gotcha-capture`.

## Report

Group by check, most severe first: stale citations, then contradictions, then
the rest. Per finding: page, line, what is wrong, proposed fix.

Then ask what to apply. Batch the mechanical fixes (drifted line numbers,
index sync, duplicate removal) into one change set; leave every stale claim
that needs re-verification as an explicit decision for the user.

## Rules

- Never delete a fact because its citation broke. A broken citation means the
  code moved, which is exactly when the fact matters most — re-verify it.
- Do not "improve" prose. Rot is the target, not style.
