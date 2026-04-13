#!/usr/bin/env bash
# audit/score.sh — Standalone mechanical audit of dotforge configuration
# Requires: bash 3.2+, python3 (for JSON output and JSON validation)
#
# Usage: ./audit/score.sh [PROJECT_DIR] [--json] [--threshold N]
#
# Computes the 15-item checklist mechanically without Claude.
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

# --- Score variables (s1..s15) and notes (n1..n15) ---
s1=0; n1=""; s2=0; n2=""; s3=0; n3=""; s4=0; n4=""; s5=0; n5=""
s6=0; n6=""; s7=0; n7=""; s8=0; n8=""; s9=0; n9=""; s10=0; n10=""
s11=0; n11=""; s12=0; n12=""; s13=0; n13=""; s14=0; n14=""; s15=0; n15=""

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

# 7. Lint hook (any lint hook: lint-on-save, lint-python, lint-ts, lint-swift, etc.)
LINT_FOUND=""
for lf in .claude/hooks/lint-*.sh; do
  [[ -f "$lf" ]] && LINT_FOUND="$lf" && break
done
if   [[ -n "$LINT_FOUND" && -x "$LINT_FOUND" ]]; then s7=1; n7="$(basename "$LINT_FOUND") present and executable"
elif [[ -n "$LINT_FOUND" ]];                        then s7=1; n7="$(basename "$LINT_FOUND") present but not executable"
else                                                     s7=0; n7="No lint hook found (lint-*.sh)"
fi

