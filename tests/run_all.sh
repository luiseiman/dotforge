#!/usr/bin/env bash
# Single entry point for every dotforge test suite. Mirrors the CI job so a
# green local run means a green CI run.
#
# Usage: bash tests/run_all.sh [--quick]
#   --quick  skip the v3 behavior scenario suites (slowest)
#
# Needs: bash 3.2+, jq, python3 with PyYAML (macOS /usr/bin/python3 lacks it —
# put /usr/local/bin or a venv first in PATH).
set -u
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
QUICK=false; [ "${1:-}" = "--quick" ] && QUICK=true
FAILED=0; RAN=0

run() {
  local label="$1"; shift
  RAN=$((RAN + 1))
  printf '\n── %s ──\n' "$label"
  if "$@"; then printf '✓ %s\n' "$label"; else printf '✗ %s\n' "$label"; FAILED=$((FAILED + 1)); fi
}

if ! python3 -c 'import yaml' 2>/dev/null; then
  echo "✗ python3 on PATH has no PyYAML (compiler tests and YAML checks need it)" >&2
  exit 1
fi

run "hook syntax"            bash -c 'for f in template/hooks/*.sh .claude/hooks/*.sh .claude/hooks/generated/*.sh stacks/*/hooks/*.sh; do [ -f "$f" ] && bash -n "$f" || exit 1; done'
run "hook permissions"       bash -c 'for f in template/hooks/*.sh .claude/hooks/*.sh; do [ -x "$f" ] || { echo "not executable: $f"; exit 1; }; done'
run "rules lint"             bash tests/lint-rules.sh
run "skills index"           bash tests/test-skills-index.sh
run "hooks behaviour"        bash tests/test-hooks.sh
run "tool-latency hook"      bash tests/test-tool-latency.sh
run "config (self)"          bash tests/test-config.sh .
run "audit engines syntax"   bash -c 'bash -n audit/score.sh && python3 -m py_compile scripts/audit_all.py'
run "templates JSON"         python3 -c 'import json; [json.load(open(f)) for f in ("template/settings.json.tmpl","global/settings.json.tmpl",".claude-plugin/plugin.json",".claude-plugin/marketplace.json")]'
run "workflows YAML"         python3 -c 'import yaml,glob; [yaml.safe_load(open(f)) for f in glob.glob(".github/workflows/*.yml")+["behaviors/index.yaml","registry/projects.yml"]]'
run "v3 runtime"             bash scripts/runtime/tests/run_all.sh
run "v3 compiler"            bash scripts/compiler/tests/run_all.sh
run "v3 behavior CLI"        bash scripts/forge-behavior/tests/run_all.sh
if ! $QUICK; then
  for d in behaviors/*/tests/run_all.sh; do
    [ -f "$d" ] || continue
    run "behavior $(basename "$(dirname "$(dirname "$d")")")" bash "$d"
  done
fi

printf '\n═══ %d suites, %d failed ═══\n' "$RAN" "$FAILED"
[ "$FAILED" -eq 0 ]
