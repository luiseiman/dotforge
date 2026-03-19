#!/bin/bash
# PostToolUse hook: eslint on TS/JS files
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]] && [[ -f "$FILE_PATH" ]]; then
  if command -v npx &>/dev/null && [[ -f "node_modules/.bin/eslint" ]]; then
    OUTPUT=$(npx eslint "$FILE_PATH" --no-error-on-unmatched-pattern 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi
fi
exit 0
