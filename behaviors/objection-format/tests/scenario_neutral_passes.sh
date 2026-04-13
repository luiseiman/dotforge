#!/usr/bin/env bash
# Neutral prompts should not fire.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke "Please continue with the plan."
invoke "What does the function do?"
invoke "Add a test for edge cases."

[ "$(counter)" = "0" ] || fail "neutral prompts should not count, got $(counter)"

pass "scenario_neutral_passes"
