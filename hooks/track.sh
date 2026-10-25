#!/usr/bin/env sh
# PostToolUse (Read|Edit|Write|MultiEdit|NotebookEdit): record what this turn
# touched so the Stop hook can tell whether the docs were consulted or updated.
# Silent, never blocks.
. "$(dirname "$0")/lib.sh"
[ -f "$GOTCHA_BASE/INDEX.md" ] || exit 0

GOTCHA_INPUT=$(cat)
tool=$(json_get tool_name)
path=$(json_get file_path)
[ -n "$path" ] || path=$(json_get notebook_path)
[ -n "$path" ] || exit 0

case "$path" in
  "$GOTCHA_BASE"/* | gotchas/*) kind=base ;;
  "$GOTCHA_PROJECT"/* | [!/]*) kind=code ;;
  *) exit 0 ;; # outside the project: plans, memory, scratch
esac

case "$tool" in
  Read) op=read ;;
  *) op=edit ;;
esac

d=$(state_dir "$(json_get session_id)")
printf '%s\t%s\t%s\n' "$op" "$kind" "$path" >>"$d/turn"
exit 0
