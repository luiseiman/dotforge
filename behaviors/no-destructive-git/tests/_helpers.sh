#!/usr/bin/env bash
# Shared helpers for no-destructive-git scenarios.
set -u

_self_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }

scenario_init() {
    local self_dir repo_root
    self_dir=$(_self_dir)
    repo_root=$(cd "${self_dir}/../../.." && pwd)

    FORGE_ROOT=$(mktemp -d -t forge-ndg-XXXXXXXX)
    export FORGE_ROOT
    export FORGE_LIB_PATH="${repo_root}/scripts/runtime/lib.sh"

    HOOK_DIR="${FORGE_ROOT}/compiled"
    mkdir -p "$HOOK_DIR"

    # shellcheck source=../../../scripts/runtime/lib.sh
    . "$FORGE_LIB_PATH"
    forge_init

    bash "${repo_root}/scripts/compiler/compile.sh" \
        "${repo_root}/behaviors/no-destructive-git/behavior.yaml" \
        "$HOOK_DIR" >/dev/null 2>&1 || {
        printf 'scenario_init: compile failed\n' >&2; return 1;
    }

    HOOK=$(find "$HOOK_DIR" -name 'no-destructive-git__*.sh' | head -1)
    [ -x "$HOOK" ] || { printf 'scenario_init: hook missing\n' >&2; return 1; }
}

scenario_cleanup() {
    [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ] && rm -rf "$FORGE_ROOT"
}

SCENARIO_SID="scenario-ndg"

invoke_bash() {
    local cmd="$1"
    local payload
    payload=$(jq -cn --arg sid "$SCENARIO_SID" --arg cmd "$cmd" \
        '{session_id: $sid, tool_name: "Bash", tool_input: {command: $cmd}}')
    SCENARIO_STDOUT=$(printf '%s' "$payload" | bash "$HOOK" 2>/dev/null) || true
}

is_deny() {
    printf '%s' "$SCENARIO_STDOUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1
}

is_empty() { [ -z "$SCENARIO_STDOUT" ]; }

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "${1:-$(basename "$0")}"; }
