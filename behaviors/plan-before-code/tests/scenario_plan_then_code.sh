#!/usr/bin/env bash
# ExitPlanMode sets flag (kept). Multiple writes to .py pass without counting.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke_plan
invoke_write "src/foo.py"
invoke_write "src/bar.py"
invoke_write "src/baz.py"
[ "$(counter)" = "0" ] || fail "plan-approved writes should not count, got $(counter)"

pass "scenario_plan_then_code"
