#!/usr/bin/env bash
# Tests for scripts/forge-doctor.sh classification and exit codes.
set -u
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCTOR="$ROOT_DIR/scripts/forge-doctor.sh"
P=$(mktemp -d -t forge-doctor-test-XXXXXX); trap 'rm -rf "$P"' EXIT
PASSED=0; FAILED=0
pass() { echo "  ✓ $1"; PASSED=$((PASSED+1)); }
fail() { echo "  ✗ $1: $2"; FAILED=$((FAILED+1)); }
h() { shasum -a 256 "$1" | cut -d' ' -f1; }

echo "═══ forge-doctor tests ═══"
mkdir -p "$P/.claude/rules" "$P/.claude/hooks" "$P/.claude/session"
printf 'rule A\n' > "$P/.claude/rules/_common.md"
printf 'hook B\n' > "$P/.claude/hooks/block-destructive.sh"
printf 'custom\n' > "$P/.claude/rules/my-own.md"
printf 'ephemeral\n' > "$P/.claude/session/last-compact.md"

# no manifest → exit 2
bash "$DOCTOR" "$P" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 2 ] && pass "exit 2 without manifest" || fail "exit without manifest" "got $rc"

cat > "$P/.claude/.forge-manifest.json" <<EOM
{"dotforge_version":"4.8.0","synced_at":"2026-11-04","stacks":[],"files":{
 ".claude/rules/_common.md":{"hash":"sha256:$(h "$P/.claude/rules/_common.md")","source":"template"},
 ".claude/hooks/block-destructive.sh":{"hash":"sha256:deadbeef","source":"template"},
 ".claude/hooks/lint-on-save.sh":{"hash":"sha256:cafebabe","source":"template"}}}
EOM

OUT=$(bash "$DOCTOR" "$P" --json 2>/dev/null); rc=$?
[ "$rc" -eq 1 ] && pass "exit 1 when drifted/missing present" || fail "exit code with drift" "got $rc"
echo "$OUT" | python3 -c "
import json,sys; d=json.load(sys.stdin)
assert d['intact']==['.claude/rules/_common.md'], d
assert d['drifted']==['.claude/hooks/block-destructive.sh'], d
assert d['missing']==['.claude/hooks/lint-on-save.sh'], d
assert d['unmanaged']==['.claude/rules/my-own.md'], d
" && pass "classification intact/drifted/missing/unmanaged" || fail "classification" "$OUT"
echo "$OUT" | grep -q "session/" && fail "session dir excluded" "leaked" || pass "ephemeral session/ excluded from unmanaged"

# repair drift + recreate missing → exit 0
printf 'hook B\n' > "$P/.claude/hooks/block-destructive.sh"
printf 'lint\n' > "$P/.claude/hooks/lint-on-save.sh"
python3 - "$P" <<'PY'
import json,sys,hashlib,os
p=sys.argv[1]; m=json.load(open(f"{p}/.claude/.forge-manifest.json"))
for rel in m["files"]:
    m["files"][rel]["hash"]="sha256:"+hashlib.sha256(open(f"{p}/{rel}","rb").read()).hexdigest()
json.dump(m,open(f"{p}/.claude/.forge-manifest.json","w"))
PY
bash "$DOCTOR" "$P" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && pass "exit 0 when all managed files intact" || fail "exit all intact" "got $rc"
bash "$DOCTOR" "$P" 2>/dev/null | grep -q "intact: 3 · drifted: 0 · missing: 0 · unmanaged: 1" && pass "text summary line" || fail "text summary" "$(bash "$DOCTOR" "$P" 2>/dev/null | head -2)"

echo "Results: $PASSED/$((PASSED+FAILED)) passed"
[ "$FAILED" -eq 0 ]
