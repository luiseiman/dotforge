#!/usr/bin/env bash
# Test suite for dotforge hooks
# Run: ./tests/test-hooks.sh
# Exit 0 if all pass, exit 1 if any fail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PASSED=0
FAILED=0

pass() {
  echo "  ✓ $1"
  PASSED=$((PASSED + 1))
}

fail() {
  echo "  ✗ $1"
  FAILED=$((FAILED + 1))
}

echo "═══ dotforge hook tests ═══"

# ─── block-destructive.sh ───

HOOK="$ROOT_DIR/template/hooks/block-destructive.sh"
echo "Testing block-destructive.sh..."

# The hook reads the real Claude Code payload on STDIN:
#   {"tool_name":"Bash","tool_input":{"command":"..."}}
# Never inject TOOL_INPUT env — that variable does not exist at runtime and
# masked an inert hook from v0.1.0 to v4.8.0.

test_block() {
  local cmd="$1"
  local label="$2"
  local tool_input
  tool_input=$(jq -cn --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')
  rc=0
  printf '%s' "$tool_input" | env -u TOOL_INPUT bash "$HOOK" >/dev/null 2>&1 || rc=$?
  if [[ $rc -eq 2 ]]; then
    pass "blocks: $label"
  else
    fail "blocks: $label (expected exit 2, got $rc)"
  fi
}

test_allow() {
  local cmd="$1"
  local label="$2"
  local tool_input
  # jq escapes embedded quotes — a hand-built printf produced invalid JSON for
  # `git commit -m "test"` and the hook correctly failed closed (exit 2)
  tool_input=$(jq -cn --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}')
  rc=0
  printf '%s' "$tool_input" | env -u TOOL_INPUT bash "$HOOK" >/dev/null 2>&1 || rc=$?
  if [[ $rc -eq 0 ]]; then
    pass "allows: $label"
  else
    fail "allows: $label (expected exit 0, got $rc)"
  fi
}

# Blocked commands
test_block "rm -rf /"                       "rm -rf /"
test_block "rm -rf *"                       "rm -rf *"
test_block "git push --force origin main"   "git push --force origin main"
test_block "git reset --hard"               "git reset --hard"
test_block "DROP TABLE users"               "DROP TABLE users"
test_block "git commit --no-verify -m wip"  "git commit --no-verify"
test_block "git config core.hooksPath /tmp/h"  "git config core.hooksPath"

# Allowed commands
test_allow "ls -la"                         "ls -la"
test_allow "git commit -m \"test\""         "git commit -m \"test\""
test_allow "python3 main.py"               "python3 main.py"

# ─── lint-on-save.sh ───

LINT_HOOK="$ROOT_DIR/template/hooks/lint-on-save.sh"
echo ""
echo "Testing lint-on-save.sh..."

# Check executable
if [[ -x "$LINT_HOOK" ]]; then
  pass "executable"
else
  fail "executable (not chmod +x)"
fi

# Check bash syntax
if bash -n "$LINT_HOOK" 2>/dev/null; then
  pass "bash syntax valid"
else
  fail "bash syntax valid"
fi

# ─── Results ───

TOTAL=$((PASSED + FAILED))
echo ""
echo "Results: $PASSED/$TOTAL passed"

if [[ $FAILED -gt 0 ]]; then
  exit 1
fi
exit 0
