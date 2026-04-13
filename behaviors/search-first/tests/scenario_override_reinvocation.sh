#!/usr/bin/env bash
# Override reinvocation: escalate to soft_block, then the exact same tool_input
# comes back → detected as override, passes silently, records audit in three
# places (state.overrides, .forge/audit/overrides.log, pending_block cleared).
set -u
. "$(dirname "$0")/_scenario_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

TARGET='{"file_path":"/src/target.py","content":"new impl"}'

# 5 consecutive Writes on the SAME target → counter 1..5, level → soft_block
for i in 1 2 3 4 5; do
    invoke_hook "$CHECK_FLAG_HOOK" "Write" "$TARGET"
done
assert_eq "5" "$(state_counter)" "5 writes → counter=5" || exit 1
assert_eq "soft_block" "$(state_effective_level)" "level soft_block" || exit 1

# Final call emitted deny AND set a pending_block with the target hash
pending_hash=$(jq -r --arg sid "$SCENARIO_SESSION_ID" \
    '.sessions[$sid].behaviors["search-first"].pending_block.tool_input_hash // empty' \
    "$FORGE_STATE_FILE")
[ -n "$pending_hash" ] || {
    printf 'FAIL: soft_block did not set pending_block\n' >&2
    exit 1
}

# Reinvoke with the exact same input → override detected
invoke_hook "$CHECK_FLAG_HOOK" "Write" "$TARGET"

# Counter must NOT have moved
assert_eq "5" "$(state_counter)" "override leaves counter unchanged" || exit 1

# stdout must be empty (silent pass through)
stdout_is_empty || {
    printf 'FAIL: override reinvocation should be silent, got: %s\n' "$SCENARIO_LAST_STDOUT" >&2
    exit 1
}

# state.overrides[] has 1 entry
ov_count=$(jq -r --arg sid "$SCENARIO_SESSION_ID" \
    '.sessions[$sid].behaviors["search-first"].overrides | length' "$FORGE_STATE_FILE")
assert_eq "1" "$ov_count" "state.overrides has one entry" || exit 1

# counter_at_override == 5
ov_counter=$(jq -r --arg sid "$SCENARIO_SESSION_ID" \
    '.sessions[$sid].behaviors["search-first"].overrides[0].counter_at_override' "$FORGE_STATE_FILE")
assert_eq "5" "$ov_counter" "override captured counter=5" || exit 1

# .forge/audit/overrides.log has 1 line
audit_lines=$(wc -l < "${FORGE_ROOT}/audit/overrides.log" | tr -d ' ')
assert_eq "1" "$audit_lines" "audit log has one override entry" || exit 1

# pending_block cleared
pending_after=$(jq -r --arg sid "$SCENARIO_SESSION_ID" \
    '.sessions[$sid].behaviors["search-first"].pending_block // "null"' "$FORGE_STATE_FILE")
assert_eq "null" "$pending_after" "pending_block cleared after override" || exit 1

# A second reinvocation with the same input now has no pending_block —
# it is treated as a fresh violation (counter=6, still soft_block monotonic).
invoke_hook "$CHECK_FLAG_HOOK" "Write" "$TARGET"
assert_eq "6" "$(state_counter)" "post-override Write increments counter again" || exit 1
assert_eq "soft_block" "$(state_effective_level)" "post-override still soft_block" || exit 1
stdout_is_deny || {
    printf 'FAIL: post-override Write should deny again\n' >&2
    exit 1
}

scenario_pass "scenario_override_reinvocation"
