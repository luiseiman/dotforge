#!/usr/bin/env bash
# status action: empty runtime, then with a session populated.
set -u
. "$(dirname "$0")/_helpers.sh"
trap cli_test_cleanup EXIT

cli_test_init

# 1. Empty: lists behaviors from index.yaml, notes no sessions
out=$(bash "$CLI" status)
assert_contains "$out" "search-first" "status lists search-first" || exit 1
assert_contains "$out" "enabled=true" "status shows enabled flag" || exit 1
assert_contains "$out" "no active sessions" "status reports no sessions" || exit 1

# 2. Seed a session with some counters + pending_block via lib.sh
forge_counter_increment "scenario-sess-1" "search-first" "Write" >/dev/null
forge_counter_increment "scenario-sess-1" "search-first" "Write" >/dev/null
forge_pending_block_set "scenario-sess-1" "search-first" "deadbeef"

out=$(bash "$CLI" status)
assert_contains "$out" "session scenario-sess-1" "status shows session id" || exit 1
assert_contains "$out" "counter=2" "status shows counter" || exit 1
assert_contains "$out" "pending=true" "status reflects pending_block" || exit 1

# 3. Filtered status with --session
out=$(bash "$CLI" status --session scenario-sess-1)
assert_contains "$out" "scenario-sess-1" "filtered status shows session" || exit 1

# 4. Session overrides are shown when present
forge_behavior_session_disable "scenario-sess-1" "search-first"
out=$(bash "$CLI" status --session scenario-sess-1)
assert_contains "$out" "session overrides" "status shows session overrides header" || exit 1
assert_contains "$out" "enabled=false" "status shows disabled flag" || exit 1

test_pass "test_status"
