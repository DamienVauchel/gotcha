# Linting

A base nobody prunes becomes a base nobody trusts. `/gotcha-lint [page|scope]` finds the **rot**. It reports first and fixes only what you confirm. (Structure problems — size, index length — belong to [`/gotcha-tidy`](Self-Organization); lint is about **truth**.)

## The ten checks

| # | Check | How |
|---|---|---|
| 1 | **Stale citations** | `stale.sh` — mechanical, run first |
| 2 | **Uncited claims** | an assertion about behaviour with no `path:line` and no source ⇒ find its proof or mark `_Unknown — not confirmed in code_` |
| 3 | **Duplicates** | the same fact on two pages ⇒ keep it where routing says, cross-reference the other |
| 4 | **Contradictions** | two pages incompatible, or a page contradicting the code ⇒ quote both, propose which is right, **you arbitrate** |
| 5 | **Unresolved unknowns** | every `_Unknown_`, ranked by how cheap it looks to resolve |
| 6 | **Cards without a check** | an empty or vague **Check** is a rumour — sharpen it or downgrade it |
| 7 | **Empty scaffolding** | theme **Cards** still empty months after init — the area never breaks, or nobody writes back (a process problem) |
| 8 | **Unharvested markers** | `git grep -n "gotcha:"` — piling up means the loop is not running |
| 9 | **Index truth** | hook lines whose page no longer matches |
| 10 | **Human docs** | `publish-check.sh` (`edited` outputs are hand corrections to port or revert; `changed`/`new` ⇒ offer a publish) and `render-diagrams.sh` on the generated pages |

## Stale citations

```sh
sh scripts/stale.sh                  # every page
sh scripts/stale.sh gotchas/modules/charge.md
```

| Output | Meaning | Do |
|---|---|---|
| `missing` | the cited file is gone | the fact may be obsolete or moved — find where, re-verify |
| `changed` | the file changed since the fact's `verified` sha | `git diff <sha> -- <path>`: does the claim still hold? Fix the line or the claim, re-stamp |
| `unpinned` | no usable sha above the citation | verify the claim now and stamp it |

## Rules

- **Never delete a fact because its citation broke.** A broken citation means the code moved — exactly when the fact matters most. Re-verify it.
- A drifted line number is a cheap fix. A changed claim needs re-verification: **never silently re-point a citation** at whatever now sits on that line.
- Re-stamp `verified` only on what you actually re-checked.
- Do not "improve" prose. Rot is the target, not style.

The report is grouped by check, most severe first (stale citations, contradictions, then the rest). Mechanical fixes — line numbers, re-stamps, cross-references — are batched into one change set; every claim needing re-verification stays an explicit decision.

## When to run it

After a large refactor, before trusting the base for a risky change, or when `stats.sh` reports unharvested markers.
