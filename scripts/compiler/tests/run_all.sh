#!/usr/bin/env bash
# Runner for all compiler tests.
set -u
cd "$(dirname "$0")"

tests=(
    test_compile.sh
)

pass=0
fail=0
failed_names=()

for t in "${tests[@]}"; do
    if bash "$t"; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        failed_names+=("$t")
    fi
done

printf '\n----------\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
    printf 'Failed: %s\n' "${failed_names[*]}"
    exit 1
fi
exit 0
