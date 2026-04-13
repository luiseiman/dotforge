#!/usr/bin/env bash
# Corrupted state.json is recovered to empty schema on next access.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

# Write garbage
printf '%s' 'this is not valid json {{{' > "$FORGE_STATE_FILE"

# Next mutation must not fail; it should reset to empty and then apply the mutation.
forge_counter_increment "recovery-session" "search-first" "Write" >/dev/null || {
    printf 'FAIL: increment after corruption returned non-zero\n' >&2
    exit 1
}

# Verify: parseable JSON
jq -e . "$FORGE_STATE_FILE" >/dev/null || {
    printf 'FAIL: state.json still invalid after recovery\n' >&2
    exit 1
}

# Verify: the new session exists and counter is 1 (fresh start)
counter=$(jq -r '.sessions["recovery-session"].behaviors["search-first"].counter' "$FORGE_STATE_FILE")
assert_eq "1" "$counter" "counter after corruption recovery" || exit 1

test_pass "test_corruption"
