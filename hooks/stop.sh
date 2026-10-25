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

# Already continuing because of this hook: let the turn end.
printf '%s' "$GOTCHA_INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && finish
[ -f "$turn" ] || exit 0

mode="${GOTCHA_AUTOCAPTURE:-$(manifest_get autocapture auto)}"
[ "$mode" = off ] && finish

grep -q "^edit	base	" "$turn" && finish

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

root="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
reason="gotcha write-back: this turn $why and wrote nothing to gotchas/. Apply the gotcha-capture skill to what THIS turn taught you that the docs did not already hold (durability test in $root/references/capture-contract.md). $act If nothing passes, reply with exactly 'gotcha: nothing durable' and stop. Do not restate your previous answer."

rm -f "$turn"
if command -v jq >/dev/null 2>&1; then
  jq -n --arg r "$reason" '{decision: "block", reason: $r}'
else
  printf '{"decision":"block","reason":"%s"}\n' "$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')"
fi
exit 0
