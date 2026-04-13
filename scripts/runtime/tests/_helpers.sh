#!/usr/bin/env bash
# Shared helpers for runtime tests. Sourced, not executed.

set -u

_test_root_dir() {
    # Path of the directory containing this _helpers.sh file.
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# test_init — create a fresh FORGE_ROOT in a temp dir and source lib.sh.
# Every test script must call this before using lib functions.
test_init() {
    local helpers_dir
    helpers_dir=$(_test_root_dir)
    FORGE_ROOT=$(mktemp -d -t forge-test-XXXXXXXX)
    export FORGE_ROOT
    # shellcheck source=../lib.sh
    . "${helpers_dir}/../lib.sh"
    forge_init || { printf 'test_init: forge_init failed\n' >&2; return 1; }
}

test_cleanup() {
    if [ -n "${FORGE_ROOT:-}" ] && [ -d "$FORGE_ROOT" ]; then
        rm -rf "$FORGE_ROOT"
    fi
}

# assert_eq expected actual [message]
assert_eq() {
    local expected="$1" actual="$2" msg="${3:-assert_eq failed}"
    if [ "$expected" != "$actual" ]; then
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' \
            "$msg" "$expected" "$actual" >&2
        return 1
    fi
    return 0
}

# assert_true: command exits 0
assert_true() {
    local msg="${1:-assert_true failed}"
    shift
    if ! "$@" >/dev/null 2>&1; then
        printf 'FAIL: %s (command: %s)\n' "$msg" "$*" >&2
        return 1
    fi
    return 0
}

# assert_false: command exits non-0
assert_false() {
    local msg="${1:-assert_false failed}"
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'FAIL: %s (command unexpectedly succeeded: %s)\n' "$msg" "$*" >&2
        return 1
    fi
    return 0
}

test_pass() {
    printf 'PASS: %s\n' "${1:-$(basename "$0")}"
}
