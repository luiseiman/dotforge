#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
pass=0; fail=0
for t in scenario_*.sh; do
    if bash "$t"; then pass=$((pass+1)); else fail=$((fail+1)); fi
done
echo "----------"
echo "${pass} passed, ${fail} failed"
[ "$fail" -eq 0 ]
