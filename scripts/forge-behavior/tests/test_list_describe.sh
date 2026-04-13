#!/usr/bin/env bash
# list / describe commands.
set -u
. "$(dirname "$0")/_helpers.sh"
trap cli_test_cleanup EXIT

cli_test_init

# --- list ---
out=$(bash "$CLI" list 2>/dev/null)
assert_contains "$out" "search-first" "list includes search-first" || exit 1
assert_contains "$out" "no-destructive-git" "list includes no-destructive-git" || exit 1
assert_contains "$out" "plan-before-code" "list includes plan-before-code" || exit 1
assert_contains "$out" "opinionated" "list shows category" || exit 1

# --- list --category filter ---
core_out=$(bash "$CLI" list --category core 2>/dev/null)
assert_contains "$core_out" "search-first" "core filter keeps search-first" || exit 1
case "$core_out" in
    *plan-before-code*)
        printf 'FAIL: core filter should not include plan-before-code\n' >&2; exit 1 ;;
esac

op_out=$(bash "$CLI" list --category opinionated 2>/dev/null)
assert_contains "$op_out" "plan-before-code" "opinionated filter keeps plan-before-code" || exit 1
case "$op_out" in
    *no-destructive-git*)
        printf 'FAIL: opinionated filter should not include no-destructive-git\n' >&2; exit 1 ;;
esac

# --- describe ---
desc=$(bash "$CLI" describe no-destructive-git 2>/dev/null)
assert_contains "$desc" "No Destructive Git Operations" "describe shows name" || exit 1
assert_contains "$desc" "category:    core" "describe shows category" || exit 1
assert_contains "$desc" "hard_block" "describe shows enforcement level" || exit 1
assert_contains "$desc" "Destructive git operations" "describe shows recovery hint" || exit 1

# describe with unknown id → error
if bash "$CLI" describe nonexistent 2>/dev/null; then
    printf 'FAIL: describe unknown id should error\n' >&2
    exit 1
fi

test_pass "test_list_describe"
