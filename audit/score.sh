#!/usr/bin/env bash
# audit/score.sh — Standalone mechanical audit of dotforge configuration
# Requires: bash 3.2+, python3 (for JSON output and JSON validation)
#
# Usage: ./audit/score.sh [PROJECT_DIR] [--json] [--threshold N]
#
# Computes the 12-item checklist mechanically without Claude.
# Semantic checks (CLAUDE.md quality, rule content) are approximated with heuristics.
# Score is indicative — /forge audit provides authoritative semantic evaluation.
#
# Exit codes:
#   0 — audit complete
#   1 — PROJECT_DIR not found
#   2 — threshold set and score < threshold (CI gate)

set -uo pipefail

# --- Parse arguments ---
PROJECT_DIR="$(pwd)"
OUTPUT_JSON=false
THRESHOLD=""

for arg in "$@"; do
  case "$arg" in
    --json)           OUTPUT_JSON=true ;;
    --threshold=*)    THRESHOLD="${arg#*=}" ;;
    --*)              ;;   # ignore unknown flags
    *)                PROJECT_DIR="$arg" ;;
  esac
done

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "ERROR: Directory not found: $PROJECT_DIR" >&2
  exit 1
fi

cd "$PROJECT_DIR"

# --- Score variables (s1..s12) and notes (n1..n12) ---
s1=0; n1=""; s2=0; n2=""; s3=0; n3=""; s4=0; n4=""; s5=0; n5=""
s6=0; n6=""; s7=0; n7=""; s8=0; n8=""; s9=0; n9=""; s10=0; n10=""
s11=0; n11=""; s12=0; n12=""

# ─────────────────────────────────────────────────────────────────────────────
# OBLIGATORIO (each 0-2)
# ─────────────────────────────────────────────────────────────────────────────

# 1. CLAUDE.md
if [[ ! -f "CLAUDE.md" ]]; then
  s1=0; n1="CLAUDE.md not found"
else
  USEFUL=$(grep -v '^\s*$' CLAUDE.md | grep -v '^\s*<!--' | wc -l | tr -d ' ')
  HS=0; HB=0; HA=0; HC=0
  grep -qiE '(python|fastapi|react|vite|swift|swiftui|node|express|go|java|spring|docker|supabase|redis|typescript|javascript)' CLAUDE.md && HS=1
  grep -qE  '(npm (run|test|build)|pytest|go test|cargo test|mvn|gradle|make test|ruff|eslint|swiftlint|swift test|python -m|uvicorn|poetry run)' CLAUDE.md && HB=1
  grep -qiE '(src/|architecture|structure|components?|modules?|services?|[├└]|`[a-z]+/)' CLAUDE.md && HA=1
  grep -qiE '(convention|pattern|rule|style|format|naming|never|always|prefer|avoid)' CLAUDE.md && HC=1
  SSUM=$((HS + HB + HA + HC))
  if   [[ $USEFUL -lt 15 ]];    then s1=0; n1="Too short (${USEFUL} useful lines)"
  elif [[ $SSUM  -ge 3  ]];     then s1=2; n1="Complete (stack:${HS} build:${HB} arch:${HA} conventions:${HC})"
  else                               s1=1; n1="Incomplete sections (stack:${HS} build:${HB} arch:${HA} conventions:${HC})"
  fi
fi

# 2. .claude/settings.json
SETTINGS=".claude/settings.json"
if [[ ! -f "$SETTINGS" ]]; then
  s2=0; n2="settings.json not found"
elif ! python3 -c "import json; json.load(open('$SETTINGS'))" 2>/dev/null; then
  s2=0; n2="settings.json is invalid JSON"
