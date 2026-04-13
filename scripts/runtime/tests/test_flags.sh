#!/usr/bin/env bash
# Flag set → check → consume → check-absent cycle.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

SID="test-session-flags"
FLAG="search_context_ready"

# Absent initially
assert_false "flag absent before set" forge_flag_check "$SID" "$FLAG" || exit 1

# Set
forge_flag_set "$SID" "$FLAG" || { printf 'FAIL: set\n' >&2; exit 1; }
assert_true "flag present after set" forge_flag_check "$SID" "$FLAG" || exit 1

# Idempotent re-set
forge_flag_set "$SID" "$FLAG" || { printf 'FAIL: re-set\n' >&2; exit 1; }
count=$(jq -r --arg sid "$SID" \
    '.sessions[$sid].flags | keys | length' "$FORGE_STATE_FILE")
assert_eq "1" "$count" "idempotent re-set produces one flag entry" || exit 1

# Consume returns 0 and removes
forge_flag_consume "$SID" "$FLAG" || {
    printf 'FAIL: consume of present flag returned non-zero\n' >&2
    exit 1
}
assert_false "flag absent after consume" forge_flag_check "$SID" "$FLAG" || exit 1

# Second consume returns 1 (not present)
if forge_flag_consume "$SID" "$FLAG"; then
    printf 'FAIL: second consume should return 1\n' >&2
    exit 1
fi

test_pass "test_flags"
