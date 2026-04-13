#!/usr/bin/env bash
# forge_resolve_level is a pure function — test it without state.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

ESC='[{"after":1,"level":"nudge"},{"after":3,"level":"warning"},{"after":5,"level":"soft_block"}]'

# Counter below all thresholds → default
level=$(forge_resolve_level 0 "silent" "$ESC")
assert_eq "silent" "$level" "counter=0 → silent (default)" || exit 1

# counter=1 → nudge
level=$(forge_resolve_level 1 "silent" "$ESC")
assert_eq "nudge" "$level" "counter=1 → nudge" || exit 1

# counter=2 → still nudge (no threshold at 2)
level=$(forge_resolve_level 2 "silent" "$ESC")
assert_eq "nudge" "$level" "counter=2 → nudge" || exit 1

# counter=3 → warning
level=$(forge_resolve_level 3 "silent" "$ESC")
assert_eq "warning" "$level" "counter=3 → warning" || exit 1

# counter=4 → still warning
level=$(forge_resolve_level 4 "silent" "$ESC")
assert_eq "warning" "$level" "counter=4 → warning" || exit 1

# counter=5 → soft_block
level=$(forge_resolve_level 5 "silent" "$ESC")
assert_eq "soft_block" "$level" "counter=5 → soft_block" || exit 1

# counter=100 → still soft_block (highest threshold wins)
level=$(forge_resolve_level 100 "silent" "$ESC")
assert_eq "soft_block" "$level" "counter=100 → soft_block" || exit 1

# Empty escalation → default only
level=$(forge_resolve_level 10 "hard_block" "[]")
assert_eq "hard_block" "$level" "empty escalation → default" || exit 1

# Monotonic level max
assert_eq "warning" "$(forge_level_max silent warning)" "max(silent, warning)" || exit 1
assert_eq "soft_block" "$(forge_level_max warning soft_block)" "max(warning, soft_block)" || exit 1
assert_eq "warning" "$(forge_level_max warning warning)" "max(warning, warning)" || exit 1
assert_eq "hard_block" "$(forge_level_max hard_block nudge)" "max(hard_block, nudge)" || exit 1

test_pass "test_resolve_level"
