#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

# Distinct paths: a soft_block records a pending_block per tool_input hash and
# the identical reinvocation would pass as an override (see scenario_override).
for path in \
    ".eslintrc.json" \
    "packages/api/eslint.config.mjs" \
    "/repo/.prettierrc.yaml" \
    "tsconfig.build.json" \
    "ruff.toml" \
    "backend/.flake8" \
    ".pre-commit-config.yaml" \
    "ios/.swiftlint.yml" \
    ".golangci.yaml" \
    "commitlint.config.cjs"
do
    invoke_edit "$path"
    is_deny || fail "edit to config '$path' should be blocked, got: $SCENARIO_STDOUT"
    has_reason || fail "deny for '$path' must carry permissionDecisionReason"
done

invoke_edit "biome.json" "Write"
is_deny || fail "Write to biome.json should be blocked"

pass "scenario_config_blocked"
