#!/bin/bash
# SessionStart hook: notify if claude-kit has updates available
# Silent unless updates found. Designed for < 2s execution.
# Requires: CLAUDE_KIT_DIR env var or ~/Documents/GitHub/claude-kit default

CLAUDE_KIT_DIR="${CLAUDE_KIT_DIR:-$HOME/Documents/GitHub/claude-kit}"

# Skip if claude-kit dir doesn't exist
[[ -d "$CLAUDE_KIT_DIR" ]] || exit 0

# Get current claude-kit version
CK_VERSION=$(cat "$CLAUDE_KIT_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')
[[ -z "$CK_VERSION" ]] && exit 0

# --- Check 1: project version vs claude-kit version ---
PROJECT_VERSION=""
MANIFEST=".forge-manifest.json"
if [[ -f "$MANIFEST" ]]; then
  PROJECT_VERSION=$(jq -r '.claude_kit_version // empty' "$MANIFEST" 2>/dev/null)
fi

# Fallback: check registry for this project path
if [[ -z "$PROJECT_VERSION" ]]; then
  PROJECT_PATH="$(pwd)"
  REGISTRY="$CLAUDE_KIT_DIR/registry/projects.yml"
  if [[ -f "$REGISTRY" ]]; then
    # Extract version for matching path (simple grep, no yq dependency)
    PROJECT_VERSION=$(awk -v path="$PROJECT_PATH" '
      /^  - name:/ { in_project=0 }
      /path:/ && index($0, path) { in_project=1 }
      in_project && /claude_kit_version:/ { gsub(/.*claude_kit_version: */, ""); print; exit }
    ' "$REGISTRY")
  fi
fi

# --- Check 2: remote updates (non-blocking, timeout 3s) ---
REMOTE_AHEAD=0
if [[ -d "$CLAUDE_KIT_DIR/.git" ]]; then
  FETCH_OUTPUT=$(cd "$CLAUDE_KIT_DIR" && timeout 3 git fetch --dry-run 2>&1)
  if [[ -n "$FETCH_OUTPUT" ]] && echo "$FETCH_OUTPUT" | grep -q "main"; then
    REMOTE_AHEAD=1
  fi
fi

# --- Output only if something to report ---
MSGS=()

if [[ -n "$PROJECT_VERSION" && "$PROJECT_VERSION" != "$CK_VERSION" ]]; then
  MSGS+=("⬆ claude-kit $PROJECT_VERSION → $CK_VERSION available. Run /forge sync to update.")
fi

if [[ "$REMOTE_AHEAD" -eq 1 ]]; then
  MSGS+=("⬆ claude-kit remote has new commits. Run: cd $CLAUDE_KIT_DIR && git pull")
fi

if [[ ${#MSGS[@]} -gt 0 ]]; then
  echo "──── claude-kit update check ────"
  for msg in "${MSGS[@]}"; do
    echo "$msg"
  done
  echo "─────────────────────────────────"
fi

exit 0
