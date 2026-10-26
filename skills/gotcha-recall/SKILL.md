---
name: gotcha-recall
description: Look something up in the project memory (gotchas/) at the lowest token cost before touching the code — grep-first on troubleshooting cards, TL;DR before body, and an explicit rule for when to distrust the docs and read the code. Use at the start of any task in a repo that has gotchas/INDEX.md, whenever you need to know how something works, where to change it, why it is the way it is, or what an error means.
argument-hint: "<question, symptom, error string, or area>"
---

# gotcha-recall

The base is worth something only if consulting it is cheaper than re-reading the
code. This is the procedure that keeps it cheap. The index (L0) is already in
context from the session-start hook.

## 1. Route

From the question, pick at most **two** pages in the L0 index. The index lines
say when to open each page — trust them.

- A pasted error, log line, exception name or symptom ⇒ go to step 2 first.
- A "how / where / why" question ⇒ step 3.
- Nothing in the index fits ⇒ step 5, and the answer is a capture candidate.

## 2. Grep the cards

Cards carry the literal strings people paste in their `keywords` line.

```sh
grep -rniF -e "<distinctive fragment>" gotchas/troubleshooting gotchas/decisions.md
```

Use the most distinctive 2–5 words of the error, not the whole message (ids,
timestamps and values never match). One hit ⇒ read **only that card**: `Read`
with `offset` at the hit line and `limit: 15`. No hit ⇒ the theme's row in
`troubleshooting/INDEX.md`, then the theme's **Map** section only.

Also try `gotchas/troubleshooting/_archive.md` before concluding there is no card.

## 3. TL;DR before body

`Read` the page with `limit: 12`: title, TL;DR, stamp. Often that is the answer.
Otherwise open the one section that answers (`grep -n "^## " <page>` gives the
offsets). Never read a whole base page "for context".

## 4. Decide whether to trust it

Read the code anyway when **any** of these holds:

- **The docs are silent** on the point you need.
- **You are about to change code on the strength of a cited fact.** Spot-check
  the cited line — one `Read` with offset, a few lines. Cheap insurance.
- **The page may be stale.** For the cited files you rely on:
  `sh ${CLAUDE_PLUGIN_ROOT}/scripts/stale.sh <page>` lists those that changed
  since the page (or card) was verified. A `changed` file means re-check that
  claim against the code before using it.
- **Two pages disagree**, or the page contradicts what you see in the code.
  The code wins; the doc gets fixed in the write-back.
- The fact is marked `_Unknown — not confirmed in code_`. Resolving it is a
  capture.

Otherwise trust the doc and move on — re-deriving what the base already holds is
exactly the cost it exists to remove.

## 5. Go to the code — and keep the receipt

When you do read the code, note for the write-back:

- what the docs **lacked** (the answer you had to dig for),
- what the docs got **wrong** (fix it, cite the proof),
- which card **answered** a symptom (bump its `seen` / `last`).

These three notes are what the Stop hook's write-back step will ask for. Keep
them in mind; do not write them yet unless the task is done.

## Budget

A recall that reads more than three base pages or more than ~150 lines of them
has gone wrong: either the index hooks are bad (fix them in the write-back) or
the question belongs to the code. Stop and read the code.
