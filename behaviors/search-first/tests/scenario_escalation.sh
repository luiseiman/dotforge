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

# Write #6: counter=6 → must stay soft_block (monotonic, not escalated further)
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "6" "$(state_counter)" "write#6 counter" || exit 1
assert_eq "soft_block" "$(state_effective_level)" "write#6 level monotonic" || exit 1

scenario_pass "scenario_escalation"
