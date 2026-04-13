#!/usr/bin/env bash
# Three unverified pushes: nudge → warning → soft_block.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

# Push 1: nudge
invoke "$CHECK_HOOK" "git push"
[ "$(counter)" = "1" ] || fail "push 1: counter=1 expected, got $(counter)"
[ "$(level)" = "nudge" ] || fail "push 1: level=nudge, got $(level)"

# Push 2: warning
invoke "$CHECK_HOOK" "git push origin feature"
[ "$(counter)" = "2" ] || fail "push 2: counter=2 expected, got $(counter)"
[ "$(level)" = "warning" ] || fail "push 2: level=warning, got $(level)"

# Push 3: soft_block
invoke "$CHECK_HOOK" "git push origin main"
[ "$(counter)" = "3" ] || fail "push 3: counter=3, got $(counter)"
[ "$(level)" = "soft_block" ] || fail "push 3: level=soft_block, got $(level)"
printf '%s' "$STDOUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null \
    || fail "push 3 should emit deny JSON"

pass "scenario_unverified_escalation"
