#!/usr/bin/env sh
# Injects the knowledge base index into every session so the agent knows what
# it already knows. Silent no-op in repos without a knowledge base.
set -eu

index="${CLAUDE_PROJECT_DIR:-.}/gotchas/INDEX.md"
[ -f "$index" ] || exit 0

# ponytail: flat 200-line cap. Split INDEX.md per scope if a repo outgrows it.
printf '<gotcha-index>\nKnowledge base present. Read the relevant page before searching the web or re-deriving the code. Capture durable findings back into it (/gotcha-investigate phase 6).\n\n'
head -n 200 "$index"
printf '\n</gotcha-index>\n'
