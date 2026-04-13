#!/usr/bin/env bash
# 10 parallel increments must serialize via lock → counter == 10.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

SID="test-session-lock"
BID="search-first"
HELPERS_DIR=$(cd "$(dirname "$0")" && pwd)

# Spawn 10 background increments, each in its own subshell with the same FORGE_ROOT.
export FORGE_ROOT
for i in 1 2 3 4 5 6 7 8 9 10; do
    (
        . "${HELPERS_DIR}/../lib.sh"
        forge_counter_increment "$SID" "$BID" "Write" >/dev/null
    ) &
done
wait

final=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].counter' "$FORGE_STATE_FILE")
assert_eq "10" "$final" "counter after 10 parallel increments" || exit 1

# Lock dir must not linger
if [ -d "$FORGE_LOCK_DIR" ]; then
    printf 'FAIL: lock dir lingered after all increments\n' >&2
    exit 1
fi

test_pass "test_lock"
