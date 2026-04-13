#!/usr/bin/env bash
# End-to-end: after `off --session`, the compiled hook short-circuits silently.
# This verifies that the compile.sh template injection is wired up correctly
# and that a disabled behavior produces NO side effects (no counter, no flag,
# no output).
set -u
. "$(dirname "$0")/_helpers.sh"
trap cli_test_cleanup EXIT

cli_test_init

SID="sess-hook-disable-test"
export FORGE_LIB_PATH="$(cd "$(dirname "$0")/../.." && pwd)/runtime/lib.sh"

# Compile search-first into a tmp dir
HOOK_OUT="${FORGE_ROOT}/compiled"
mkdir -p "$HOOK_OUT"
bash "$(cd "$(dirname "$0")/../.." && pwd)/compiler/compile.sh" \
    "${FORGE_BEHAVIORS_DIR}/search-first/behavior.yaml" "$HOOK_OUT" >/dev/null 2>&1 \
    || { printf 'FAIL: compile\n' >&2; exit 1; }

CHECK_HOOK=$(find "$HOOK_OUT" -name 'search-first__pretooluse__write-edit__*.sh' | head -1)
[ -x "$CHECK_HOOK" ] || { printf 'FAIL: check_flag hook missing\n' >&2; exit 1; }

payload_for() {
    local tool="$1"
    jq -cn --arg sid "$SID" --arg tool "$tool" \
        '{session_id: $sid, tool_name: $tool, tool_input: {}}'
}

# --- Step 1: while enabled, a Write (no prior search) produces counter=1, nudge ---
out=$(printf '%s' "$(payload_for Write)" | bash "$CHECK_HOOK" 2>/dev/null)
counter=$(jq -r --arg sid "$SID" '.sessions[$sid].behaviors["search-first"].counter // 0' "$FORGE_STATE_FILE")
assert_eq "1" "$counter" "enabled: counter=1 after first Write" || exit 1
printf '%s' "$out" | jq -e '.systemMessage | type == "string"' >/dev/null \
    || { printf 'FAIL: enabled Write should emit systemMessage\n' >&2; exit 1; }

# --- Step 2: disable at session scope via the CLI ---
bash "$CLI" off search-first --session "$SID" >/dev/null || { printf 'FAIL: off session\n' >&2; exit 1; }

# --- Step 3: the next Write is a no-op: no stdout, no counter movement ---
snapshot_counter=$(jq -r --arg sid "$SID" '.sessions[$sid].behaviors["search-first"].counter // 0' "$FORGE_STATE_FILE")
out=$(printf '%s' "$(payload_for Write)" | bash "$CHECK_HOOK" 2>/dev/null)

# stdout empty
[ -z "$out" ] || { printf 'FAIL: disabled hook should emit nothing, got: %s\n' "$out" >&2; exit 1; }

# counter did NOT move
post_counter=$(jq -r --arg sid "$SID" '.sessions[$sid].behaviors["search-first"].counter // 0' "$FORGE_STATE_FILE")
assert_eq "$snapshot_counter" "$post_counter" "disabled: counter frozen" || exit 1

# --- Step 4: re-enable and verify hook fires again ---
bash "$CLI" on search-first --session "$SID" >/dev/null
out=$(printf '%s' "$(payload_for Write)" | bash "$CHECK_HOOK" 2>/dev/null)
final_counter=$(jq -r --arg sid "$SID" '.sessions[$sid].behaviors["search-first"].counter // 0' "$FORGE_STATE_FILE")
if [ "$final_counter" -le "$post_counter" ]; then
    printf 'FAIL: re-enabled hook did not increment (before=%s after=%s)\n' "$post_counter" "$final_counter" >&2
    exit 1
fi

test_pass "test_hook_respects_session_disable"
