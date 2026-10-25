#!/usr/bin/env sh
# Shared helpers for gotcha hooks. POSIX sh; jq is used when present, never required.

GOTCHA_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
GOTCHA_PROJECT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
GOTCHA_BASE="$GOTCHA_PROJECT/gotchas"
GOTCHA_MANIFEST="$GOTCHA_BASE/manifest.yml"

# json_get <key> — first string value for <key> in the JSON on $GOTCHA_INPUT.
# The first match is the right one: tool_input precedes tool_response in hook
# payloads, and file contents inside tool_response are escaped.
json_get() {
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$GOTCHA_INPUT" | jq -r --arg k "$1" '
      (.. | objects | select(has($k)) | .[$k] | select(type == "string")) // empty' 2>/dev/null | head -n 1
  else
    printf '%s' "$GOTCHA_INPUT" | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -n 1 |
      sed 's/.*:[[:space:]]*"\(.*\)"$/\1/'
  fi
}

# manifest_get <key> <default> — flat top-level scalar from manifest.yml.
manifest_get() {
  v=""
  [ -f "$GOTCHA_MANIFEST" ] &&
    v=$(sed -n "s/^$1:[[:space:]]*\([^#]*\).*/\1/p" "$GOTCHA_MANIFEST" | head -n 1 | tr -d " \"'")
  printf '%s' "${v:-$2}"
}

# state_dir <session_id> — per-session scratch, created on demand.
state_dir() {
  d="${TMPDIR:-/tmp}/gotcha-$(id -u)/${1:-nosession}"
  mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}

# publish_behind — number of source pages changed since the human docs were
# last published; empty when publishing is off.
publish_behind() {
  [ "$(manifest_get publish_target docs)" = none ] && return 0
  (cd "$GOTCHA_PROJECT" && sh "$GOTCHA_ROOT/scripts/publish-check.sh" --count 2>/dev/null) || true
}
