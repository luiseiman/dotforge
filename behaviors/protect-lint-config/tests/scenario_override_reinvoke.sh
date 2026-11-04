#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

# soft_block: first identical edit is denied, the exact reinvocation passes
# (pending_block hash match within the override window).
invoke_edit "tsconfig.json"
is_deny || fail "first edit to tsconfig.json should be blocked"

invoke_edit "tsconfig.json"
is_empty || fail "identical reinvocation should pass as an override, got: $SCENARIO_STDOUT"

pass "scenario_override_reinvoke"
