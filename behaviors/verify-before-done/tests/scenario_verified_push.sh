#!/usr/bin/env bash
# pytest → git push: counter stays 0, flag consumed.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke "$SET_HOOK" "pytest tests/"
flag_present || fail "pytest should have set verification_done flag"

invoke "$CHECK_HOOK" "git push origin main"
[ "$(counter)" = "0" ] || fail "counter should be 0 after verified push, got $(counter)"
flag_present && fail "flag should have been consumed"

pass "scenario_verified_push"
