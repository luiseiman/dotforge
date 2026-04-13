#!/usr/bin/env bash
# Writes without a plan: counter increments, escalates.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke_write "src/a.py"
[ "$(counter)" = "1" ] || fail "write 1: counter=1, got $(counter)"
[ "$(level)" = "nudge" ] || fail "write 1: level=nudge, got $(level)"

invoke_write "src/b.py"
invoke_write "src/c.py"
[ "$(level)" = "warning" ] || fail "write 3: level=warning, got $(level)"

invoke_write "src/d.py"
invoke_write "src/e.py"
invoke_write "src/f.py"
[ "$(counter)" = "6" ] || fail "write 6: counter=6, got $(counter)"
[ "$(level)" = "soft_block" ] || fail "write 6: level=soft_block, got $(level)"

pass "scenario_unplanned_writes"