# 8. Custom commands
CMD_DIR=".claude/commands"
if [[ -d "$CMD_DIR" ]] && [[ -n "$(ls "$CMD_DIR"/*.md 2>/dev/null)" ]]; then
  CC=$(ls "$CMD_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  s8=1; n8="${CC} custom command(s)"
else
  s8=0; n8=".claude/commands/ absent or empty"
fi

# 9. Project memory (agent-memory with real content, or MEMORY.md)
MEM_FILES=$(find .claude/agent-memory -name "*.md" -not -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
if   [[ "$MEM_FILES" -gt 0 ]]; then
  s9=1; n9="agent-memory/ with ${MEM_FILES} file(s)"
elif [[ -d ".claude/agent-memory" ]]; then
  s9=1; n9="agent-memory/ initialized (no content yet)"
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
    'ignore (all |previous |above )?(instructions|rules)|system:|<system>|</system>|<instructions>.*</instructions>|IGNORE ALL|disregard (all |previous )?instructions|override instructions|you are now|forget (all |everything|previous)|base64:[A-Za-z0-9+/]{40}' \
    "$f" 2>/dev/null | head -2 || true)
  [[ -n "$MATCH" ]] && SCAN_FOUND="${SCAN_FOUND} ${f}"
done
if [[ -n "$SCAN_FOUND" ]]; then
  s12=0; n12="⚠ Suspicious patterns in:${SCAN_FOUND}"
else
  s12=1; n12="Clean (${SCAN_COUNT} files scanned)"
fi

# 13. Auto mode safety
if [[ ! -f "$SETTINGS" ]]; then
  s13=1; n13="settings.json not found — auto mode not enabled (pass)"
elif ! grep -q '"defaultMode"' "$SETTINGS" 2>/dev/null; then
  s13=1; n13="defaultMode not set — auto mode not enabled (pass)"
elif ! grep -q '"auto"' "$SETTINGS" 2>/dev/null; then
  s13=1; n13="defaultMode present but not auto (pass)"
else
  # Auto mode is enabled — check deny list covers secrets
  HE=$(grep -c '\.env'        "$SETTINGS" 2>/dev/null)
  HK=$(grep -c '\.key'        "$SETTINGS" 2>/dev/null)
  HP=$(grep -c '\.pem'        "$SETTINGS" 2>/dev/null)
  HR=$(grep -c 'credentials'  "$SETTINGS" 2>/dev/null)
  DC=$((HE + HK + HP + HR))
  if [[ $DC -ge 3 ]]; then s13=1; n13="Auto mode enabled WITH deny list covering secrets (${DC}/4)"
  else                      s13=0; n13="Auto mode enabled WITHOUT complete deny list (.env:${HE} .key:${HK} .pem:${HP} credentials:${HR})"
  fi
fi

# 14. Behaviors coverage (v3 — behavior governance)
# Pass if project has at least one compiled behavior hook OR a behaviors/index.yaml
# with at least one enabled behavior.
s14=0; n14="No v3 behaviors detected"
if [[ -f "behaviors/index.yaml" ]]; then
  BH_ENABLED=$(python3 -c "
import yaml, sys
try:
    d = yaml.safe_load(open('behaviors/index.yaml')) or {}
    n = sum(1 for b in (d.get('behaviors') or []) if b.get('enabled', True))
    print(n)
except Exception:
    print(0)
" 2>/dev/null)
  if [[ "${BH_ENABLED:-0}" -gt 0 ]]; then
    s14=1; n14="${BH_ENABLED} behaviors enabled in behaviors/index.yaml"
  fi
elif ls .claude/hooks/generated/*__pretooluse__*.sh >/dev/null 2>&1; then
  BH_COUNT=$(ls .claude/hooks/generated/*__pretooluse__*.sh 2>/dev/null | wc -l | tr -d ' ')
  s14=1; n14="${BH_COUNT} compiled behavior hooks in .claude/hooks/generated/"
elif [[ -f "$SETTINGS" ]] && grep -qE '(behaviors|__pretooluse__)' "$SETTINGS" 2>/dev/null; then
  s14=1; n14="behavior hook references present in settings.json"
fi

# 15. OS-level sandboxing
SANDBOX_STATE="off"
if [[ -f "$SETTINGS" ]]; then
  SANDBOX_STATE=$(python3 -c "
import json
try:
    d = json.load(open('$SETTINGS'))
    sb = d.get('sandbox') or {}
    if sb.get('enabled') is True:
        fs = sb.get('filesystem') or {}
        net = sb.get('network') or {}
        if fs.get('denyRead') or fs.get('denyWrite') or net.get('allowedDomains'):
            print('on_restricted')
        else:
            print('on_permissive')
    else:
        print('off')
except Exception:
    print('off')
" 2>/dev/null)
fi

HANDLES_SECRETS=0
SECRET_REASON=""
if ls .env .env.* 2>/dev/null | grep -vE '\.(example|sample|template)$' >/dev/null 2>&1; then
  HANDLES_SECRETS=1; SECRET_REASON=".env files present"
elif find . -maxdepth 3 -type f \( -name '*.key' -o -name '*.pem' -o -name 'credentials*' \) -not -path './node_modules/*' -not -path './.git/*' 2>/dev/null | head -1 | grep -q .; then
  HANDLES_SECRETS=1; SECRET_REASON="key/pem/credentials files detected"
elif grep -rqE '(gcloud|aws configure|kubectl apply|firebase login|openai|anthropic|supabase)' --include='*.sh' --include='*.md' --include='*.env' --include='*.yaml' . 2>/dev/null; then
  HANDLES_SECRETS=1; SECRET_REASON="cloud/API refs in scripts or docs"
fi

case "$SANDBOX_STATE" in
  on_restricted)
    s15=1; n15="sandbox.enabled with filesystem/network restrictions" ;;
  on_permissive)
    s15=0; n15="sandbox.enabled but no filesystem/network restrictions configured" ;;
  off)
    if [[ $HANDLES_SECRETS -eq 0 ]]; then
      s15=1; n15="No secrets detected — sandboxing not required (auto-pass)"
    else
      s15=0; n15="Project handles secrets (${SECRET_REASON}) but sandbox.enabled is not true"
    fi
    ;;
esac

# ─────────────────────────────────────────────────────────────────────────────
# Calculate score
# ─────────────────────────────────────────────────────────────────────────────
SCORE_OBL=$((s1 + s2 + s3 + s4 + s5))
SCORE_REC=$((s6 + s7 + s8 + s9 + s10 + s11 + s12 + s13 + s14 + s15))

SCORE_TOTAL=$(awk "BEGIN { printf \"%.2f\", ${SCORE_OBL} * 0.7 + ${SCORE_REC} * (3.0 / 10) }")

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
CAP_STR="False"
$SECURITY_CAP && CAP_STR="True"

# Sanitize notes for safe Python string interpolation
_san() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '; }

if $OUTPUT_JSON; then
  python3 - <<PYEOF
import json
data = {
  "score": float("${SCORE_TOTAL}"),
  "level": "${LEVEL}",
  "security_cap": ${CAP_STR},
  "score_obligatorio": ${SCORE_OBL},
  "score_recomendado": ${SCORE_REC},
  "items": {
    "1_claude_md":         {"score": ${s1},  "note": "$(_san "$n1")"},
    "2_settings_json":     {"score": ${s2},  "note": "$(_san "$n2")"},
    "3_rules":             {"score": ${s3},  "note": "$(_san "$n3")"},
    "4_block_destructive": {"score": ${s4},  "note": "$(_san "$n4")"},
    "5_build_test":        {"score": ${s5},  "note": "$(_san "$n5")"},
    "6_errors_md":         {"score": ${s6},  "note": "$(_san "$n6")"},
    "7_lint_hook":         {"score": ${s7},  "note": "$(_san "$n7")"},
    "8_commands":          {"score": ${s8},  "note": "$(_san "$n8")"},
    "9_memory":            {"score": ${s9},  "note": "$(_san "$n9")"},
    "10_agents":           {"score": ${s10}, "note": "$(_san "$n10")"},
    "11_gitignore":        {"score": ${s11}, "note": "$(_san "$n11")"},
    "12_injection":        {"score": ${s12}, "note": "$(_san "$n12")"},
    "13_auto_mode":        {"score": ${s13}, "note": "$(_san "$n13")"},
    "14_behaviors":        {"score": ${s14}, "note": "$(_san "$n14")"},
    "15_sandboxing":       {"score": ${s15}, "note": "$(_san "$n15")"}
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
  echo "── RECOMENDADO (${SCORE_REC}/10) ──"
  printf "  [%s] 6.  CLAUDE_ERRORS.md     %s\n" "$s6"  "$n6"
  printf "  [%s] 7.  Lint hook            %s\n" "$s7"  "$n7"
  printf "  [%s] 8.  Custom commands      %s\n" "$s8"  "$n8"
  printf "  [%s] 9.  Memory               %s\n" "$s9"  "$n9"
  printf "  [%s] 10. Agents               %s\n" "$s10" "$n10"
  printf "  [%s] 11. .gitignore           %s\n" "$s11" "$n11"
  printf "  [%s] 12. Injection scan       %s\n" "$s12" "$n12"
  printf "  [%s] 13. Auto mode safety     %s\n" "$s13" "$n13"
  printf "  [%s] 14. Behaviors coverage   %s\n" "$s14" "$n14"
  printf "  [%s] 15. Sandboxing           %s\n" "$s15" "$n15"
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
