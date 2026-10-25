#!/usr/bin/env sh
# stats.sh [base-dir] — one line per page: size, cards, freshness, and the
# organization rule it breaks (references/organization.md). Costs no reading:
# skills run this instead of opening pages to decide whether to tidy.
set -eu
base="${1:-gotchas}"
[ -d "$base" ] || { echo "no knowledge base at $base" >&2; exit 1; }

INDEX_MAX="${GOTCHA_INDEX_MAX:-60}"
PAGE_MAX="${GOTCHA_PAGE_MAX:-300}"
CARDS_MAX="${GOTCHA_CARDS_MAX:-15}"
CARDS_MIN="${GOTCHA_CARDS_MIN:-3}"
COLD_DAYS="${GOTCHA_COLD_DAYS:-365}"
today=$(date +%Y-%m-%d)

indexed=$(cat "$base/INDEX.md" "$base/troubleshooting/INDEX.md" 2>/dev/null || true)

printf '%-44s %5s %5s %5s  %-10s  %s\n' page lines cards cold verified flags
find "$base" -name '*.md' ! -name '_*' | sort | while read -r f; do
  rel=${f#"$base"/}
  awk -v rel="$rel" -v today="$today" -v page_max="$PAGE_MAX" -v index_max="$INDEX_MAX" \
      -v cards_max="$CARDS_MAX" -v cards_min="$CARDS_MIN" -v cold_days="$COLD_DAYS" '
    function days(d,   y, m, dd) {  # days from civil, enough for differences
      y = substr(d, 1, 4) + 0; m = substr(d, 6, 2) + 0; dd = substr(d, 9, 2) + 0
      if (m <= 2) { y--; m += 12 }
      return 365 * y + int(y / 4) - int(y / 100) + int(y / 400) + int((153 * (m - 3) + 2) / 5) + dd
    }
    /^### (TS|D)-[0-9]+/ { cards++ }
    /> \*\*TL;DR\*\*/ { tldr = 1 }
    tolower($0) ~ /verified [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ {
      match(tolower($0), /verified [0-9-]+/); v = substr($0, RSTART + 9, 10)
      if (!pv && !cards) pv = v
    }
    /^### (TS|D)-[0-9]+/ { incard = 1 }
    incard && match($0, /last [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) {
      l = substr($0, RSTART + 5, 10); incard = 0
      if (days(today) - days(l) > cold_days) cold++
      if (l > newest) newest = l
    }
    END {
      flags = ""
      if (rel == "INDEX.md") { if (NR > index_max) flags = flags " INDEX>" index_max }
      else if (rel !~ /INDEX\.md$/ && !tldr) flags = flags " NO_TLDR"
      if (NR > page_max) flags = flags " SPLIT(lines)"
      if (rel ~ /^troubleshooting\// && rel !~ /INDEX\.md$/) {
        if (cards > cards_max) flags = flags " SPLIT(cards)"
        if (cards < cards_min && (newest == "" || days(today) - days(newest) > 180)) flags = flags " MERGE?"
      }
      if (cold) flags = flags " COLD"
      printf "%-44s %5d %5s %5s  %-10s %s\n", rel, NR, (cards ? cards : "-"), (cold ? cold : "-"), (pv ? pv : "-"), flags
    }' "$f" | {
    read -r line
    case "$rel" in
      INDEX.md | troubleshooting/INDEX.md | manifest.yml) ;;
      *) printf '%s' "$indexed" | grep -qF "$(basename "$rel")" || line="$line UNINDEXED" ;;
    esac
    printf '%s\n' "$line"
  }
done

next() {
  n=$(grep -rhoE "^### $1-[0-9]+" "$base" 2>/dev/null | sed "s/^### $1-0*//" | sort -n | tail -n 1)
  printf '%s-%03d' "$1" $(( ${n:-0} + 1 ))
}
markers=$(git grep -nI 'gotcha:' -- . ":(exclude)$base" 2>/dev/null | grep -c . || true)
printf '\nnext ids: %s %s · unharvested gotcha: markers: %s\n' "$(next TS)" "$(next D)" "$markers"
