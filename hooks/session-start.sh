#!/usr/bin/env sh
# SessionStart (startup, resume, clear, compact): inject the L0 index and the
# working loop. No base yet ⇒ offer /gotcha-init once per repository.
set -eu
. "$(dirname "$0")/lib.sh"

if [ ! -f "$GOTCHA_BASE/INDEX.md" ]; then
  git -C "$GOTCHA_PROJECT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
  offered="${XDG_STATE_HOME:-$HOME/.local/state}/gotcha/offered"
  mkdir -p "$(dirname "$offered")" 2>/dev/null || true
  grep -qxF "$GOTCHA_PROJECT" "$offered" 2>/dev/null && exit 0
  printf '%s\n' "$GOTCHA_PROJECT" >>"$offered" 2>/dev/null || true
  cat <<'EOF'
<gotcha-setup>
The gotcha plugin is installed but this repository has no project memory yet
(no gotchas/INDEX.md). At the first natural opportunity, tell the user in one
line that `/gotcha-init` will analyse the code and write the base docs, and ask
whether to run it now. Mention it once; do not insist.
</gotcha-setup>
EOF
  exit 0
fi

mode=$(manifest_get autocapture auto)
cat <<EOF
<gotcha-memory mode="$mode">
This repo keeps its project memory in gotchas/ — human-readable docs, reviewed in PR.
Loop for every task:
1. RECALL — pick pages from the index below. Error or symptom ⇒ grep it in
   gotchas/troubleshooting/ first and read only the matching card. Read a page's
   TL;DR before its body. Go to the code when the docs are silent, when you are
   about to rely on a cited fact for a change, or when the page is stale
   (details: gotcha-recall skill).
2. ACT — do the task.
3. WRITE BACK — what this task taught you that the docs lacked goes into
   gotchas/ in the same change set, per the gotcha-capture skill. Nothing
   durable ⇒ write nothing. mode=propose ⇒ list findings and ask first.
Mid-task, drop a one-line \`gotcha: <fact>\` comment where you learn something
instead of stopping to edit docs.

EOF
# Hard cap: the index is paid for in every session. /gotcha-tidy keeps it under 60.
head -n 80 "$GOTCHA_BASE/INDEX.md"
printf '\n</gotcha-memory>\n'