else
  HE=$(grep -c '\.env'        "$SETTINGS" 2>/dev/null)
  HK=$(grep -c '\.key'        "$SETTINGS" 2>/dev/null)
  HP=$(grep -c '\.pem'        "$SETTINGS" 2>/dev/null)
  HR=$(grep -c 'credentials'  "$SETTINGS" 2>/dev/null)
  HB=$(grep -c '"Bash(\*)"'   "$SETTINGS" 2>/dev/null)
  DC=$((HE + HK + HP + HR))
  if   [[ $DC -ge 3 && $HB -eq 0 ]]; then s2=2; n2="Deny list covers .env/key/pem/credentials"
  elif [[ $DC -ge 1 ]];               then s2=1; n2="Partial deny list (.env:${HE} .key:${HK} .pem:${HP} credentials:${HR})"
  else                                     s2=1; n2="settings.json exists but no deny list detected"
  fi
fi

# 3. Rules with globs
RULES_DIR=".claude/rules"
if [[ ! -d "$RULES_DIR" ]] || [[ -z "$(ls "$RULES_DIR"/*.md 2>/dev/null)" ]]; then
  s3=0; n3=".claude/rules/ empty or absent"
else
  TR=0; RG=0
  for f in "$RULES_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    TR=$((TR+1))
    grep -q '^globs:' "$f" && RG=$((RG+1))
  done
  if   [[ $RG -eq 0 ]];        then s3=1; n3="${TR} rules but none have globs: frontmatter"
  elif [[ $RG -lt $TR ]];      then s3=1; n3="${RG}/${TR} rules have globs:"
  else                              s3=2; n3="${TR} rules, all with globs:"
  fi
fi

# 4. block-destructive hook
HOOK_BD=".claude/hooks/block-destructive.sh"
if [[ ! -f "$HOOK_BD" ]]; then
  s4=0; n4="block-destructive.sh not found"
else
  IE=0; IW=0; IP=0
  [[ -x "$HOOK_BD" ]] && IE=1
  [[ -f "$SETTINGS" ]] && grep -q 'block-destructive' "$SETTINGS" 2>/dev/null && IW=1
  grep -q 'rm -rf' "$HOOK_BD" && grep -qiE '(DROP|drop)' "$HOOK_BD" && grep -q 'force' "$HOOK_BD" && IP=1
  if   [[ $IE -eq 1 && $IW -eq 1 && $IP -eq 1 ]]; then s4=2; n4="Executable, wired, covers rm/DROP/force"
  elif [[ $IE -eq 1 && $IW -eq 1 ]];               then s4=1; n4="Wired but incomplete patterns (exec:${IE} wired:${IW} patterns:${IP})"
  else                                                   s4=1; n4="Exists but not fully configured (exec:${IE} wired:${IW} patterns:${IP})"
  fi
fi

# 5. Build/test commands in CLAUDE.md
if [[ ! -f "CLAUDE.md" ]]; then
  s5=0; n5="CLAUDE.md not found"
else
  HT=0; HB2=0
  grep -qiE '(pytest|npm test|go test|cargo test|swift test|mvn test|gradle test|make test|vitest|jest)' CLAUDE.md && HT=1
  grep -qiE '(npm run build|go build|cargo build|mvn package|gradle build|docker build|make build|ruff check|tsc )' CLAUDE.md && HB2=1
  if   [[ $HT -eq 1 && $HB2 -eq 1 ]]; then s5=2; n5="Both build and test commands documented"
  elif [[ $HT -eq 1 || $HB2 -eq 1 ]]; then s5=1; n5="Partial (build:${HB2} test:${HT})"
  else
    grep -qE '`[a-z].*`|```bash|```sh' CLAUDE.md && s5=1 && n5="Commands present but no build/test pattern detected" || { s5=0; n5="No runnable commands found in CLAUDE.md"; }
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# RECOMENDADO (each 0-1)
# ─────────────────────────────────────────────────────────────────────────────

# 6. CLAUDE_ERRORS.md
if [[ ! -f "CLAUDE_ERRORS.md" ]]; then
  s6=0; n6="CLAUDE_ERRORS.md not found"
elif grep -qE '\| *Type *\||\| *Tipo *\|' "CLAUDE_ERRORS.md"; then
  s6=1; n6="Present with Type column"
else
  s6=1; n6="Present but missing Type column"
fi

