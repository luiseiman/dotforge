#!/usr/bin/env bash
# Compile search-first.yaml and verify: file count, naming, syntax, settings snippet.
set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/../../.." && pwd)
. "${REPO_ROOT}/scripts/runtime/tests/_helpers.sh"

trap 'rm -rf "$OUTPUT_DIR"' EXIT

OUTPUT_DIR=$(mktemp -d -t forge-compile-test-XXXXXXXX)

FIXTURE="${SCRIPT_DIR}/fixtures/search-first.yaml"
[ -f "$FIXTURE" ] || { printf 'FAIL: fixture not found\n' >&2; exit 1; }

# Run the compiler
if ! "${REPO_ROOT}/scripts/compiler/compile.sh" "$FIXTURE" "$OUTPUT_DIR" 2>/dev/null; then
    printf 'FAIL: compiler returned non-zero\n' >&2
    exit 1
fi

# Expect: 2 hook files + 1 settings snippet
hook_count=$(find "$OUTPUT_DIR" -name 'search-first__*.sh' | wc -l | tr -d ' ')
assert_eq "2" "$hook_count" "expected 2 hooks for search-first" || exit 1

settings_file="${OUTPUT_DIR}/search-first.settings.json"
[ -f "$settings_file" ] || {
    printf 'FAIL: settings snippet missing: %s\n' "$settings_file" >&2
    exit 1
}

# Expected naming: one for set_flag (Grep|Glob|Read), one for check_flag (Write|Edit)
set_flag_hook=$(find "$OUTPUT_DIR" -name 'search-first__pretooluse__grep-glob-read__*.sh')
check_flag_hook=$(find "$OUTPUT_DIR" -name 'search-first__pretooluse__write-edit__*.sh')

[ -n "$set_flag_hook" ] || {
    printf 'FAIL: set_flag hook not found (expected grep-glob-read slug)\n' >&2
    ls "$OUTPUT_DIR" >&2
    exit 1
}
[ -n "$check_flag_hook" ] || {
    printf 'FAIL: check_flag hook not found (expected write-edit slug)\n' >&2
    exit 1
}

# Both must be executable
[ -x "$set_flag_hook" ] || { printf 'FAIL: set_flag hook not executable\n' >&2; exit 1; }
[ -x "$check_flag_hook" ] || { printf 'FAIL: check_flag hook not executable\n' >&2; exit 1; }

# Both must pass bash syntax check
bash -n "$set_flag_hook" || { printf 'FAIL: set_flag hook syntax error\n' >&2; exit 1; }
bash -n "$check_flag_hook" || { printf 'FAIL: check_flag hook syntax error\n' >&2; exit 1; }

# Set_flag hook must contain forge_flag_set and NOT forge_counter_increment
if ! grep -q 'forge_flag_set' "$set_flag_hook"; then
    printf 'FAIL: set_flag hook missing forge_flag_set call\n' >&2
    exit 1
fi
if grep -q 'forge_counter_increment' "$set_flag_hook"; then
    printf 'FAIL: set_flag hook must not call counter_increment\n' >&2
    exit 1
fi

# Check_flag hook must contain both forge_flag_consume and run_evaluate
if ! grep -q 'forge_flag_consume' "$check_flag_hook"; then
    printf 'FAIL: check_flag hook missing forge_flag_consume call\n' >&2
    exit 1
fi
if ! grep -q 'run_evaluate' "$check_flag_hook"; then
    printf 'FAIL: check_flag hook missing run_evaluate for on_absent: violate\n' >&2
    exit 1
fi

# Settings snippet must be valid JSON with 2 PreToolUse entries
jq -e . "$settings_file" >/dev/null || {
    printf 'FAIL: settings snippet not valid JSON\n' >&2
    exit 1
}
settings_entries=$(jq '.hooks.PreToolUse | length' "$settings_file")
assert_eq "2" "$settings_entries" "settings snippet has 2 PreToolUse entries" || exit 1

# Matcher strings preserved (not slugified) in the settings file
matcher_1=$(jq -r '.hooks.PreToolUse[0].matcher' "$settings_file")
matcher_2=$(jq -r '.hooks.PreToolUse[1].matcher' "$settings_file")
assert_eq "Grep|Glob|Read" "$matcher_1" "first matcher preserved" || exit 1
assert_eq "Write|Edit" "$matcher_2" "second matcher preserved" || exit 1

test_pass "test_compile"
