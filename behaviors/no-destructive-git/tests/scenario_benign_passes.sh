#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

for cmd in \
    "ls -la" \
    "git status" \
    "git push origin main" \
    "git commit -m 'wip'" \
    "git reset --soft HEAD~1" \
    "git clean -n" \
    "git branch -d feature/old"
do
    invoke_bash "$cmd"
    is_empty || fail "benign '$cmd' should pass silently, got: $SCENARIO_STDOUT"
done

pass "scenario_benign_passes"
