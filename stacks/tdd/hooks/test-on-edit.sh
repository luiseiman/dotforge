#!/usr/bin/env bash
# PostToolUse hook (matcher: Write|Edit)
# Runs the project's test suite whenever a source file is edited.
# Exit 0 always — warning only, never blocks.

set -euo pipefail

# ── 1. Extract the file path from TOOL_INPUT ──────────────────────────────────
FILE_PATH=""
if [ -n "${TOOL_INPUT:-}" ]; then
  # TOOL_INPUT is JSON; extract "path" or "file_path" field
  FILE_PATH=$(printf '%s' "$TOOL_INPUT" | python3 -c \
    "import sys,json; d=json.load(sys.stdin); print(d.get('path') or d.get('file_path',''))" 2>/dev/null || true)
fi

# Nothing to act on
[ -z "$FILE_PATH" ] && exit 0

# ── 2. Filter: source files only ─────────────────────────────────────────────
case "$FILE_PATH" in
  *.py|*.ts|*.tsx|*.js|*.jsx|*.go|*.swift|*.rb) ;;
  *) exit 0 ;;
esac

# ── 3. Skip test files ────────────────────────────────────────────────────────
# Match test directories or test-indicating patterns in the filename
case "$FILE_PATH" in
  tests/*|__tests__/*|spec/*|test/*) exit 0 ;;
  *_test.py|*_test.go|*_test.rb)    exit 0 ;;
  *.test.ts|*.test.tsx|*.test.js|*.test.jsx) exit 0 ;;
  *.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx) exit 0 ;;
esac

# ── 4. Resolve project root (directory of the edited file or cwd) ─────────────
PROJECT_ROOT="${CLAUDE_PROJECT_ROOT:-$(pwd)}"

# ── 5. Detect test runner ──────────────────────────────────────────────────────
TEST_CMD=""

# pytest
if [ -f "$PROJECT_ROOT/pytest.ini" ]; then
  TEST_CMD="python -m pytest -x --tb=short -q"
elif [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
  if grep -q '\[tool\.pytest' "$PROJECT_ROOT/pyproject.toml" 2>/dev/null; then
    TEST_CMD="python -m pytest -x --tb=short -q"
  fi
fi

# vitest
if [ -z "$TEST_CMD" ]; then
  if ls "$PROJECT_ROOT"/vitest.config.* 2>/dev/null | grep -q .; then
    TEST_CMD="npx vitest run --reporter=dot"
  fi
fi

# jest
if [ -z "$TEST_CMD" ]; then
  if ls "$PROJECT_ROOT"/jest.config.* 2>/dev/null | grep -q .; then
    TEST_CMD="npx jest --bail --reporters=default"
  fi
fi

# go
if [ -z "$TEST_CMD" ]; then
  if [ -f "$PROJECT_ROOT/go.mod" ]; then
    TEST_CMD="go test ./... -count=1"
  fi
fi

# swift
if [ -z "$TEST_CMD" ]; then
  if [ -f "$PROJECT_ROOT/Package.swift" ]; then
    TEST_CMD="swift test"
  fi
fi

# No runner detected — skip silently
[ -z "$TEST_CMD" ] && exit 0

# ── 6. Run tests ──────────────────────────────────────────────────────────────
echo "[test-on-edit] ${FILE_PATH} edited — running: ${TEST_CMD}" >&2

cd "$PROJECT_ROOT"
eval "$TEST_CMD" >&2 || true

exit 0
