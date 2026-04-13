#!/usr/bin/env bash
# Five Write calls without prior Grep → counter escalates silent → nudge → warning → soft_block.
# Mirrors the escalation table in RUNTIME.md §5.
set -u
. "$(dirname "$0")/_scenario_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

# Write #1: counter=1 → nudge (first threshold)
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "1" "$(state_counter)" "write#1 counter" || exit 1
assert_eq "nudge" "$(state_effective_level)" "write#1 level" || exit 1
stdout_has_system_message || { printf 'FAIL: write#1 expected systemMessage\n' >&2; exit 1; }
stdout_is_deny && { printf 'FAIL: write#1 should not deny\n' >&2; exit 1; } || true

# Write #2: counter=2 → still nudge
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "2" "$(state_counter)" "write#2 counter" || exit 1
assert_eq "nudge" "$(state_effective_level)" "write#2 level" || exit 1

# Write #3: counter=3 → warning
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "3" "$(state_counter)" "write#3 counter" || exit 1
assert_eq "warning" "$(state_effective_level)" "write#3 level" || exit 1
stdout_has_system_message || { printf 'FAIL: write#3 expected systemMessage\n' >&2; exit 1; }

# Write #4: counter=4 → still warning (monotonic)
invoke_hook "$CHECK_FLAG_HOOK" "Edit"
assert_eq "4" "$(state_counter)" "write#4 counter" || exit 1
assert_eq "warning" "$(state_effective_level)" "write#4 level" || exit 1

# Write #5: counter=5 → soft_block
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "5" "$(state_counter)" "write#5 counter" || exit 1
assert_eq "soft_block" "$(state_effective_level)" "write#5 level" || exit 1
stdout_is_deny || { printf 'FAIL: write#5 expected permissionDecision deny\n  got: %s\n' "$SCENARIO_LAST_STDOUT" >&2; exit 1; }
stdout_has_system_message || { printf 'FAIL: write#5 expected systemMessage alongside deny\n' >&2; exit 1; }

# Write #6: same empty tool_input as the one that just got blocked → detected
# as reinvocation after override. Counter does NOT move, override recorded,
# stdout passes silently.
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "5" "$(state_counter)" "write#6 (override) counter unchanged" || exit 1
stdout_is_empty || {
    printf 'FAIL: write#6 override should be silent (got: %s)\n' "$SCENARIO_LAST_STDOUT" >&2
    exit 1
}
override_count=$(jq -r --arg sid "$SCENARIO_SESSION_ID" \
    '.sessions[$sid].behaviors["search-first"].overrides | length' "$FORGE_STATE_FILE")
assert_eq "1" "$override_count" "write#6 recorded one override in state" || exit 1

# pending_block cleared after override
pending=$(jq -r --arg sid "$SCENARIO_SESSION_ID" \
    '.sessions[$sid].behaviors["search-first"].pending_block // "null"' "$FORGE_STATE_FILE")
assert_eq "null" "$pending" "pending_block cleared after override" || exit 1

# Write #7: new tool_input (different file_path) → NOT an override, counter
# advances to 6, monotonic level stays soft_block.
invoke_hook "$CHECK_FLAG_HOOK" "Write" '{"file_path":"/src/different.py","content":"x"}'
assert_eq "6" "$(state_counter)" "write#7 counter advances" || exit 1
assert_eq "soft_block" "$(state_effective_level)" "write#7 level monotonic" || exit 1
stdout_is_deny || {
    printf 'FAIL: write#7 with new input should deny again\n' >&2
    exit 1
}

# The new soft_block sets a fresh pending_block with the new hash
pending_after=$(jq -r --arg sid "$SCENARIO_SESSION_ID" \
    '.sessions[$sid].behaviors["search-first"].pending_block.tool_input_hash // empty' \
    "$FORGE_STATE_FILE")
[ -n "$pending_after" ] || {
    printf 'FAIL: write#7 soft_block did not set a new pending_block\n' >&2
    exit 1
}

scenario_pass "scenario_escalation"
