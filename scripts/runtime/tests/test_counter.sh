#!/usr/bin/env bash
# Sequential counter increments produce counter == N.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

SID="test-session-counter"
BID="search-first"

for i in 1 2 3 4 5 6 7 8 9 10; do
    forge_counter_increment "$SID" "$BID" "Write" >/dev/null || {
        printf 'FAIL: increment %d returned non-zero\n' "$i" >&2
        exit 1
    }
done

final=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].counter' "$FORGE_STATE_FILE")

assert_eq "10" "$final" "counter after 10 sequential increments" || exit 1

last_tool=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].last_violation_tool' "$FORGE_STATE_FILE")
assert_eq "Write" "$last_tool" "last_violation_tool recorded" || exit 1

test_pass "test_counter"
