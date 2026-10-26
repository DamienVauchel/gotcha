#!/usr/bin/env sh
# Stop: the write-back gate. If this turn changed code or had to explore it, and
# wrote nothing to gotchas/, send Claude back once to apply the capture contract.
# One nudge per turn at most; a turn that wrote to the base passes untouched.
. "$(dirname "$0")/lib.sh"
[ -f "$GOTCHA_BASE/INDEX.md" ] || exit 0

GOTCHA_INPUT=$(cat)
d=$(state_dir "$(json_get session_id)")
turn="$d/turn"

finish() { rm -f "$turn"; exit 0; }
block() {
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg r "$1" '{decision: "block", reason: $r}'
  else
    printf '{"decision":"block","reason":"%s"}\n' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
  fi
  exit 0
}

# Already continuing because of this hook: let the turn end.
printf '%s' "$GOTCHA_INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && finish
[ -f "$turn" ] || exit 0

# The turn wrote to the base. With on-change publishing, make the human docs follow.
if grep -q "^edit	base	" "$turn"; then
  targets=$(manifest_get publish_targets docs)
  when=$(manifest_get publish_when on-change)
  behind=$(publish_behind)
  # on-change only drives the local docs/ channel; remote channels stay manual.
  if [ "$when" = on-change ] && [ "${behind:-0}" -gt 0 ] && case ",$targets," in *,docs,*) true ;; *) false ;; esac; then
    rm -f "$turn"
    block "gotcha publish: this turn changed gotchas/ and $behind source page(s) are now ahead of the human docs. Run the gotcha-publish skill for the changed pages only, then report in one line."
  fi
  finish
fi

mode="${GOTCHA_AUTOCAPTURE:-$(manifest_get autocapture auto)}"
[ "$mode" = off ] && finish

edits=$(grep -c "^edit	code	" "$turn" || true)
reads=$(grep "^read	code	" "$turn" | cut -f3 | sort -u | wc -l | tr -d ' ')
min_edits=$(manifest_get nudge_min_edits 1)
min_reads=$(manifest_get nudge_min_reads 6)

why=""
[ "$edits" -ge "$min_edits" ] && why="edited $edits code file(s)"
if [ "$reads" -ge "$min_reads" ]; then
  [ -n "$why" ] && why="$why and "
  why="${why}read $reads code files to work it out"
fi
[ -n "$why" ] || finish

if [ "$mode" = propose ]; then
  act="List each candidate finding with its destination page and ask the user before writing."
else
  act="Write the findings that pass into gotchas/ now, then report them in one line."
fi

reason="gotcha write-back: this turn $why and wrote nothing to gotchas/. Apply the gotcha-capture skill to what THIS turn taught you that the docs did not already hold (durability test in $GOTCHA_ROOT/references/capture-contract.md). $act If nothing passes, reply with exactly 'gotcha: nothing durable' and stop. Do not restate your previous answer."

rm -f "$turn"
block "$reason"
