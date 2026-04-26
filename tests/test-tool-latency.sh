#!/usr/bin/env bash
# Test suite for tool-latency.sh PostToolUse hook
# Run: bash tests/test-tool-latency.sh

set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
HOOK="$ROOT_DIR/template/hooks/tool-latency.sh"
PASSED=0; FAILED=0

pass() { echo "  ✓ $1"; PASSED=$((PASSED+1)); }
fail() { echo "  ✗ $1: $2"; FAILED=$((FAILED+1)); }

# Run hook in an isolated tmpdir so PROJECT_HASH is deterministic and
# the counter file does not collide with the user's real metrics.
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

# md5 hash of the temp PWD — must match _hash() in the hook
HASH=$(printf '%s' "$PWD" | md5sum 2>/dev/null | cut -c1-8 || \
       printf '%s' "$PWD" | md5 -q 2>/dev/null | cut -c1-8 || \
       printf '%s' "$PWD" | cksum | cut -d' ' -f1)
COUNTER="/tmp/claude-tool-latency-${HASH}"
rm -f "$COUNTER"

echo "═══ tool-latency.sh tests ═══"

# 1. Happy path: tool_name + duration_ms numeric → one line appended
echo '{"tool_name":"Bash","duration_ms":234,"hook_event_name":"PostToolUse"}' | bash "$HOOK"
if [[ -f "$COUNTER" ]] && grep -qE '^Bash\|234$' "$COUNTER"; then
  pass "happy path: writes 'Bash|234'"
else
  fail "happy path" "expected 'Bash|234' line in $COUNTER, got: $(cat "$COUNTER" 2>/dev/null || echo '<missing>')"
fi

# 2. Multiple calls accumulate
echo '{"tool_name":"Edit","duration_ms":12}' | bash "$HOOK"
echo '{"tool_name":"Read","duration_ms":3}' | bash "$HOOK"
LINES=$(wc -l < "$COUNTER" | tr -d ' ')
if [[ "$LINES" == "3" ]]; then
  pass "accumulates across calls (3 lines)"
else
  fail "accumulates" "expected 3 lines, got $LINES"
fi

# 3. Missing duration_ms → no-op (back-compat with Claude Code <v2.1.119)
rm -f "$COUNTER"
echo '{"tool_name":"Bash"}' | bash "$HOOK"
if [[ ! -f "$COUNTER" ]]; then
  pass "missing duration_ms → no-op"
else
  fail "missing duration_ms" "counter should not exist; got: $(cat "$COUNTER")"
fi

# 4. Non-numeric duration → no-op (defensive)
rm -f "$COUNTER"
echo '{"tool_name":"Bash","duration_ms":"slow"}' | bash "$HOOK"
if [[ ! -f "$COUNTER" ]]; then
  pass "non-numeric duration_ms → no-op"
else
  fail "non-numeric duration" "counter should not exist; got: $(cat "$COUNTER")"
fi

# 5. Pipe in tool_name is sanitized (won't break the parser)
rm -f "$COUNTER"
echo '{"tool_name":"weird|tool","duration_ms":7}' | bash "$HOOK"
if grep -qE '^weird_tool\|7$' "$COUNTER"; then
  pass "pipe in tool_name sanitized to _"
else
  fail "pipe sanitization" "expected 'weird_tool|7', got: $(cat "$COUNTER")"
fi

# 6. Empty stdin → no-op, exit 0
rm -f "$COUNTER"
printf '' | bash "$HOOK"
RC=$?
if [[ "$RC" == "0" && ! -f "$COUNTER" ]]; then
  pass "empty stdin → exit 0, no-op"
else
  fail "empty stdin" "rc=$RC, counter exists=$([[ -f $COUNTER ]] && echo yes || echo no)"
fi

# 7. Aggregation logic that session-report.sh uses (simulated)
rm -f "$COUNTER"
for d in 100 50 800 30; do
  echo "{\"tool_name\":\"Bash\",\"duration_ms\":$d}" | bash "$HOOK"
done
TOTAL=$(awk -F'|' 'BEGIN{s=0} {if($2 ~ /^[0-9]+$/) s+=$2} END{print s+0}' "$COUNTER")
SLOWEST=$(awk -F'|' '$2 ~ /^[0-9]+$/ {if ($2+0 > max) {max=$2+0; tool=$1}} END{if (tool!="") printf "%s=%dms", tool, max; else print "none"}' "$COUNTER")
if [[ "$TOTAL" == "980" && "$SLOWEST" == "Bash=800ms" ]]; then
  pass "session-report aggregation: total=980ms, slowest=Bash=800ms"
else
  fail "aggregation" "total=$TOTAL slowest=$SLOWEST (expected 980 + Bash=800ms)"
fi

rm -f "$COUNTER"

echo
echo "----------"
echo "$PASSED passed, $FAILED failed"
[[ "$FAILED" == "0" ]] && exit 0 || exit 1
