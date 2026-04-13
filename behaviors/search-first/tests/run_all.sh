#!/usr/bin/env bash
# Runner for all search-first end-to-end scenarios.
set -u
cd "$(dirname "$0")"

scenarios=(
    scenario_flag_happy_path.sh
    scenario_idempotent_set.sh
    scenario_alternating.sh
    scenario_escalation.sh
    scenario_override_reinvocation.sh
)

pass=0
fail=0
failed_names=()

for s in "${scenarios[@]}"; do
    if bash "$s"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        failed_names+=("$s")
    fi
done

printf '\n----------\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
    printf 'Failed: %s\n' "${failed_names[*]}"
    exit 1
fi
exit 0
