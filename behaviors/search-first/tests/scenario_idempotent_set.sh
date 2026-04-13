#!/usr/bin/env bash
# Grep → Grep → Glob → Write: three search-like tools re-set the same flag
# idempotently. Write still consumes exactly one flag and produces no violation.
set -u
. "$(dirname "$0")/_scenario_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

# Three consecutive set_flag invocations (different tool names all matching the same matcher)
invoke_hook "$SET_FLAG_HOOK" "Grep"
invoke_hook "$SET_FLAG_HOOK" "Glob"
invoke_hook "$SET_FLAG_HOOK" "Read"

# Still exactly one flag entry
flag_keys_count=$(jq -r --arg sid "$SCENARIO_SESSION_ID" '.sessions[$sid].flags | keys | length' "$FORGE_STATE_FILE")
assert_eq "1" "$flag_keys_count" "three sets collapse to one flag entry" || exit 1

# Counter still 0 — flag operations never touch counters
assert_eq "0" "$(state_counter)" "counter untouched by set_flag" || exit 1

# Write consumes the flag → no violation
invoke_hook "$CHECK_FLAG_HOOK" "Write"
assert_eq "0" "$(state_counter)" "Write after multi-set: counter still 0" || exit 1
state_flag_present "search_context_ready" && {
    printf 'FAIL: flag should have been consumed\n' >&2
    exit 1
} || true

scenario_pass "scenario_idempotent_set"
