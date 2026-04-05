#!/usr/bin/env bash
# PostToolUse hook: eslint + tsc type-check on TS/JS files
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]] && [[ -f "$FILE_PATH" ]]; then
  # Step 1: ESLint — runs on all TS/JS files
  if command -v npx &>/dev/null && [[ -f "node_modules/.bin/eslint" ]]; then
    OUTPUT=$(npx eslint "$FILE_PATH" --no-error-on-unmatched-pattern 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi

  # Step 2: TypeScript type-check — only for .ts/.tsx files
  # Finds the nearest tsconfig.json by walking up from the file's directory
  if [[ "$FILE_PATH" =~ \.(ts|tsx)$ ]] && command -v npx &>/dev/null; then
    TSCONFIG=""
    DIR=$(dirname "$FILE_PATH")
    while [[ "$DIR" != "/" ]]; do
      if [[ -f "$DIR/tsconfig.json" ]]; then
        TSCONFIG="$DIR/tsconfig.json"
        break
      fi
      DIR=$(dirname "$DIR")
    done

    if [[ -n "$TSCONFIG" ]]; then
      OUTPUT=$(npx tsc --noEmit --project "$TSCONFIG" 2>&1)
      if [[ $? -ne 0 ]]; then
        echo "$OUTPUT" >&2
        exit 2
      fi
    fi
  fi
fi
exit 0
