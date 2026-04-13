#!/usr/bin/env bash
# Shared helpers for search-first scenarios. Sourced by each scenario_*.sh.
#
# Responsibility:
#   - Create an isolated FORGE_ROOT
#   - Compile the canonical behaviors/search-first/behavior.yaml into it
#   - Export FORGE_LIB_PATH so compiled hooks source the right lib.sh
#   - Provide invoke_hook and assertion helpers against state.json

set -u

_scenario_self_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

scenario_init() {
    local self_dir repo_root
    self_dir=$(_scenario_self_dir)
    repo_root=$(cd "${self_dir}/../../.." && pwd)

    FORGE_ROOT=$(mktemp -d -t forge-scenario-XXXXXXXX)
    export FORGE_ROOT
    export FORGE_LIB_PATH="${repo_root}/scripts/runtime/lib.sh"

    SCENARIO_HOOK_DIR="${FORGE_ROOT}/compiled"
    mkdir -p "$SCENARIO_HOOK_DIR"

    # shellcheck source=../../../scripts/runtime/lib.sh
    . "$FORGE_LIB_PATH"
    forge_init

    local behavior_yaml="${repo_root}/behaviors/search-first/behavior.yaml"
    [ -f "$behavior_yaml" ] || {
        printf 'scenario_init: behavior.yaml not found at %s\n' "$behavior_yaml" >&2
        return 1
    }
    bash "${repo_root}/scripts/compiler/compile.sh" "$behavior_yaml" "$SCENARIO_HOOK_DIR" >/dev/null 2>&1 || {
        printf 'scenario_init: compile failed\n' >&2
        return 1
    }

    # Resolve the two hook paths we generated for search-first.
    SET_FLAG_HOOK=$(find "$SCENARIO_HOOK_DIR" -name 'search-first__pretooluse__grep-glob-read__*.sh' | head -1)
    CHECK_FLAG_HOOK=$(find "$SCENARIO_HOOK_DIR" -name 'search-first__pretooluse__write-edit__*.sh' | head -1)

    [ -x "$SET_FLAG_HOOK" ] || { printf 'scenario_init: set_flag hook missing\n' >&2; return 1; }
    [ -x "$CHECK_FLAG_HOOK" ] || { printf 'scenario_init: check_flag hook missing\n' >&2; return 1; }
}

scenario_cleanup() {
    if [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ]; then
        rm -rf "$FORGE_ROOT"
    fi
}

# invoke_hook <hook_path> <tool_name> [tool_input_json]
# Emits hook stdout to SCENARIO_LAST_STDOUT, exit status to SCENARIO_LAST_RC.
SCENARIO_SESSION_ID="scenario-session-search-first"
invoke_hook() {
    local hook="$1" tool="$2"
    local tool_input="${3-}"
    [ -z "$tool_input" ] && tool_input='{}'
    local payload
    payload=$(jq -cn --arg sid "$SCENARIO_SESSION_ID" --arg tool "$tool" \
        --argjson input "$tool_input" \
        '{session_id: $sid, tool_name: $tool, tool_input: $input}')
    SCENARIO_LAST_STDOUT=$(printf '%s' "$payload" | bash "$hook" 2>/dev/null) || true
    SCENARIO_LAST_RC=$?
}

# --- Assertions ---

assert_eq() {
    local expected="$1" actual="$2" msg="${3:-assert_eq}"
    if [ "$expected" != "$actual" ]; then
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$msg" "$expected" "$actual" >&2
        return 1
    fi
}

state_counter() {
    jq -r --arg sid "$SCENARIO_SESSION_ID" --arg bid "search-first" \
        '.sessions[$sid].behaviors[$bid].counter // 0' "$FORGE_STATE_FILE"
}

state_effective_level() {
    jq -r --arg sid "$SCENARIO_SESSION_ID" --arg bid "search-first" \
        '.sessions[$sid].behaviors[$bid].effective_level // "silent"' "$FORGE_STATE_FILE"
}

state_flag_present() {
    local flag="$1"
    local v
    v=$(jq -r --arg sid "$SCENARIO_SESSION_ID" --arg flag "$flag" \
        '.sessions[$sid].flags[$flag] // empty' "$FORGE_STATE_FILE")
    [ -n "$v" ] && [ "$v" != "null" ]
}

stdout_is_empty() {
    [ -z "$SCENARIO_LAST_STDOUT" ]
}

stdout_has_system_message() {
    printf '%s' "$SCENARIO_LAST_STDOUT" | jq -e '.systemMessage | type == "string"' >/dev/null 2>&1
}

stdout_is_deny() {
    printf '%s' "$SCENARIO_LAST_STDOUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1
}

scenario_pass() {
    printf 'PASS: %s\n' "${1:-$(basename "$0")}"
}
