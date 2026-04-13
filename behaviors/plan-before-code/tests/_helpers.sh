#!/usr/bin/env bash
set -u

_self_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }

scenario_init() {
    local self_dir repo_root
    self_dir=$(_self_dir)
    repo_root=$(cd "${self_dir}/../../.." && pwd)

    FORGE_ROOT=$(mktemp -d -t forge-pbc-XXXXXXXX)
    export FORGE_ROOT
    export FORGE_LIB_PATH="${repo_root}/scripts/runtime/lib.sh"
    HOOK_DIR="${FORGE_ROOT}/compiled"
    mkdir -p "$HOOK_DIR"
    . "$FORGE_LIB_PATH"
    forge_init

    bash "${repo_root}/scripts/compiler/compile.sh" \
        "${repo_root}/behaviors/plan-before-code/behavior.yaml" \
        "$HOOK_DIR" >/dev/null 2>&1 || {
        printf 'scenario_init: compile failed\n' >&2; return 1;
    }
    SET_HOOK=$(find "$HOOK_DIR" -name 'plan-before-code__*exitplanmode*.sh')
    CHECK_HOOK=$(find "$HOOK_DIR" -name 'plan-before-code__*write-edit*.sh')
    [ -x "$SET_HOOK" ] && [ -x "$CHECK_HOOK" ] || {
        printf 'scenario_init: hooks missing\n' >&2; return 1;
    }
}

scenario_cleanup() {
    [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ] && rm -rf "$FORGE_ROOT"
}

SID="scenario-pbc"

invoke_plan() {
    local payload
    payload=$(jq -cn --arg sid "$SID" '{session_id: $sid, tool_name: "ExitPlanMode", tool_input: {plan: "do X"}}')
    STDOUT=$(printf '%s' "$payload" | bash "$SET_HOOK" 2>/dev/null) || true
}

invoke_write() {
    local fp="$1"
    local payload
    payload=$(jq -cn --arg sid "$SID" --arg fp "$fp" \
        '{session_id: $sid, tool_name: "Write", tool_input: {file_path: $fp, content: "x"}}')
    STDOUT=$(printf '%s' "$payload" | bash "$CHECK_HOOK" 2>/dev/null) || true
}

counter() {
    jq -r --arg sid "$SID" --arg bid "plan-before-code" \
        '.sessions[$sid].behaviors[$bid].counter // 0' "$FORGE_STATE_FILE"
}
level() {
    jq -r --arg sid "$SID" --arg bid "plan-before-code" \
        '.sessions[$sid].behaviors[$bid].effective_level // "silent"' "$FORGE_STATE_FILE"
}

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "${1:-$(basename "$0")}"; }
