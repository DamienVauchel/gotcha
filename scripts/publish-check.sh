#!/usr/bin/env sh
# publish-check.sh — what the human docs need rebuilt (references/publishing.md).
#
#   publish-check.sh                         list changed / new / removed sources, hand-edited outputs
#   publish-check.sh --count                 one number: sources behind (for hooks)
#   publish-check.sh --record OUT REMOTE SRCS
#       after writing OUT (a local path, or a name for a remote page) from the
#       comma-separated SRCS (paths relative to gotchas/): store their hashes.
#       REMOTE is the remote page id, or - for local files.
#
# State lives in gotchas/.publish-state (committed). Hashes ignore <sub> lines,
# so a seen bump or a re-stamp does not trigger a rebuild. Run from the repo root.
set -eu
base="${GOTCHA_BASE_DIR:-gotchas}"
state="$base/.publish-state"
[ -d "$base" ] || { echo "no knowledge base at $base" >&2; exit 1; }

h() { sed '/<sub>/d' "$1" | cksum | cut -d' ' -f1; }

sources() {
  find "$base" -name '*.md' ! -name '_*' ! -name 'INDEX.md' | sed "s#^$base/##" | sort
}

if [ "${1:-}" = --record ]; then
  [ "$#" -eq 4 ] || { echo "usage: --record OUT REMOTE SRC[,SRC…]" >&2; exit 2; }
  out=$2 remote=$3 srcs=$4
  tmp="$state.tmp"
  { [ -f "$state" ] && cat "$state" || true; } |
    awk -F'\t' -v o="$out" -v s=",$srcs," '
      !($1 == "out" && $2 == o) && !($1 == "src" && index(s, "," $2 ",") > 0)' >"$tmp"
  for s in $(printf '%s' "$srcs" | tr ',' ' '); do
    [ -f "$base/$s" ] || { echo "no source $base/$s" >&2; rm -f "$tmp"; exit 2; }
    printf 'src\t%s\t%s\n' "$s" "$(h "$base/$s")" >>"$tmp"
  done
  oh=-
  [ -f "$out" ] && oh=$(h "$out")
  printf 'out\t%s\t%s\t%s\t%s\n' "$out" "$oh" "$remote" "$srcs" >>"$tmp"
  sort "$tmp" >"$state" && rm -f "$tmp"
  exit 0
fi

report=$(
  sources | while read -r s; do
    rec=$( { [ -f "$state" ] && awk -F'\t' -v s="$s" '$1 == "src" && $2 == s { print $3 }' "$state"; } || true)
    outs=$( { [ -f "$state" ] && awk -F'\t' -v s=",$s," '$1 == "out" && index("," $5 ",", s) > 0 { printf " %s", $2 }' "$state"; } || true)
    if [ -z "$rec" ]; then
      printf 'new\t%s\n' "$s"
    elif [ "$rec" != "$(h "$base/$s")" ]; then
      printf 'changed\t%s\t→%s\n' "$s" "$outs"
    fi
  done
  [ -f "$state" ] || exit 0
  awk -F'\t' '$1 == "src" { print $2 }' "$state" | while read -r s; do
    [ -f "$base/$s" ] || printf 'removed\t%s\t→%s\n' "$s" \
      "$(awk -F'\t' -v s=",$s," '$1 == "out" && index("," $5 ",", s) > 0 { printf " %s", $2 }' "$state")"
  done
  awk -F'\t' '$1 == "out" && $3 != "-" { print $2 "\t" $3 }' "$state" | while IFS='	' read -r o oh; do
    if [ ! -f "$o" ]; then printf 'missing\t%s\n' "$o"
    elif [ "$(h "$o")" != "$oh" ]; then printf 'edited\t%s\n' "$o"
    fi
  done
)

if [ "${1:-}" = --count ]; then
  printf '%s' "$report" | grep -cE '^(new|changed|removed)' || true
  exit 0
fi
if [ -z "$report" ]; then echo fresh; else printf '%s\n' "$report"; fi
