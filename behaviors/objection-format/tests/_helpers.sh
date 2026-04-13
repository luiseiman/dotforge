#!/usr/bin/env bash
set -u

_self_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }

scenario_init() {
    local self_dir repo_root
    self_dir=$(_self_dir)
    repo_root=$(cd "${self_dir}/../../.." && pwd)

    FORGE_ROOT=$(mktemp -d -t forge-objfmt-XXXXXXXX)
    export FORGE_ROOT
    export FORGE_LIB_PATH="${repo_root}/scripts/runtime/lib.sh"
    HOOK_DIR="${FORGE_ROOT}/compiled"
    mkdir -p "$HOOK_DIR"
    . "$FORGE_LIB_PATH"
    forge_init

    bash "${repo_root}/scripts/compiler/compile.sh" \
        "${repo_root}/behaviors/objection-format/behavior.yaml" \
        "$HOOK_DIR" >/dev/null 2>&1 || {
        printf 'scenario_init: compile failed\n' >&2; return 1;
    }
    HOOK=$(find "$HOOK_DIR" -name 'objection-format__*.sh' | head -1)
    [ -x "$HOOK" ] || { printf 'scenario_init: hook missing\n' >&2; return 1; }
}

scenario_cleanup() {
    [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ] && rm -rf "$FORGE_ROOT"
}

SID="scenario-objfmt"

invoke() {
    local prompt="$1"
    local payload
    payload=$(jq -cn --arg sid "$SID" --arg p "$prompt" \
        '{session_id: $sid, prompt: $p}')
    STDOUT=$(printf '%s' "$payload" | bash "$HOOK" 2>/dev/null) || true
}

counter() {
    jq -r --arg sid "$SID" --arg bid "objection-format" \
        '.sessions[$sid].behaviors[$bid].counter // 0' "$FORGE_STATE_FILE"
}

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "${1:-$(basename "$0")}"; }
