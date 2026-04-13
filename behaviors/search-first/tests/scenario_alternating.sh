#!/usr/bin/env bash
# Alternating pattern: Grep → Write → Grep → Write → Write.
# Expected: first two Writes consume flags (0 violations), third Write violates (counter=1).
# This is the realistic "search before each write" discipline.
set -u
. "$(dirname "$0")/_scenario_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke_hook "$SET_FLAG_HOOK"   "Grep"
invoke_hook "$CHECK_FLAG_HOOK" "Write"   # consumes
assert_eq "0" "$(state_counter)" "Write#1 after Grep: no violation" || exit 1

invoke_hook "$SET_FLAG_HOOK"   "Glob"
invoke_hook "$CHECK_FLAG_HOOK" "Edit"    # consumes
assert_eq "0" "$(state_counter)" "Edit after Glob: no violation" || exit 1

# Third Write without a fresh search → violates
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "1" "$(state_counter)" "Write#3 without search: counter=1" || exit 1
assert_eq "nudge" "$(state_effective_level)" "Write#3 level nudge" || exit 1

scenario_pass "scenario_alternating"
