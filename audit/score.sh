#!/usr/bin/env bash
# audit/score.sh — Standalone mechanical audit of dotforge configuration
# Requires: bash 3.2+, python3 (for JSON output and JSON validation)
#
# Usage: ./audit/score.sh [PROJECT_DIR] [--json] [--threshold N]
#
# Two-dimension model (v4.x — see audit/checklist.md + audit/scoring.md):
#   Dimension A — Native Health: 5 obligatory (0-2) + 10 recommended (0-1).
#                 score = obl*0.7 + rec*0.3, security cap 6.0. The CI gate.
#   Dimension B — dotforge Adoption: 4 items (0-1). Informational, 0-4.
#                 Does NOT affect Native Health.
# Semantic checks (CLAUDE.md quality, rule content) are approximated with heuristics.
# Score is indicative — /forge audit provides authoritative semantic evaluation.
#
# Exit codes:
#   0 — audit complete
#   1 — PROJECT_DIR not found
#   2 — threshold set and native_health < threshold (CI gate)

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

# --- Dimension A: scores (s1..s15) and notes (n1..n15) ---
s1=0; n1=""; s2=0; n2=""; s3=0; n3=""; s4=0; n4=""; s5=0; n5=""
s6=0; n6=""; s7=0; n7=""; s8=0; n8=""; s9=0; n9=""; s10=0; n10=""
s11=0; n11=""; s12=0; n12=""; s13=0; n13=""; s14=0; n14=""; s15=0; n15=""
# --- Dimension B: scores (b1..b4) and notes (m1..m4) ---
b1=0; m1=""; b2=0; m2=""; b3=0; m3=""; b4=0; m4=""

# ─────────────────────────────────────────────────────────────────────────────
# DIMENSION A — OBLIGATORIO (each 0-2)
# ─────────────────────────────────────────────────────────────────────────────

# 1. Project instructions — CLAUDE.md, or AGENTS.md when Claude Code loads it natively (v2.1.277+)
#    Evaluate the file(s) Claude actually reads: CLAUDE.md (+ AGENTS.md if imported via "@AGENTS.md"),
#    or AGENTS.md alone when there is no CLAUDE.md. A CLAUDE.md symlink to AGENTS.md counts as CLAUDE.md.
INSTR_FILES=""; INSTR_NOTE=""; INSTR_TEXT=""
if [[ -f "CLAUDE.md" ]]; then
  INSTR_FILES="CLAUDE.md"
  if [[ -f "AGENTS.md" ]]; then
    if grep -qE '^@(\./)?AGENTS\.md[[:space:]]*$' CLAUDE.md 2>/dev/null; then
      INSTR_FILES="CLAUDE.md AGENTS.md"
    elif [[ -L "CLAUDE.md" ]]; then
      INSTR_NOTE=" (CLAUDE.md is a symlink to AGENTS.md)"
    else
      INSTR_NOTE=" ⚠ AGENTS.md present but not imported — ignored by Claude Code, copies may drift"
    fi
  fi
elif [[ -f "AGENTS.md" ]]; then
  INSTR_FILES="AGENTS.md"
  INSTR_NOTE=" (AGENTS.md read natively, no CLAUDE.md)"
fi
if [[ -z "$INSTR_FILES" ]]; then
  s1=0; n1="No CLAUDE.md or AGENTS.md found"
