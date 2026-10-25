#!/usr/bin/env sh
# stale.sh [page...] — for every `path:line` citation, compare the cited file
# against the commit the fact was verified at (the `verified YYYY-MM-DD @ sha`
# stamp of its card, else of its page). Prints only what needs a look:
#   missing   file is gone
#   changed   file changed since the fact was verified — re-check the claim
#   unpinned  no verified sha above the citation, so freshness is unknown
# Run from the repo root. No argument ⇒ every page under gotchas/.
set -eu
[ "$#" -gt 0 ] || set -- $(find gotchas -name '*.md' ! -name '_*' | sort)

for page in "$@"; do
  awk '
    /^### / { in_cards = 1; card = "" }
    {
      if (match(tolower($0), /verified [0-9-]+ @ [0-9a-f]+/)) {
        split(substr(tolower($0), RSTART, RLENGTH), p, " ")
        if (in_cards) card = p[4]; else page_sha = p[4]
      }
      s = $0
      while (match(s, /`[A-Za-z0-9_.\/-]+\.[A-Za-z0-9]+:[0-9]+(-[0-9]+)?`/)) {
        c = substr(s, RSTART + 1, RLENGTH - 2); sub(/:[0-9-]+$/, "", c)
        sha = card != "" ? card : page_sha
        print (sha != "" ? sha : "-") "\t" c
        s = substr(s, RSTART + RLENGTH)
      }
    }' "$page" | sort -u | while IFS='	' read -r sha path; do
    if [ ! -e "$path" ]; then
      printf '%s\tmissing\t%s\n' "$page" "$path"
    elif [ "$sha" = - ] || ! git cat-file -e "$sha^{commit}" 2>/dev/null; then
      printf '%s\tunpinned\t%s\n' "$page" "$path"
    elif ! git diff --quiet "$sha" -- "$path" 2>/dev/null; then
      printf '%s\tchanged\t%s\t(since %s)\n' "$page" "$path" "$sha"
    fi
  done
done
