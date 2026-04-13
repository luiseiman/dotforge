#!/usr/bin/env bash
# pending_block lifecycle: hash stability, set, try_override match/miss/stale.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

SID="test-session-pending"
BID="search-first"

# --- Hash stability: same input → same hash, different input → different hash ---
h1=$(printf '{"file_path":"/foo.py","content":"x"}' | forge_tool_input_hash)
h2=$(printf '{"content":"x","file_path":"/foo.py"}' | forge_tool_input_hash)
h3=$(printf '{"file_path":"/bar.py","content":"x"}' | forge_tool_input_hash)

assert_eq "$h1" "$h2" "canonical hash is key-order independent" || exit 1
if [ "$h1" = "$h3" ]; then
    printf 'FAIL: different inputs produced identical hash\n' >&2
    exit 1
fi

# --- Seed a session with counter + pending_block ---
forge_counter_increment "$SID" "$BID" "Write" >/dev/null
forge_pending_block_set "$SID" "$BID" "$h1" || { printf 'FAIL: set\n' >&2; exit 1; }

# Verify it landed in state
stored=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].pending_block.tool_input_hash // empty' \
    "$FORGE_STATE_FILE")
assert_eq "$h1" "$stored" "pending_block stored hash" || exit 1

# --- try_override with matching hash → success, records override, clears pending_block ---
if ! forge_pending_block_try_override "$SID" "$BID" "Write" "$h1" "summary of input"; then
    printf 'FAIL: try_override should have succeeded with matching fresh hash\n' >&2
    exit 1
fi

# pending_block cleared
cleared=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].pending_block // "null"' \
    "$FORGE_STATE_FILE")
assert_eq "null" "$cleared" "pending_block cleared after override" || exit 1

# overrides[] grew by 1
ov_count=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].overrides | length' \
    "$FORGE_STATE_FILE")
assert_eq "1" "$ov_count" "override recorded in state" || exit 1

# audit log line present
audit_lines=$(wc -l < "$FORGE_AUDIT_LOG" | tr -d ' ')
assert_eq "1" "$audit_lines" "override recorded in audit log" || exit 1

# --- try_override with no pending_block → returns 1, no changes ---
if forge_pending_block_try_override "$SID" "$BID" "Write" "$h1" "summary"; then
    printf 'FAIL: try_override should have returned 1 with no pending_block\n' >&2
    exit 1
fi

# --- Mismatched hash clears the pending_block as stale ---
forge_pending_block_set "$SID" "$BID" "$h1"
if forge_pending_block_try_override "$SID" "$BID" "Write" "$h3" "summary"; then
    printf 'FAIL: try_override should have returned 1 on mismatched hash\n' >&2
    exit 1
fi
stale_cleared=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].pending_block // "null"' \
    "$FORGE_STATE_FILE")
assert_eq "null" "$stale_cleared" "pending_block cleared as stale on hash miss" || exit 1

# --- Expired window clears as stale ---
# Inject a pending_block with blocked_at 10 minutes ago
old_iso="2020-01-01T00:00:00Z"
tmp=$(mktemp)
jq --arg sid "$SID" --arg bid "$BID" --arg h "$h1" --arg old "$old_iso" \
    '.sessions[$sid].behaviors[$bid].pending_block = {tool_input_hash: $h, blocked_at: $old}' \
    "$FORGE_STATE_FILE" > "$tmp" && mv "$tmp" "$FORGE_STATE_FILE"

if forge_pending_block_try_override "$SID" "$BID" "Write" "$h1" "summary"; then
    printf 'FAIL: try_override should have returned 1 on expired window\n' >&2
    exit 1
fi
expired_cleared=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].pending_block // "null"' \
    "$FORGE_STATE_FILE")
assert_eq "null" "$expired_cleared" "pending_block cleared as stale on expired window" || exit 1

# Override count must still be 1 — we did not create a second override on the stale case
ov_count_final=$(jq -r --arg sid "$SID" --arg bid "$BID" \
    '.sessions[$sid].behaviors[$bid].overrides | length' \
    "$FORGE_STATE_FILE")
assert_eq "1" "$ov_count_final" "no new override recorded for stale pending_block" || exit 1

test_pass "test_pending_block"