else
  INSTR_TEXT=$(cat $INSTR_FILES 2>/dev/null)
  USEFUL=$(printf '%s\n' "$INSTR_TEXT" | grep -v '^\s*$' | grep -v '^\s*<!--' | wc -l | tr -d ' ')
  HS=0; HB=0; HA=0; HC=0
  printf '%s\n' "$INSTR_TEXT" | grep -qiE '(python|fastapi|react|vite|swift|swiftui|node|express|go|java|spring|docker|supabase|redis|typescript|javascript)' && HS=1
  printf '%s\n' "$INSTR_TEXT" | grep -qE  '(npm (run|test|build)|pytest|go test|cargo test|mvn|gradle|make test|ruff|eslint|swiftlint|swift test|python -m|uvicorn|poetry run)' && HB=1
  printf '%s\n' "$INSTR_TEXT" | grep -qiE '(src/|architecture|structure|components?|modules?|services?|[├└]|`[a-z]+/)' && HA=1
  printf '%s\n' "$INSTR_TEXT" | grep -qiE '(convention|pattern|rule|style|format|naming|never|always|prefer|avoid)' && HC=1
  SSUM=$((HS + HB + HA + HC))
  if   [[ $USEFUL -lt 15 ]];    then s1=0; n1="Too short (${USEFUL} useful lines in ${INSTR_FILES})${INSTR_NOTE}"
  elif [[ $SSUM  -ge 3  ]];     then s1=2; n1="Complete (stack:${HS} build:${HB} arch:${HA} conventions:${HC}; ${INSTR_FILES})${INSTR_NOTE}"
  else                               s1=1; n1="Incomplete sections (stack:${HS} build:${HB} arch:${HA} conventions:${HC}; ${INSTR_FILES})${INSTR_NOTE}"
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

# 5. Build/test commands in the instruction file (same file set as item 1)
if [[ -z "$INSTR_FILES" ]]; then
  s5=0; n5="No CLAUDE.md or AGENTS.md found"
else
  HT=0; HB2=0
  printf '%s\n' "$INSTR_TEXT" | grep -qiE '(pytest|npm test|go test|cargo test|swift test|mvn test|gradle test|make test|vitest|jest)' && HT=1
  printf '%s\n' "$INSTR_TEXT" | grep -qiE '(npm run build|go build|cargo build|mvn package|gradle build|docker build|make build|ruff check|tsc )' && HB2=1
  if   [[ $HT -eq 1 && $HB2 -eq 1 ]]; then s5=2; n5="Both build and test commands documented (${INSTR_FILES})"
  elif [[ $HT -eq 1 || $HB2 -eq 1 ]]; then s5=1; n5="Partial (build:${HB2} test:${HT}; ${INSTR_FILES})"
  else
    printf '%s\n' "$INSTR_TEXT" | grep -qE '`[a-z].*`|```bash|```sh' && s5=1 && n5="Commands present but no build/test pattern detected" || { s5=0; n5="No runnable commands found in ${INSTR_FILES}"; }
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
# DIMENSION A — RECOMENDADO (each 0-1) — native Claude Code usage
# ─────────────────────────────────────────────────────────────────────────────

# 6. .gitignore protects secrets
if [[ ! -f ".gitignore" ]]; then
  s6=0; n6=".gitignore not found"
else
  GE=$(grep -cE '^\.env$|^\.env\b' .gitignore 2>/dev/null)
  GK=$(grep -c  '\.key'             .gitignore 2>/dev/null)
  GP=$(grep -c  '\.pem'             .gitignore 2>/dev/null)
  GR=$(grep -cE '(credentials|secret)' .gitignore 2>/dev/null)
  GC=$((GE + GK + GP + GR))
  if [[ $GC -ge 2 ]]; then s6=1; n6="Covers secrets (${GC}/4 patterns)"
  else                     s6=0; n6="Weak secret protection (${GC}/4 patterns)"
  fi
fi

