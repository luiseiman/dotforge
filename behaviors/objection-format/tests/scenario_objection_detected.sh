#!/usr/bin/env bash
# Friction markers should increment the counter.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke "no, that's not what I meant"
[ "$(counter)" = "1" ] || fail "after 'no,': counter=1, got $(counter)"

invoke "don't touch that file"
[ "$(counter)" = "2" ] || fail "after don't: counter=2, got $(counter)"

invoke "stop, revert that change"
[ "$(counter)" = "3" ] || fail "after stop: counter=3, got $(counter)"

pass "scenario_objection_detected"
