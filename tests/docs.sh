#!/usr/bin/env sh
# Drift check: README and wiki/ are gotcha's own human docs and must describe
# what the plugin actually ships. Fails when a skill, agent, hook, script,
# channel or manifest key exists in the plugin but not in the docs.
# Run from anywhere: sh tests/docs.sh
set -eu
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
fail=0
miss() { echo "FAIL  $1"; fail=1; }
need() { # need <file> <text> <what>
  grep -qF -- "$2" "$1" || miss "$3 \`$2\` is not in $1"
}

# Versions agree: plugin.json, marketplace.json, README badge
v=$(jq -r .version .claude-plugin/plugin.json)
[ "$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json)" = "$v" ] || miss "marketplace.json version differs from plugin.json ($v)"
grep -qF "version-$v-" README.md || miss "README badge does not show version $v"

# Every skill is in the README and in wiki/Commands.md
for d in skills/*/; do
  s=$(basename "$d")
  need README.md "/$s" "skill"
  need wiki/Commands.md "/$s" "skill"
done

# Every agent is in wiki/Agents.md
for f in agents/*.md; do need wiki/Agents.md "$(basename "$f" .md)" "agent"; done

# Every hook script is in wiki/Hooks.md, every helper script in wiki/Scripts.md
for h in session-start track stop; do need wiki/Hooks.md "$h.sh" "hook"; done
for f in scripts/*.sh; do need wiki/Scripts.md "$(basename "$f")" "script"; done

# Every publication channel in the manifest template is in the README and the channels page
channels=$(awk '/publish_targets:/ { on = 1 } on && /publish_dir:/ { exit } on { print }' templates/manifest.yml |
  sed 's/^#//; s/.*any mix of://' | tr '\n' ' ' | tr '|' '\n' | sed 's/^[ ]*//; s/[ ]*$//' |
  grep -E '^[a-z-]+$' | grep -vx none || true)
[ -n "$channels" ] || miss "could not read the channel list from templates/manifest.yml"
for c in $channels; do
  need README.md "$c" "channel"
  need wiki/Publishing-Channels.md "$c" "channel"
done

# Every top-level manifest key is in wiki/Configuration.md
for k in $(grep -oE '^[a-z_]+:' templates/manifest.yml | tr -d ':' | sort -u); do
  need wiki/Configuration.md "$k" "manifest key"
done

# Sidebar and pages agree
for f in wiki/*.md; do
  p=$(basename "$f" .md)
  case "$p" in _*) continue ;; esac
  grep -qF "($(printf '%s' "$p" | tr ' ' '-'))" wiki/_Sidebar.md || miss "wiki page $p is not in _Sidebar.md"
done

[ "$fail" -eq 0 ] && echo "ok    docs match the plugin"
exit $fail
