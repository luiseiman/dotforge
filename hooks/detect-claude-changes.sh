#!/bin/bash
# Stop hook: detects .claude/ changes at the end of a session.
# Generates a sanitized inbox practice note for /forge update to process.
#
# Sanitization (hardened 2026-04-14):
# - Excludes ephemeral/machine-local paths (sessions, session-env, projects,
#   metrics, plugins, worktrees, *cache*.json, settings.local.json, forge-manifest).
#   These contain UUIDs, absolute paths, and state that must not reach tracked
#   practice records.
# - Reports categorized counts, NOT raw filenames, to avoid leaking foreign
#   project structure, path-encoded usernames (Claude's `.claude/projects/`
#   convention), or domain-specific rule names.
# - Rejects entirely if a sanitized filename matches a secret-prefix regex.
#   Pattern list adapted from NousResearch/hermes-agent agent/redact.py.
#   Fail-closed: on any secret match, exit 0 without writing the inbox file.
#
# === INSTALLATION ===
# 1. Set DOTFORGE_DIR to your clone location (global/sync.sh does this)
# 2. Make executable: chmod +x hooks/detect-claude-changes.sh
# 3. Wire it into ~/.claude/settings.json under hooks.Stop
# ========================

set -uo pipefail

DOTFORGE_DIR="${DOTFORGE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
INBOX_DIR="$DOTFORGE_DIR/practices/inbox"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
TODAY="$(date +%Y-%m-%d)"

# Skip when running inside dotforge itself
if [[ "$PROJECT_DIR" == "$DOTFORGE_DIR"* ]]; then
  exit 0
fi

# Collect files modified in last 2h, emitted as paths relative to PROJECT_DIR
RAW_CHANGED=$(find "$PROJECT_DIR/.claude" \( -name "*.md" -o -name "*.sh" -o -name "*.json" \) 2>/dev/null | while read -r f; do
  if [[ -f "$f" ]] && find "$f" -mmin -120 -print -quit 2>/dev/null | grep -q .; then
    echo "${f#"$PROJECT_DIR"/}"
  fi
done)

# Path exclusion: drop ephemeral/local-state paths that leak UUIDs, absolute
# filesystem structure, or cache/auth metadata.
EXCLUDE_PATHS='^\.claude/(session|sessions|session-env|projects|metrics|plugins|worktrees)/|^\.claude/[^/]*cache[^/]*\.json$|^\.claude/settings\.local\.json$|^\.claude/\.forge-manifest\.json$'
CHANGED=$(printf '%s\n' "$RAW_CHANGED" | grep -vE "$EXCLUDE_PATHS" | sed '/^$/d')

if [[ -z "$CHANGED" ]]; then
  exit 0
fi

# Secret scan on sanitized filenames. If ANY name looks like an API key prefix,
# refuse to write the inbox entry. Fail-closed.
SECRET_REGEX='sk-[A-Za-z0-9_-]{10}|ghp_[A-Za-z0-9]{10}|github_pat_[A-Za-z0-9_]{10}|gh[ours]_[A-Za-z0-9]{10}|xox[baprs]-[A-Za-z0-9-]{10}|AIza[A-Za-z0-9_-]{30}|AKIA[A-Z0-9]{16}|sk_(live|test)_[A-Za-z0-9]{10}|SG\.[A-Za-z0-9_-]{10}|hf_[A-Za-z0-9]{10}|r8_[A-Za-z0-9]{10}|npm_[A-Za-z0-9]{10}|pypi-[A-Za-z0-9_-]{10}|dop_v1_[A-Za-z0-9]{10}|tvly-[A-Za-z0-9]{10}|exa_[A-Za-z0-9]{10}|gsk_[A-Za-z0-9]{10}|pplx-[A-Za-z0-9]{10}|fal_[A-Za-z0-9_-]{10}|fc-[A-Za-z0-9]{10}|bb_live_[A-Za-z0-9_-]{10}'
if printf '%s\n' "$CHANGED" | grep -qE "$SECRET_REGEX"; then
  exit 0
fi

# Compute output path
SLUG="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-session-changes"
OUTFILE="$INBOX_DIR/${TODAY}-${SLUG}.md"

# Don't duplicate if one already exists today for this project
if [[ -f "$OUTFILE" ]]; then
  exit 0
fi

mkdir -p "$INBOX_DIR"

# Categorize: count files per top-level .claude/ subdirectory.
count_pattern() {
  printf '%s\n' "$CHANGED" | grep -cE "$1" || true
}

N_AGENTS=$(count_pattern '^\.claude/agents/')
N_COMMANDS=$(count_pattern '^\.claude/commands/')
N_HOOKS=$(count_pattern '^\.claude/hooks/')
N_RULES=$(count_pattern '^\.claude/rules/')
N_SKILLS=$(count_pattern '^\.claude/skills/')
N_MEMORY=$(count_pattern '^\.claude/agent-memory/')
N_CLAUDEMD=$(count_pattern '^\.claude/CLAUDE\.md$')
N_SETTINGS=$(count_pattern '^\.claude/settings\.json$')

TOTAL=$(printf '%s\n' "$CHANGED" | wc -l | tr -d ' ')
N_KNOWN=$((N_AGENTS + N_COMMANDS + N_HOOKS + N_RULES + N_SKILLS + N_MEMORY + N_CLAUDEMD + N_SETTINGS))
N_OTHER=$((TOTAL - N_KNOWN))

emit_line() {
  local label="$1" n="$2"
  if [[ "$n" -gt 0 ]]; then
    printf -- '- %s: %d\n' "$label" "$n"
  fi
}

SUMMARY=$({
  emit_line "agents"        "$N_AGENTS"
  emit_line "commands"      "$N_COMMANDS"
  emit_line "hooks"         "$N_HOOKS"
  emit_line "rules"         "$N_RULES"
  emit_line "skills"        "$N_SKILLS"
  emit_line "agent-memory"  "$N_MEMORY"
  emit_line "CLAUDE.md"     "$N_CLAUDEMD"
  emit_line "settings.json" "$N_SETTINGS"
  emit_line "other"         "$N_OTHER"
})

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
${TOTAL} file(s) modified in .claude/ of project ${PROJECT_NAME} during the session.

## Categories
${SUMMARY}

## Sanitization
File names and paths are intentionally not listed. This capture is machine-generated
and summary-only to avoid leaking absolute paths, usernames, session UUIDs,
cross-project filesystem structure, or domain-specific rule names. Ephemeral
runtime state (sessions/, session-env/, projects/, metrics/, plugins/, worktrees/,
*cache*.json, settings.local.json, forge-manifest) is excluded before counting.
If any sanitized filename matched a known API-key prefix regex, no inbox entry
would have been written at all.

## Evaluation needed
Review if these changes contain patterns, rules, or configurations that should
be generalized to dotforge. Inspect the originating project directly if more
detail is needed — this inbox entry is intentionally summary-only.

## Decision
Pending — evaluate in next /forge update
HEREDOC

exit 0
