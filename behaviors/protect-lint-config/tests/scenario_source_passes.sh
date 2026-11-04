#!/usr/bin/env bash
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

for path in \
    "src/app.ts" \
    "README.md" \
    "docs/tsconfig-notes.md" \
    ".eslintrc.json.bak" \
    "pyproject.toml" \
    "config/settings.yaml" \
    "tests/test_eslint_rules.py"
do
    invoke_edit "$path"
    is_empty || fail "edit to source '$path' should pass silently, got: $SCENARIO_STDOUT"
done

pass "scenario_source_passes"
