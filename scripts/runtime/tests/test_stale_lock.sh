#!/usr/bin/env bash
# Stale lock (PID not running) is detected and cleaned up on next acquire.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

# Plant a stale lock with a PID guaranteed not to exist.
mkdir -p "$FORGE_LOCK_DIR"
printf '%s' '99999999' > "${FORGE_LOCK_DIR}/pid"

# Acquire must succeed via stale-lock detection, not timeout.
start=$(date +%s)
if ! forge_lock_acquire; then
    printf 'FAIL: acquire timed out despite stale lock\n' >&2
    exit 1
fi
elapsed=$(( $(date +%s) - start ))
forge_lock_release

# Must be fast — well under the 2s timeout. Allow 1s slack for CI jitter.
if [ "$elapsed" -gt 1 ]; then
    printf 'FAIL: stale lock cleanup took %ds (expected <1)\n' "$elapsed" >&2
    exit 1
fi

test_pass "test_stale_lock"
