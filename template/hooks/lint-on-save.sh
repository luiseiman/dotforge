#!/bin/bash
# PostToolUse hook: auto-lint on file save
# Install: .claude/hooks/lint-on-save.sh
# Matcher: Write|Edit
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null)

if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

# Python → ruff
if [[ "$FILE_PATH" =~ \.py$ ]]; then
  if command -v ruff &>/dev/null; then
    OUTPUT=$(ruff check "$FILE_PATH" 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi
fi

# TypeScript/JavaScript → eslint
if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]]; then
  if command -v npx &>/dev/null && [[ -f "node_modules/.bin/eslint" ]]; then
    OUTPUT=$(npx eslint "$FILE_PATH" --no-error-on-unmatched-pattern 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi
fi

# TypeScript → tsc type-check (complementary to eslint, .ts/.tsx only)
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

# Swift → swiftformat (check only)
if [[ "$FILE_PATH" =~ \.swift$ ]]; then
  if command -v swiftformat &>/dev/null; then
    OUTPUT=$(swiftformat --lint "$FILE_PATH" 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi
fi

exit 0
