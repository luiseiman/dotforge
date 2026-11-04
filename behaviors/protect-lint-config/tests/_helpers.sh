#!/usr/bin/env bash
# Shared helpers for protect-lint-config scenarios.
set -u

_self_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }

scenario_init() {
    local self_dir repo_root
    self_dir=$(_self_dir)
    repo_root=$(cd "${self_dir}/../../.." && pwd)

    FORGE_ROOT=$(mktemp -d -t forge-plc-XXXXXXXX)
    export FORGE_ROOT
    export FORGE_LIB_PATH="${repo_root}/scripts/runtime/lib.sh"

    HOOK_DIR="${FORGE_ROOT}/compiled"
    mkdir -p "$HOOK_DIR"

    # shellcheck source=../../../scripts/runtime/lib.sh
    . "$FORGE_LIB_PATH"
    forge_init

    bash "${repo_root}/scripts/compiler/compile.sh" \
        "${repo_root}/behaviors/protect-lint-config/behavior.yaml" \
        "$HOOK_DIR" >/dev/null 2>&1 || {
        printf 'scenario_init: compile failed\n' >&2; return 1;
    }

    HOOK=$(find "$HOOK_DIR" -name 'protect-lint-config__*.sh' | head -1)
    [ -x "$HOOK" ] || { printf 'scenario_init: hook missing\n' >&2; return 1; }
}

scenario_cleanup() {
    [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ] && rm -rf "$FORGE_ROOT"
}

SCENARIO_SID="scenario-plc"

# invoke_edit <file_path> [tool_name]  — tool_name defaults to Edit
invoke_edit() {
    local path="$1" tool="${2:-Edit}"
    local payload
    payload=$(jq -cn --arg sid "$SCENARIO_SID" --arg p "$path" --arg t "$tool" \
        '{session_id: $sid, tool_name: $t, tool_input: {file_path: $p, old_string: "a", new_string: "b"}}')
    SCENARIO_STDOUT=$(printf '%s' "$payload" | bash "$HOOK" 2>/dev/null) || true
}

is_deny() {
    printf '%s' "$SCENARIO_STDOUT" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1
}

has_reason() {
    printf '%s' "$SCENARIO_STDOUT" | jq -e '.hookSpecificOutput.permissionDecisionReason | type == "string"' >/dev/null 2>&1
}

is_empty() { [ -z "$SCENARIO_STDOUT" ]; }

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "${1:-$(basename "$0")}"; }
