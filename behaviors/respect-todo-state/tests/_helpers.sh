#!/usr/bin/env bash
set -u

_self_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }

scenario_init() {
    local self_dir repo_root
    self_dir=$(_self_dir)
    repo_root=$(cd "${self_dir}/../../.." && pwd)

    FORGE_ROOT=$(mktemp -d -t forge-rts-XXXXXXXX)
    export FORGE_ROOT
    export FORGE_LIB_PATH="${repo_root}/scripts/runtime/lib.sh"
    HOOK_DIR="${FORGE_ROOT}/compiled"
    mkdir -p "$HOOK_DIR"
    . "$FORGE_LIB_PATH"
    forge_init

    bash "${repo_root}/scripts/compiler/compile.sh" \
        "${repo_root}/behaviors/respect-todo-state/behavior.yaml" \
        "$HOOK_DIR" >/dev/null 2>&1 || {
        printf 'scenario_init: compile failed\n' >&2; return 1;
    }
    SET_HOOK=$(find "$HOOK_DIR" -name 'respect-todo-state__*taskupdate__*.sh')
    CHECK_HOOK=$(find "$HOOK_DIR" -name 'respect-todo-state__*taskcreate__*.sh')
    [ -x "$SET_HOOK" ] && [ -x "$CHECK_HOOK" ] || {
        printf 'scenario_init: hooks missing\n' >&2; return 1;
    }
}

scenario_cleanup() {
    [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ] && rm -rf "$FORGE_ROOT"
}

SID="scenario-rts"

invoke() {
    local hook="$1" tool="$2"
    local payload
    payload=$(jq -cn --arg sid "$SID" --arg tool "$tool" \
        '{session_id: $sid, tool_name: $tool, tool_input: {}}')
    STDOUT=$(printf '%s' "$payload" | bash "$hook" 2>/dev/null) || true
}

counter() {
    jq -r --arg sid "$SID" --arg bid "respect-todo-state" \
        '.sessions[$sid].behaviors[$bid].counter // 0' "$FORGE_STATE_FILE"
}
level() {
    jq -r --arg sid "$SID" --arg bid "respect-todo-state" \
        '.sessions[$sid].behaviors[$bid].effective_level // "silent"' "$FORGE_STATE_FILE"
}

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "${1:-$(basename "$0")}"; }
