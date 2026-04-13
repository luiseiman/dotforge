#!/usr/bin/env bash
# Shared helpers for forge-behavior CLI tests.
set -u

_helpers_dir() { cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }

cli_test_init() {
    local hd repo_root
    hd=$(_helpers_dir)
    repo_root=$(cd "${hd}/../../.." && pwd)

    FORGE_ROOT=$(mktemp -d -t forge-cli-test-XXXXXXXX)
    export FORGE_ROOT

    # Copy behaviors/ into a tmp location so mutations don't touch the repo
    FORGE_BEHAVIORS_DIR="${FORGE_ROOT}/behaviors"
    export FORGE_BEHAVIORS_DIR
    mkdir -p "$FORGE_BEHAVIORS_DIR"
    cp -R "${repo_root}/behaviors/." "$FORGE_BEHAVIORS_DIR/"

    CLI="${repo_root}/scripts/forge-behavior/cli.sh"
    [ -x "$CLI" ] || { printf 'cli_test_init: CLI not executable: %s\n' "$CLI" >&2; return 1; }

    # Source lib.sh so tests can inspect state directly
    # shellcheck source=../../runtime/lib.sh
    . "${repo_root}/scripts/runtime/lib.sh"
    forge_init
}

cli_test_cleanup() {
    if [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ]; then
        rm -rf "$FORGE_ROOT"
    fi
}

assert_eq() {
    local expected="$1" actual="$2" msg="${3:-assert_eq}"
    if [ "$expected" != "$actual" ]; then
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$msg" "$expected" "$actual" >&2
        return 1
    fi
}

assert_contains() {
    local haystack="$1" needle="$2" msg="${3:-assert_contains}"
    case "$haystack" in
        *"$needle"*) return 0 ;;
        *)
            printf 'FAIL: %s\n  needle: %s\n  in: %s\n' "$msg" "$needle" "$haystack" >&2
            return 1
            ;;
    esac
}

test_pass() {
    printf 'PASS: %s\n' "${1:-$(basename "$0")}"
}

# _yaml_value <yaml_file> <jq-like path on JSON equiv> — helper for assertions
yaml_get() {
    python3 - "$1" "$2" <<'PY'
import sys, yaml, json
with open(sys.argv[1]) as f:
    data = yaml.safe_load(f) or {}
path = sys.argv[2].split('.')
v = data
try:
    for p in path:
        if isinstance(v, list):
            v = v[int(p)]
        else:
            v = v[p]
except (KeyError, IndexError, ValueError):
    v = None
print(json.dumps(v))
PY
}