# 7. Lint hook
HOOK_LINT=".claude/hooks/lint-on-save.sh"
if   [[ -f "$HOOK_LINT" && -x "$HOOK_LINT" ]]; then s7=1; n7="lint-on-save.sh present and executable"
elif [[ -f "$HOOK_LINT" ]];                        then s7=1; n7="lint-on-save.sh present but not executable"
else                                                    s7=0; n7="lint-on-save.sh not found"
fi

# 8. Custom commands
CMD_DIR=".claude/commands"
if [[ -d "$CMD_DIR" ]] && [[ -n "$(ls "$CMD_DIR"/*.md 2>/dev/null)" ]]; then
  CC=$(ls "$CMD_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  s8=1; n8="${CC} custom command(s)"
else
  s8=0; n8=".claude/commands/ absent or empty"
fi

# 9. Project memory
if   [[ -d ".claude/agent-memory" ]] && [[ -n "$(ls ".claude/agent-memory" 2>/dev/null)" ]]; then
  s9=1; n9="agent-memory/ present"
elif [[ -f ".claude/MEMORY.md" ]]; then
  s9=1; n9="MEMORY.md present"
else
  s9=0; n9="No project memory found"
fi

# 10. Agents + orchestration
HA2=0; HR2=0
[[ -d ".claude/agents" ]] && [[ -n "$(ls .claude/agents/*.md 2>/dev/null)" ]] && HA2=1
[[ -f ".claude/rules/agents.md" ]] && HR2=1
if   [[ $HA2 -eq 1 && $HR2 -eq 1 ]]; then
  AC=$(ls .claude/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
  s10=1; n10="${AC} agents + agents.md rule"
elif [[ $HA2 -eq 1 || $HR2 -eq 1 ]]; then s10=1; n10="Partial (agents:${HA2} rule:${HR2})"
else                                        s10=0; n10="No agents or orchestration rule"
fi

# 11. .gitignore
if [[ ! -f ".gitignore" ]]; then
  s11=0; n11=".gitignore not found"
else
  GE=$(grep -cE '^\.env$|^\.env\b' .gitignore 2>/dev/null)
  GK=$(grep -c  '\.key'             .gitignore 2>/dev/null)
  GP=$(grep -c  '\.pem'             .gitignore 2>/dev/null)
  GR=$(grep -cE '(credentials|secret)' .gitignore 2>/dev/null)
  GC=$((GE + GK + GP + GR))
  if [[ $GC -ge 2 ]]; then s11=1; n11="Covers secrets (${GC}/4 patterns)"
  else                     s11=0; n11="Weak secret protection (${GC}/4 patterns)"
  fi
fi

# 12. Prompt injection scan
SCAN_FOUND=""
SCAN_COUNT=0
for f in CLAUDE.md .claude/rules/*.md .claude/*.md; do
  [[ -f "$f" ]] || continue
  SCAN_COUNT=$((SCAN_COUNT+1))
  MATCH=$(grep -niE \
    'ignore (all |previous |above )?(instructions|rules)|system:|<system>|</system>|<instructions>|IGNORE ALL|disregard (all |previous )?instructions|override instructions|you are now|forget (all |everything|previous)|base64:[A-Za-z0-9+/]{40}' \
    "$f" 2>/dev/null | head -2 || true)
  [[ -n "$MATCH" ]] && SCAN_FOUND="${SCAN_FOUND} ${f}"
done
if [[ -n "$SCAN_FOUND" ]]; then
  s12=0; n12="⚠ Suspicious patterns in:${SCAN_FOUND}"
else
  s12=1; n12="Clean (${SCAN_COUNT} files scanned)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Calculate score
# ─────────────────────────────────────────────────────────────────────────────
SCORE_OBL=$((s1 + s2 + s3 + s4 + s5))
SCORE_REC=$((s6 + s7 + s8 + s9 + s10 + s11 + s12))

SCORE_TOTAL=$(awk "BEGIN { printf \"%.2f\", ${SCORE_OBL} * 0.7 + ${SCORE_REC} * (3.0 / 7) }")

SECURITY_CAP=false
if [[ $s2 -eq 0 || $s4 -eq 0 ]]; then
  SECURITY_CAP=true
  SCORE_TOTAL=$(awk "BEGIN { v=${SCORE_TOTAL}; printf \"%.2f\", (v > 6.0 ? 6.0 : v) }")
fi

LEVEL=$(awk "BEGIN {
  s = ${SCORE_TOTAL}
  if      (s >= 9) print \"Excelente\"
  else if (s >= 7) print \"Bueno\"
  else if (s >= 5) print \"Aceptable\"
  else if (s >= 3) print \"Deficiente\"
  else             print \"Critico\"
}")

# ─────────────────────────────────────────────────────────────────────────────
# Output
# ─────────────────────────────────────────────────────────────────────────────
CAP_STR="false"
$SECURITY_CAP && CAP_STR="true"

if $OUTPUT_JSON; then
  python3 - <<PYEOF
import json, sys
data = {
  "score": float("${SCORE_TOTAL}"),
  "level": "${LEVEL}",
  "security_cap": ${CAP_STR},
  "score_obligatorio": ${SCORE_OBL},
  "score_recomendado": ${SCORE_REC},
  "items": {
    "1_claude_md":         {"score": ${s1},  "note": """${n1}"""},
    "2_settings_json":     {"score": ${s2},  "note": """${n2}"""},
    "3_rules":             {"score": ${s3},  "note": """${n3}"""},
    "4_block_destructive": {"score": ${s4},  "note": """${n4}"""},
    "5_build_test":        {"score": ${s5},  "note": """${n5}"""},
    "6_errors_md":         {"score": ${s6},  "note": """${n6}"""},
    "7_lint_hook":         {"score": ${s7},  "note": """${n7}"""},
    "8_commands":          {"score": ${s8},  "note": """${n8}"""},
    "9_memory":            {"score": ${s9},  "note": """${n9}"""},
    "10_agents":           {"score": ${s10}, "note": """${n10}"""},
    "11_gitignore":        {"score": ${s11}, "note": """${n11}"""},
    "12_injection":        {"score": ${s12}, "note": """${n12}"""}
  }
}
print(json.dumps(data, indent=2))
PYEOF
else
  CAP_NOTE=""
  $SECURITY_CAP && CAP_NOTE="  ⚠ security cap applied (settings.json or block-destructive missing)"
  echo "═══ AUDIT SCORE: $(basename "$PROJECT_DIR") ═══"
  echo "Score: ${SCORE_TOTAL}/10  (${LEVEL})${CAP_NOTE}"
  echo ""
  echo "── OBLIGATORIO (${SCORE_OBL}/10) ──"
  printf "  [%s] 1.  CLAUDE.md            %s\n" "$s1"  "$n1"
  printf "  [%s] 2.  settings.json        %s\n" "$s2"  "$n2"
  printf "  [%s] 3.  Rules                %s\n" "$s3"  "$n3"
  printf "  [%s] 4.  block-destructive    %s\n" "$s4"  "$n4"
  printf "  [%s] 5.  Build/test commands  %s\n" "$s5"  "$n5"
  echo ""
  echo "── RECOMENDADO (${SCORE_REC}/7) ──"
  printf "  [%s] 6.  CLAUDE_ERRORS.md     %s\n" "$s6"  "$n6"
  printf "  [%s] 7.  Lint hook            %s\n" "$s7"  "$n7"
  printf "  [%s] 8.  Custom commands      %s\n" "$s8"  "$n8"
  printf "  [%s] 9.  Memory               %s\n" "$s9"  "$n9"
  printf "  [%s] 10. Agents               %s\n" "$s10" "$n10"
  printf "  [%s] 11. .gitignore           %s\n" "$s11" "$n11"
  printf "  [%s] 12. Injection scan       %s\n" "$s12" "$n12"
fi

# CI threshold gate
if [[ -n "$THRESHOLD" ]]; then
  BELOW=$(awk "BEGIN { print (${SCORE_TOTAL} < ${THRESHOLD}) ? 1 : 0 }")
  if [[ "$BELOW" == "1" ]]; then
    echo "" >&2
    echo "FAIL: score ${SCORE_TOTAL} is below threshold ${THRESHOLD}" >&2
    exit 2
  fi
fi

exit 0
