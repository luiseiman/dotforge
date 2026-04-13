#!/usr/bin/env bash
# strict halves escalation thresholds, relaxed doubles them.
set -u
. "$(dirname "$0")/_helpers.sh"
trap cli_test_cleanup EXIT

cli_test_init

YAML="${FORGE_BEHAVIORS_DIR}/search-first/behavior.yaml"

# Baseline: [1, 3, 5]
a0=$(yaml_get "$YAML" "policy.enforcement.escalation.0.after")
a1=$(yaml_get "$YAML" "policy.enforcement.escalation.1.after")
a2=$(yaml_get "$YAML" "policy.enforcement.escalation.2.after")
assert_eq "1" "$a0" "initial escalation[0].after" || exit 1
assert_eq "3" "$a1" "initial escalation[1].after" || exit 1
assert_eq "5" "$a2" "initial escalation[2].after" || exit 1

# strict: [1 → max(1, 0)=1, 3 → 1, 5 → 2]
bash "$CLI" strict search-first >/dev/null || { printf 'FAIL: strict\n' >&2; exit 1; }
s0=$(yaml_get "$YAML" "policy.enforcement.escalation.0.after")
s1=$(yaml_get "$YAML" "policy.enforcement.escalation.1.after")
s2=$(yaml_get "$YAML" "policy.enforcement.escalation.2.after")
assert_eq "1" "$s0" "strict: 1 → 1 (floor)" || exit 1
assert_eq "1" "$s1" "strict: 3 → 1" || exit 1
assert_eq "2" "$s2" "strict: 5 → 2" || exit 1

# relaxed (on the already-stricted baseline): [1→2, 1→2, 2→4]
bash "$CLI" relaxed search-first >/dev/null || { printf 'FAIL: relaxed\n' >&2; exit 1; }
r0=$(yaml_get "$YAML" "policy.enforcement.escalation.0.after")
r1=$(yaml_get "$YAML" "policy.enforcement.escalation.1.after")
r2=$(yaml_get "$YAML" "policy.enforcement.escalation.2.after")
assert_eq "2" "$r0" "relaxed: 1 → 2" || exit 1
assert_eq "2" "$r1" "relaxed: 1 → 2" || exit 1
assert_eq "4" "$r2" "relaxed: 2 → 4" || exit 1

# Levels preserved (only `after` changes)
lvl0=$(yaml_get "$YAML" "policy.enforcement.escalation.0.level")
lvl2=$(yaml_get "$YAML" "policy.enforcement.escalation.2.level")
assert_eq '"nudge"' "$lvl0" "level[0] preserved" || exit 1
assert_eq '"soft_block"' "$lvl2" "level[2] preserved" || exit 1

# Unknown behavior id → error
if bash "$CLI" strict nonexistent 2>/dev/null; then
    printf 'FAIL: strict with unknown id should fail\n' >&2
    exit 1
fi

test_pass "test_strict_relaxed"