# 7. Prompt injection scan
SCAN_FOUND=""
SCAN_COUNT=0
for f in CLAUDE.md AGENTS.md .claude/rules/*.md .claude/*.md; do
  [[ -f "$f" ]] || continue
  SCAN_COUNT=$((SCAN_COUNT+1))
  MATCH=$(grep -niE \
    'ignore (all |previous |above )?(instructions|rules)|system:|<system>|</system>|<instructions>.*</instructions>|IGNORE ALL|disregard (all |previous )?instructions|override instructions|you are now|forget (all |everything|previous)|base64:[A-Za-z0-9+/]{40}' \
    "$f" 2>/dev/null | head -2 || true)
  [[ -n "$MATCH" ]] && SCAN_FOUND="${SCAN_FOUND} ${f}"
done
if [[ -n "$SCAN_FOUND" ]]; then
  s7=0; n7="⚠ Suspicious patterns in:${SCAN_FOUND}"
else
  s7=1; n7="Clean (${SCAN_COUNT} files scanned)"
fi

# 8. Auto mode safety — since Claude Code v2.1.284 a missing defaultMode means auto mode ON
if [[ ! -f "$SETTINGS" ]]; then
  s8=0; n8="settings.json not found — session defaults to auto mode (v2.1.284+) with no deny list"
elif grep -q '"defaultMode"' "$SETTINGS" 2>/dev/null && ! grep -Eq '"defaultMode"[[:space:]]*:[[:space:]]*"auto"' "$SETTINGS" 2>/dev/null; then
  s8=1; n8="defaultMode explicitly non-auto (pass)"
else
  if grep -q '"defaultMode"' "$SETTINGS" 2>/dev/null; then MODE_SRC="explicit"; else MODE_SRC="default since v2.1.284"; fi
  HE=$(grep -c '\.env'        "$SETTINGS" 2>/dev/null)
  HK=$(grep -c '\.key'        "$SETTINGS" 2>/dev/null)
  HP=$(grep -c '\.pem'        "$SETTINGS" 2>/dev/null)
  HR=$(grep -c 'credentials'  "$SETTINGS" 2>/dev/null)
  DC=$((HE + HK + HP + HR))
  if [[ $DC -ge 3 ]]; then s8=1; n8="Auto mode active (${MODE_SRC}) WITH deny list covering secrets (${DC}/4)"
  else                      s8=0; n8="Auto mode active (${MODE_SRC}) WITHOUT complete deny list (.env:${HE} .key:${HK} .pem:${HP} credentials:${HR})"
  fi
fi

# 9. OS-level sandboxing
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
  on_restricted) s9=1; n9="sandbox.enabled with filesystem/network restrictions" ;;
  on_permissive) s9=0; n9="sandbox.enabled but no filesystem/network restrictions configured" ;;
  off)
    if [[ $HANDLES_SECRETS -eq 0 ]]; then s9=1; n9="No secrets detected — sandboxing not required (auto-pass)"
    else s9=0; n9="Project handles secrets (${SECRET_REASON}) but sandbox.enabled is not true"
    fi ;;
esac

# 10. Lint hook (lint-on-save, lint-python, lint-ts, lint-swift, etc.)
LINT_FOUND=""
for lf in .claude/hooks/lint-*.sh; do
  [[ -f "$lf" ]] && LINT_FOUND="$lf" && break
done
if   [[ -n "$LINT_FOUND" && -x "$LINT_FOUND" ]]; then s10=1; n10="$(basename "$LINT_FOUND") present and executable"
elif [[ -n "$LINT_FOUND" ]];                        then s10=1; n10="$(basename "$LINT_FOUND") present but not executable"
else                                                     s10=0; n10="No lint hook found (lint-*.sh)"
fi

# 11. Auto-memory well used (MEMORY.md index hygiene + error log)
ERRLOG=0
if [[ -f "CLAUDE_ERRORS.md" ]]; then
  if grep -qE '\| *Type *\||\| *Tipo *\|' "CLAUDE_ERRORS.md"; then ERRLOG=2; else ERRLOG=1; fi
fi
MEM_PRESENT=0; MEM_DUMP=0; MEM_LINES=0
for mf in ".claude/MEMORY.md" "MEMORY.md"; do
  if [[ -f "$mf" ]]; then
    MEM_PRESENT=1
    MEM_LINES=$(wc -l < "$mf" | tr -d ' ')
    MEM_BYTES=$(wc -c < "$mf" | tr -d ' ')
    if [[ ${MEM_LINES:-0} -gt 200 || ${MEM_BYTES:-0} -gt 25600 ]]; then MEM_DUMP=1; fi
    break
  fi
done
AGMEM=$(find .claude/agent-memory -name "*.md" -not -name ".gitkeep" 2>/dev/null | wc -l | tr -d ' ')
if [[ $MEM_DUMP -eq 1 ]]; then
  s11=0; n11="MEMORY.md is a dump (${MEM_LINES} lines / >25KB) — only first 200 lines/25KB injected"
elif [[ $ERRLOG -ge 1 || ${AGMEM:-0} -gt 0 || $MEM_PRESENT -eq 1 ]]; then
  s11=1; n11="Memory present (error-log:${ERRLOG} agent-mem:${AGMEM} memory.md-index:${MEM_PRESENT})"
else
  s11=0; n11="No project memory or error log found"
fi

# 12. Permission cascade (machine-local overrides in settings.local.json)
if [[ -f ".claude/settings.local.json" ]]; then
  s12=1; n12="settings.local.json used for local overrides"
elif [[ -f "$SETTINGS" ]] && grep -qE '/Users/|/home/[a-z]' "$SETTINGS" 2>/dev/null; then
  s12=0; n12="Machine paths in versioned settings.json — move to settings.local.json"
else
  s12=1; n12="No local overrides needed (auto-pass)"
fi

# 13. Attribution configured (attribution.* not deprecated includeCoAuthoredBy)
if [[ -f "$SETTINGS" ]] && grep -q 'includeCoAuthoredBy' "$SETTINGS" 2>/dev/null; then
  s13=0; n13="Uses deprecated includeCoAuthoredBy — migrate to attribution.commit/pr"
elif [[ -f "$SETTINGS" ]] && grep -q '"attribution"' "$SETTINGS" 2>/dev/null; then
  s13=1; n13="attribution.* configured"
else
  s13=1; n13="Default co-author acceptable (auto-pass)"
fi

# 14. Custom commands
CMD_DIR=".claude/commands"
if [[ -d "$CMD_DIR" ]] && [[ -n "$(ls "$CMD_DIR"/*.md 2>/dev/null)" ]]; then
  CC=$(ls "$CMD_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
  s14=1; n14="${CC} custom command(s)"
else
  s14=0; n14=".claude/commands/ absent or empty"
fi

# 15. Agents + orchestration
HA2=0; HR2=0
[[ -d ".claude/agents" ]] && [[ -n "$(ls .claude/agents/*.md 2>/dev/null)" ]] && HA2=1
[[ -f ".claude/rules/agents.md" ]] && HR2=1
if   [[ $HA2 -eq 1 && $HR2 -eq 1 ]]; then
  AC=$(ls .claude/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
  s15=1; n15="${AC} agents + agents.md rule"
elif [[ $HA2 -eq 1 || $HR2 -eq 1 ]]; then s15=1; n15="Partial (agents:${HA2} rule:${HR2})"
else                                        s15=0; n15="No agents or orchestration rule"
fi

# ─────────────────────────────────────────────────────────────────────────────
# DIMENSION B — dotforge Adoption (each 0-1, informational)
# ─────────────────────────────────────────────────────────────────────────────

# B1. v3 behaviors compiled AND wired in settings.json
if ls .claude/hooks/generated/*__pretooluse__*.sh >/dev/null 2>&1 \
   && [[ -f "$SETTINGS" ]] && grep -qE '(generated|__pretooluse__)' "$SETTINGS" 2>/dev/null; then
  BH_COUNT=$(ls .claude/hooks/generated/*__pretooluse__*.sh 2>/dev/null | wc -l | tr -d ' ')
  b1=1; m1="${BH_COUNT} compiled behavior hook(s) wired in settings.json"
elif [[ -f "behaviors/index.yaml" ]]; then
  b1=0; m1="behaviors declared but not compiled+wired (declaration alone does not count)"
else
  b1=0; m1="No v3 behaviors"
fi

# B2. Workflow availability (v4)
if ls workflows/*.js >/dev/null 2>&1 && grep -lq "export const meta" workflows/*.js 2>/dev/null; then
  WF=$(grep -l "export const meta" workflows/*.js 2>/dev/null | wc -l | tr -d ' ')
  b2=1; m2="${WF} workflow(s) with export const meta"
else
  b2=0; m2="No workflows/ with valid meta block"
fi

# B3. Domain rules present
DOM=$(ls .claude/rules/domain/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "${DOM:-0}" -gt 0 ]]; then
  b3=1; m3="${DOM} domain rule(s) (freshness checked semantically by /forge audit)"
else
  b3=0; m3="No domain rules in .claude/rules/domain/"
fi

# B4. Sync recency — not mechanically determinable standalone (needs registry)
b4=0; m4="Sync recency indeterminate standalone — resolved by /forge audit via registry"

# ─────────────────────────────────────────────────────────────────────────────
# Calculate scores
# ─────────────────────────────────────────────────────────────────────────────
SCORE_OBL=$((s1 + s2 + s3 + s4 + s5))
SCORE_REC=$((s6 + s7 + s8 + s9 + s10 + s11 + s12 + s13 + s14 + s15))
NATIVE_HEALTH=$(awk "BEGIN { printf \"%.2f\", ${SCORE_OBL} * 0.7 + ${SCORE_REC} * (3.0 / 10) }")

SECURITY_CAP=false
if [[ $s2 -eq 0 || $s4 -eq 0 ]]; then
  SECURITY_CAP=true
  NATIVE_HEALTH=$(awk "BEGIN { v=${NATIVE_HEALTH}; printf \"%.2f\", (v > 6.0 ? 6.0 : v) }")
fi

FORGE_ADOPTION=$((b1 + b2 + b3 + b4))
if   [[ $FORGE_ADOPTION -eq 0 ]]; then ADOPTION_LABEL="None"
elif [[ $FORGE_ADOPTION -le 2 ]]; then ADOPTION_LABEL="Partial"
elif [[ $FORGE_ADOPTION -eq 3 ]]; then ADOPTION_LABEL="Most"
else                                   ADOPTION_LABEL="Full"
fi

LEVEL=$(awk "BEGIN {
  s = ${NATIVE_HEALTH}
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
  "score": float("${NATIVE_HEALTH}"),
  "native_health": float("${NATIVE_HEALTH}"),
  "level": "${LEVEL}",
  "security_cap": ${CAP_STR},
  "score_obligatorio": ${SCORE_OBL},
  "score_recomendado": ${SCORE_REC},
  "forge_adoption": ${FORGE_ADOPTION},
  "adoption_label": "${ADOPTION_LABEL}",
  "native_health_items": {
    "1_claude_md":         {"score": ${s1},  "note": "$(_san "$n1")"},
    "2_settings_json":     {"score": ${s2},  "note": "$(_san "$n2")"},
    "3_rules":             {"score": ${s3},  "note": "$(_san "$n3")"},
    "4_block_destructive": {"score": ${s4},  "note": "$(_san "$n4")"},
    "5_build_test":        {"score": ${s5},  "note": "$(_san "$n5")"},
    "6_gitignore":         {"score": ${s6},  "note": "$(_san "$n6")"},
    "7_injection":         {"score": ${s7},  "note": "$(_san "$n7")"},
    "8_auto_mode":         {"score": ${s8},  "note": "$(_san "$n8")"},
    "9_sandboxing":        {"score": ${s9},  "note": "$(_san "$n9")"},
    "10_lint_hook":        {"score": ${s10}, "note": "$(_san "$n10")"},
    "11_auto_memory":      {"score": ${s11}, "note": "$(_san "$n11")"},
    "12_permission_cascade": {"score": ${s12}, "note": "$(_san "$n12")"},
    "13_attribution":      {"score": ${s13}, "note": "$(_san "$n13")"},
    "14_commands":         {"score": ${s14}, "note": "$(_san "$n14")"},
    "15_agents":           {"score": ${s15}, "note": "$(_san "$n15")"}
  },
  "adoption_items": {
    "B1_behaviors":        {"score": ${b1}, "note": "$(_san "$m1")"},
    "B2_workflows":        {"score": ${b2}, "note": "$(_san "$m2")"},
    "B3_domain_rules":     {"score": ${b3}, "note": "$(_san "$m3")"},
    "B4_sync_recency":     {"score": ${b4}, "note": "$(_san "$m4")"}
  }
}
print(json.dumps(data, indent=2))
PYEOF
else
  CAP_NOTE=""
  $SECURITY_CAP && CAP_NOTE="  ⚠ security cap applied (settings.json or block-destructive missing)"
  echo "═══ AUDIT SCORE: $(basename "$PROJECT_DIR") ═══"
  echo "Native Health: ${NATIVE_HEALTH}/10  (${LEVEL})${CAP_NOTE}"
  echo "dotforge Adoption: ${FORGE_ADOPTION}/4  (${ADOPTION_LABEL})  [informational — does not affect Native Health]"
  echo ""
  echo "═ DIMENSION A — NATIVE HEALTH ═"
  echo "── OBLIGATORIO (${SCORE_OBL}/10) ──"
  printf "  [%s] 1.  CLAUDE.md            %s\n" "$s1"  "$n1"
  printf "  [%s] 2.  settings.json        %s\n" "$s2"  "$n2"
  printf "  [%s] 3.  Rules                %s\n" "$s3"  "$n3"
  printf "  [%s] 4.  block-destructive    %s\n" "$s4"  "$n4"
  printf "  [%s] 5.  Build/test commands  %s\n" "$s5"  "$n5"
  echo ""
  echo "── RECOMENDADO (${SCORE_REC}/10) ──"
  printf "  [%s] 6.  .gitignore           %s\n" "$s6"  "$n6"
  printf "  [%s] 7.  Injection scan       %s\n" "$s7"  "$n7"
  printf "  [%s] 8.  Auto mode safety     %s\n" "$s8"  "$n8"
  printf "  [%s] 9.  Sandboxing           %s\n" "$s9"  "$n9"
  printf "  [%s] 10. Lint hook            %s\n" "$s10" "$n10"
  printf "  [%s] 11. Auto-memory used     %s\n" "$s11" "$n11"
  printf "  [%s] 12. Permission cascade   %s\n" "$s12" "$n12"
  printf "  [%s] 13. Attribution          %s\n" "$s13" "$n13"
  printf "  [%s] 14. Custom commands      %s\n" "$s14" "$n14"
  printf "  [%s] 15. Agents               %s\n" "$s15" "$n15"
  echo ""
  echo "═ DIMENSION B — DOTFORGE ADOPTION (informational) ═"
  printf "  [%s] B1. v3 behaviors         %s\n" "$b1" "$m1"
  printf "  [%s] B2. Workflow available   %s\n" "$b2" "$m2"
  printf "  [%s] B3. Domain rules         %s\n" "$b3" "$m3"
  printf "  [%s] B4. Sync recency         %s\n" "$b4" "$m4"
fi

# CI threshold gate (on Native Health)
if [[ -n "$THRESHOLD" ]]; then
  BELOW=$(awk "BEGIN { print (${NATIVE_HEALTH} < ${THRESHOLD}) ? 1 : 0 }")
  if [[ "$BELOW" == "1" ]]; then
    echo "" >&2
    echo "FAIL: native_health ${NATIVE_HEALTH} is below threshold ${THRESHOLD}" >&2
    exit 2
  fi
fi

exit 0
