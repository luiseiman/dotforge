#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

for cmd in \
    "git push origin main --force" \
    "git push origin main -f" \
    "git push --force-with-lease origin feature" \
    "git reset --hard HEAD~3" \
    "git clean -fd" \
    "git clean -df" \
    "git branch -D feature/old" \
    "git branch -Df feature/other"
do
    invoke_bash "$cmd"
    is_deny || fail "destructive '$cmd' should be blocked, got: $SCENARIO_STDOUT"
done

pass "scenario_destructive_blocked"
