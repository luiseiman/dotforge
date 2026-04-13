#!/usr/bin/env bash
# Grep → Write: flag set by Grep is consumed by Write, NO violation counted.
# Second Write (without a new Grep): flag is gone, violation counted.
set -u
. "$(dirname "$0")/_scenario_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

# 1. Grep: sets flag, no counter movement
invoke_hook "$SET_FLAG_HOOK" "Grep"
state_flag_present "search_context_ready" || {
    printf 'FAIL: Grep did not set search_context_ready flag\n' >&2
    exit 1
}
assert_eq "0" "$(state_counter)" "after Grep: counter still 0" || exit 1
stdout_is_empty || {
    printf 'FAIL: set_flag hook should emit no stdout (got: %s)\n' "$SCENARIO_LAST_STDOUT" >&2
    exit 1
}

# 2. Write: flag present → consume, no violation
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "0" "$(state_counter)" "after Write with flag: counter still 0" || exit 1
if state_flag_present "search_context_ready"; then
    printf 'FAIL: flag was not consumed by Write\n' >&2
    exit 1
fi
stdout_is_empty || {
    printf 'FAIL: consumed check_flag should emit no stdout (got: %s)\n' "$SCENARIO_LAST_STDOUT" >&2
    exit 1
}
assert_eq "silent" "$(state_effective_level)" "level after consume stays silent" || exit 1

# 3. Second Write without fresh Grep: flag absent → violate, counter=1, nudge
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "1" "$(state_counter)" "second Write: counter=1" || exit 1
assert_eq "nudge" "$(state_effective_level)" "second Write: nudge" || exit 1
stdout_has_system_message || {
    printf 'FAIL: second Write expected systemMessage\n' >&2
    exit 1
}

scenario_pass "scenario_flag_happy_path"
