#!/usr/bin/env sh
# Smoke test for the hooks: runs them against a throwaway project and checks
# what they print. Run from anywhere: sh tests/hooks.sh
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
proj="$tmp/proj"
mkdir -p "$proj/gotchas" "$proj/src"
printf '# Index\n- [Overview](overview.md) - start here\n' >"$proj/gotchas/INDEX.md"
printf 'language: en\npublish_targets: docs,notion\npublish_when: manual\nautocapture: auto\n' >"$proj/gotchas/manifest.yml"

export CLAUDE_PROJECT_DIR="$proj" CLAUDE_PLUGIN_ROOT="$root" TMPDIR="$tmp"
fail=0
check() { # check <name> <condition exit code>
  if [ "$2" -eq 0 ]; then echo "ok    $1"; else echo "FAIL  $1"; fail=1; fi
}
has() { printf '%s' "$1" | grep -qF -- "$2"; }

# manifest_get reads a comma-separated list as one scalar
got=$(sh -c '. "$CLAUDE_PLUGIN_ROOT/hooks/lib.sh"; manifest_get publish_targets docs')
[ "$got" = "docs,notion" ]; check "manifest_get reads publish_targets" $?

# SessionStart injects the loop and the index
out=$(sh "$root/hooks/session-start.sh" </dev/null)
has "$out" "<gotcha-memory"; check "session-start injects the memory block" $?
has "$out" "start here"; check "session-start injects INDEX.md" $?

# Stop: a turn that edited code and wrote nothing to gotchas/ is blocked once
printf '{"session_id":"t1","tool_name":"Edit","tool_input":{"file_path":"%s/src/a.ts"}}' "$proj" | sh "$root/hooks/track.sh"
out=$(printf '{"session_id":"t1"}' | sh "$root/hooks/stop.sh")
has "$out" '"decision"'; check "stop blocks a code turn with no write-back" $?
has "$out" "gotcha write-back"; check "stop block carries the write-back reason" $?

# Stop: the same turn after the nudge (stop_hook_active) passes
printf '{"session_id":"t2","tool_name":"Edit","tool_input":{"file_path":"%s/src/a.ts"}}' "$proj" | sh "$root/hooks/track.sh"
out=$(printf '{"session_id":"t2","stop_hook_active":true}' | sh "$root/hooks/stop.sh")
[ -z "$out" ]; check "stop passes when already continuing" $?

# Stop: a turn that wrote to gotchas/ passes (publish_when: manual)
printf '{"session_id":"t3","tool_name":"Edit","tool_input":{"file_path":"%s/src/a.ts"}}' "$proj" | sh "$root/hooks/track.sh"
printf '{"session_id":"t3","tool_name":"Edit","tool_input":{"file_path":"%s/gotchas/overview.md"}}' "$proj" | sh "$root/hooks/track.sh"
out=$(printf '{"session_id":"t3"}' | sh "$root/hooks/stop.sh")
[ -z "$out" ]; check "stop passes when the base was updated" $?

# Stop: autocapture off passes
sed -i 's/autocapture: auto/autocapture: off/' "$proj/gotchas/manifest.yml"
printf '{"session_id":"t4","tool_name":"Edit","tool_input":{"file_path":"%s/src/a.ts"}}' "$proj" | sh "$root/hooks/track.sh"
out=$(printf '{"session_id":"t4"}' | sh "$root/hooks/stop.sh")
[ -z "$out" ]; check "stop passes when autocapture is off" $?

# Stop: on-change asks for a publish only when docs is a channel and pages are behind
sed -i 's/autocapture: off/autocapture: auto/; s/publish_when: manual/publish_when: on-change/' "$proj/gotchas/manifest.yml"
printf '# Overview\n' >"$proj/gotchas/overview.md"
printf '{"session_id":"t5","tool_name":"Edit","tool_input":{"file_path":"%s/gotchas/overview.md"}}' "$proj" | sh "$root/hooks/track.sh"
out=$(printf '{"session_id":"t5"}' | sh "$root/hooks/stop.sh")
has "$out" "gotcha publish"; check "stop asks for a publish when docs is a channel" $?
sed -i 's/publish_targets: docs,notion/publish_targets: notion/' "$proj/gotchas/manifest.yml"
printf '{"session_id":"t6","tool_name":"Edit","tool_input":{"file_path":"%s/gotchas/overview.md"}}' "$proj" | sh "$root/hooks/track.sh"
out=$(printf '{"session_id":"t6"}' | sh "$root/hooks/stop.sh")
[ -z "$out" ]; check "stop stays silent when docs is not a channel" $?

exit $fail
