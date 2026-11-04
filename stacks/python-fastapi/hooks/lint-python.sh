#!/usr/bin/env bash
# PostToolUse hook: ruff check on Python files
HOOK_INPUT=$(cat 2>/dev/null || true)  # stdin JSON; no TOOL_INPUT env var exists
FILE_PATH=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" =~ \.py$ ]] && [[ -f "$FILE_PATH" ]]; then
  if command -v ruff &>/dev/null; then
    OUTPUT=$(ruff check "$FILE_PATH" 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi
fi
exit 0
