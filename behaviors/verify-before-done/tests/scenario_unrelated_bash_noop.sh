#!/usr/bin/env bash
# Unrelated Bash commands (ls, cat) should not touch counter or flag.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke "$SET_HOOK" "ls -la"
invoke "$SET_HOOK" "cat README.md"
invoke "$CHECK_HOOK" "ls -la"
invoke "$CHECK_HOOK" "cat README.md"

[ "$(counter)" = "0" ] || fail "unrelated commands incremented counter to $(counter)"
flag_present && fail "unrelated commands set flag"

pass "scenario_unrelated_bash_noop"
