#!/bin/bash
# Stop hook: detects .claude/ changes at the end of a session.
# If .claude/ files were modified during the session, generates a practice
# note in practices/inbox/ for /forge update to process.
#
# === INSTALLATION ===
# 1. Set DOTFORGE_DIR to your clone location (global/sync.sh does this)
# 2. Make executable: chmod +x hooks/detect-claude-changes.sh
# 3. Add to ~/.claude/settings.json:
#    {
#      "hooks": {
#        "Stop": [
#          {
#            "matcher": "",
#            "hooks": [
#              {
#                "type": "command",
#                "command": "$DOTFORGE_DIR/hooks/detect-claude-changes.sh"
#              }
#            ]
#          }
#        ]
#      }
#    }
# ========================

# Resolve DOTFORGE_DIR: use env var if set, otherwise default to script's parent
DOTFORGE_DIR="${DOTFORGE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
INBOX_DIR="$DOTFORGE_DIR/practices/inbox"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
TODAY="$(date +%Y-%m-%d)"

# Skip when running inside dotforge itself
if [[ "$PROJECT_DIR" == "$DOTFORGE_DIR"* ]]; then
  exit 0
fi

# Find .claude/ files modified in the last 2 hours
CHANGED_FILES=$(find "$PROJECT_DIR/.claude" -name "*.md" -o -name "*.sh" -o -name "*.json" 2>/dev/null | while read f; do
  if [[ -f "$f" ]] && find "$f" -mmin -120 -print -quit 2>/dev/null | grep -q .; then
    echo "$f"
  fi
done)

if [[ -z "$CHANGED_FILES" ]]; then
  exit 0
fi

# Ensure inbox directory exists
mkdir -p "$INBOX_DIR"

# Generate inbox practice note
SLUG="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-session-changes"
OUTFILE="$INBOX_DIR/${TODAY}-${SLUG}.md"

# Don't duplicate if one already exists today for this project
if [[ -f "$OUTFILE" ]]; then
  exit 0
fi

FILE_LIST=$(echo "$CHANGED_FILES" | sed "s|$PROJECT_DIR/||g" | sort)
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')

cat > "$OUTFILE" << HEREDOC
---
id: practice-${TODAY}-${SLUG}
title: "Changes detected in .claude/ of ${PROJECT_NAME}"
source: "post-session hook — ${PROJECT_NAME}"
source_type: experience
discovered: ${TODAY}
status: inbox
tags: [auto-detected, ${PROJECT_NAME}]
tested_in: ${PROJECT_NAME}
incorporated_in: []
replaced_by: null
---

## Description
${FILE_COUNT} file(s) modified in .claude/ of project ${PROJECT_NAME} during the session.

## Modified files
${FILE_LIST}

## Evaluation needed
Review if these changes contain patterns, rules, or configurations that should be generalized to dotforge.

## Decision
Pending — evaluate in next /forge update
HEREDOC

exit 0
