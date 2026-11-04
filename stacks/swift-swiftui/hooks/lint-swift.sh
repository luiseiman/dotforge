#!/usr/bin/env bash
# PostToolUse hook: swiftlint or swift build on Swift files
HOOK_INPUT=$(cat 2>/dev/null || true)  # stdin JSON; no TOOL_INPUT env var exists
FILE_PATH=$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" =~ \.swift$ ]] && [[ -f "$FILE_PATH" ]]; then
  # Prefer swiftlint if available
  if command -v swiftlint &>/dev/null; then
    OUTPUT=$(swiftlint lint --path "$FILE_PATH" --quiet 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  # Fallback: swift build for type checking
  elif command -v swift &>/dev/null; then
    # Find Package.swift by walking up
    DIR=$(dirname "$FILE_PATH")
    PACKAGE=""
    while [[ "$DIR" != "/" ]]; do
      if [[ -f "$DIR/Package.swift" ]]; then
        PACKAGE="$DIR/Package.swift"
        break
      fi
      DIR=$(dirname "$DIR")
    done

    if [[ -n "$PACKAGE" ]]; then
      OUTPUT=$(cd "$(dirname "$PACKAGE")" && swift build 2>&1)
      if [[ $? -ne 0 ]]; then
        echo "$OUTPUT" >&2
        exit 2
      fi
    fi
  fi
fi
exit 0
