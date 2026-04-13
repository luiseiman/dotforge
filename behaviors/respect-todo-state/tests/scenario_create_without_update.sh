#!/usr/bin/env bash
# TaskCreate without prior TaskUpdate: nudge → warning → soft_block.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke "$CHECK_HOOK" "TaskCreate"
[ "$(counter)" = "1" ] || fail "create 1: counter=1, got $(counter)"
[ "$(level)" = "nudge" ] || fail "create 1: level=nudge, got $(level)"

invoke "$CHECK_HOOK" "TaskCreate"
invoke "$CHECK_HOOK" "TaskCreate"
[ "$(counter)" = "3" ] || fail "create 3: counter=3, got $(counter)"
[ "$(level)" = "warning" ] || fail "create 3: level=warning, got $(level)"

invoke "$CHECK_HOOK" "TaskCreate"
invoke "$CHECK_HOOK" "TaskCreate"
[ "$(counter)" = "5" ] || fail "create 5: counter=5, got $(counter)"
[ "$(level)" = "soft_block" ] || fail "create 5: level=soft_block, got $(level)"
printf '%s' "$STDOUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null \
    || fail "create 5 should emit deny JSON"

pass "scenario_create_without_update"
