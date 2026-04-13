#!/usr/bin/env bash
# Non-source file writes (md, json, yaml) are exempt — conditions don't match.
set -u
. "$(dirname "$0")/_helpers.sh"
trap scenario_cleanup EXIT

scenario_init || exit 1

invoke_write "README.md"
invoke_write "package.json"
invoke_write "config.yaml"
invoke_write "notes.txt"
[ "$(counter)" = "0" ] || fail "non-source writes should not count, got $(counter)"

pass "scenario_non_source_exempt"
