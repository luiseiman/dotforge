#!/usr/bin/env bash
# TaskUpdate → TaskCreate: flag consumed, counter stays 0.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke "$SET_HOOK" "TaskUpdate"
invoke "$CHECK_HOOK" "TaskCreate"
[ "$(counter)" = "0" ] || fail "counter should stay 0 after update→create, got $(counter)"

pass "scenario_update_then_create"
