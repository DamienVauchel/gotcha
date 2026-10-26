#!/usr/bin/env sh
# render-diagrams.sh [--out DIR] [--png] FILE.md…
# Renders every ```mermaid block with the official CLI: a block that fails here
# is a broken diagram on every target. With --out, keeps the renders
# (<file>-<n>.svg, or .png with --png) — for Confluence attachments, or to look
# at them. Needs Node; uses a local mmdc, else npx (network).
set -eu
out="" ext=svg
while [ "$#" -gt 0 ]; do
  case "$1" in
    --out) out=$2; shift 2 ;;
    --png) ext=png; shift ;;
    *) break ;;
  esac
done
[ "$#" -gt 0 ] || { echo "usage: render-diagrams.sh [--out DIR] [--png] FILE.md…" >&2; exit 2; }

if command -v mmdc >/dev/null 2>&1; then
  mmdc() { command mmdc "$@"; }
elif command -v npx >/dev/null 2>&1; then
  mmdc() { npx -y @mermaid-js/mermaid-cli@11.4.2 "$@"; }
else
  echo "render-diagrams: node/npx not found — diagrams NOT verified" >&2
  exit 3
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Headless Chrome for mmdc: honour an explicit browser, else let puppeteer find one.
chrome="${PUPPETEER_EXECUTABLE_PATH:-}"
for c in chromium chromium-browser google-chrome; do
  [ -n "$chrome" ] && break
  command -v "$c" >/dev/null 2>&1 && chrome=$(command -v "$c")
done
if [ -n "$chrome" ]; then
  printf '{"executablePath":"%s","args":["--no-sandbox"]}' "$chrome" >"$work/pp.json"
else
  printf '{"args":["--no-sandbox"]}' >"$work/pp.json"
fi
[ -n "$out" ] && mkdir -p "$out"

fail=0 total=0
for f in "$@"; do
  stem=$(printf '%s' "$f" | sed 's#^\./##; s#\.md$##; s#/#-#g')
  awk -v dir="$work" -v stem="$stem" '
    /^```mermaid[[:space:]]*$/ { n++; file = dir "/" stem "-" n ".mmd"; inb = 1; next }
    inb && /^```[[:space:]]*$/ { inb = 0; close(file); next }
    inb { print > file }' "$f"
  for m in "$work/$stem"-*.mmd; do
    [ -f "$m" ] || continue
    total=$((total + 1))
    n=$(basename "$m" .mmd)
    target="$work/$n.$ext"
    [ -n "$out" ] && target="$out/$n.$ext"
    if err=$(mmdc -p "$work/pp.json" -i "$m" -o "$target" -s 2 -b white 2>&1); then
      printf 'ok\t%s#%s\n' "$f" "${n##*-}"
    else
      fail=$((fail + 1))
      printf 'FAIL\t%s#%s\t%s\n' "$f" "${n##*-}" "$(printf '%s' "$err" | grep -m1 -iE 'error|expect' || printf '%s' "$err" | tail -n 1)"
    fi
  done
done
printf '%s diagram(s), %s failed\n' "$total" "$fail"
[ "$fail" -eq 0 ]
