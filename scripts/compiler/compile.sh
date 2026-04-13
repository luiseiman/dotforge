#!/usr/bin/env bash
# dotforge v3 behavior compiler — minimal.
# Reads a behavior.yaml and emits one bash hook per trigger into an output dir,
# plus a JSON snippet for settings.json registration.
#
# Usage:
#   scripts/compiler/compile.sh <path/to/behavior.yaml> [output_dir]
#
# Default output_dir: .claude/hooks/generated
#
# Supported actions: evaluate, set_flag, check_flag (SCHEMA.md §3.5)
# Unsupported in v1: type: prompt, conditions with closed DSL beyond matcher.
#                    conditions are emitted into the hook as a comment but NOT
#                    enforced. The only runtime enforcement in v1 is the matcher.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

_log() { printf '[compile] %s\n' "$*" >&2; }
_die() { _log "ERROR: $*"; exit 1; }

[ $# -ge 1 ] || _die "usage: $0 <behavior.yaml> [output_dir]"
YAML_FILE="$1"
OUTPUT_DIR="${2:-.claude/hooks/generated}"
[ -f "$YAML_FILE" ] || _die "behavior file not found: $YAML_FILE"

command -v jq >/dev/null 2>&1 || _die "jq is required"
command -v python3 >/dev/null 2>&1 || _die "python3 is required"

# ---------------------------------------------------------------------------
# Load YAML → JSON
# ---------------------------------------------------------------------------

BEHAVIOR_JSON=$(python3 - <<PYEOF
import json, sys, yaml
with open("${YAML_FILE}", "r") as f:
    data = yaml.safe_load(f)
json.dump(data, sys.stdout)
PYEOF
)

[ -n "$BEHAVIOR_JSON" ] || _die "could not parse YAML: $YAML_FILE"

# ---------------------------------------------------------------------------
# Extract top-level fields
# ---------------------------------------------------------------------------

SCHEMA_VERSION=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.schema_version // empty')
[ "$SCHEMA_VERSION" = "1" ] || _die "schema_version must equal \"1\" (got: $SCHEMA_VERSION)"

BEHAVIOR_ID=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.id // empty')
[ -n "$BEHAVIOR_ID" ] || _die "id is required"
printf '%s' "$BEHAVIOR_ID" | grep -qE '^[a-z][a-z0-9-]*[a-z0-9]$' \
    || _die "id must match ^[a-z][a-z0-9-]*[a-z0-9]$ (got: $BEHAVIOR_ID)"

BEHAVIOR_NAME=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.name // .id')
BEHAVIOR_CATEGORY=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.category // "experimental"')

DEFAULT_LEVEL=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.policy.enforcement.default_level // "silent"')
ESCALATION_JSON=$(printf '%s' "$BEHAVIOR_JSON" | jq -c '.policy.enforcement.escalation // []')
RECOVERY_HINT=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.policy.recovery.hint // ""')
NUDGE_TEMPLATE=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.rendering.nudge_template // empty')
WARNING_TEMPLATE=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.rendering.warning_template // empty')
BLOCK_REASON=$(printf '%s' "$BEHAVIOR_JSON" | jq -r '.rendering.block_reason // "Behavior blocked by dotforge."')

TRIGGER_COUNT=$(printf '%s' "$BEHAVIOR_JSON" | jq '.policy.triggers | length')
[ "$TRIGGER_COUNT" -ge 1 ] || _die "at least one trigger is required"

mkdir -p "$OUTPUT_DIR"

SETTINGS_SNIPPET='{"hooks":{}}'

# ---------------------------------------------------------------------------
# Helpers: escape YAML-sourced strings for safe embedding in bash single quotes
# ---------------------------------------------------------------------------

# Escape a value so it can live inside bash single-quoted strings.
# Closes the quote, inserts an escaped single quote, reopens — the classic pattern.
# Replaces each ' with the 4-char sequence: '\''
_bash_sq_escape() {
    # Use python3 for correctness — bash parameter expansion backslash handling
    # is treacherous enough inside double quotes that we bypass it.
    python3 -c 'import sys; print(sys.argv[1].replace("\x27", "\x27\\\x27\x27"), end="")' "$1"
}

# Slugify a matcher (e.g. "Write|Edit" → "write-edit", "*" → "all")
_slugify_matcher() {
    local raw="$1"
    if [ -z "$raw" ] || [ "$raw" = "*" ]; then
        printf 'all'
        return
    fi
    printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr '|' '-' | tr -cd 'a-z0-9-'
}

# ---------------------------------------------------------------------------
# Per-trigger hook generation
# ---------------------------------------------------------------------------

for idx in $(seq 0 $((TRIGGER_COUNT - 1))); do
    TRIGGER=$(printf '%s' "$BEHAVIOR_JSON" | jq -c ".policy.triggers[$idx]")
    EVENT=$(printf '%s' "$TRIGGER" | jq -r '.event // "PreToolUse"')
    MATCHER=$(printf '%s' "$TRIGGER" | jq -r '.matcher // "*"')
    ACTION=$(printf '%s' "$TRIGGER" | jq -r '.action // "evaluate"')
    FLAG=$(printf '%s' "$TRIGGER" | jq -r '.flag // empty')
    ON_PRESENT=$(printf '%s' "$TRIGGER" | jq -r '.on_present // empty')
    ON_ABSENT=$(printf '%s' "$TRIGGER" | jq -r '.on_absent // empty')
    CONDITIONS_JSON=$(printf '%s' "$TRIGGER" | jq -c '.conditions // []')
    CONDITIONS_COUNT=$(printf '%s' "$CONDITIONS_JSON" | jq 'length')
    CONDITIONS_LOGIC=$(printf '%s' "$TRIGGER" | jq -r '.logic // "all"')

    case "$ACTION" in
        evaluate) ;;
        set_flag)
            [ -n "$FLAG" ] || _die "trigger[$idx]: set_flag requires 'flag'"
            ;;
        check_flag)
            [ -n "$FLAG" ] || _die "trigger[$idx]: check_flag requires 'flag'"
            [ "$ON_PRESENT" = "consume" ] || [ "$ON_PRESENT" = "keep" ] \
                || _die "trigger[$idx]: check_flag requires on_present ∈ {consume, keep}"
            [ "$ON_ABSENT" = "skip" ] || [ "$ON_ABSENT" = "violate" ] \
                || _die "trigger[$idx]: check_flag requires on_absent ∈ {skip, violate}"
            ;;
        *) _die "trigger[$idx]: unknown action '$ACTION'"
            ;;
    esac

    MATCHER_SLUG=$(_slugify_matcher "$MATCHER")
    EVENT_SLUG=$(printf '%s' "$EVENT" | tr '[:upper:]' '[:lower:]')
    HOOK_PATH="${OUTPUT_DIR}/${BEHAVIOR_ID}__${EVENT_SLUG}__${MATCHER_SLUG}__${idx}.sh"

    # Escape strings destined for single-quoted bash literals
    ESC_BID=$(_bash_sq_escape "$BEHAVIOR_ID")
    ESC_NAME=$(_bash_sq_escape "$BEHAVIOR_NAME")
    ESC_FLAG=$(_bash_sq_escape "$FLAG")
    ESC_DEFAULT_LEVEL=$(_bash_sq_escape "$DEFAULT_LEVEL")
    ESC_ESCALATION=$(_bash_sq_escape "$ESCALATION_JSON")
    ESC_NUDGE=$(_bash_sq_escape "$NUDGE_TEMPLATE")
    ESC_WARNING=$(_bash_sq_escape "$WARNING_TEMPLATE")
    ESC_BLOCK_REASON=$(_bash_sq_escape "$BLOCK_REASON")
    ESC_RECOVERY=$(_bash_sq_escape "$RECOVERY_HINT")

    {
    cat <<HOOK_HEADER
#!/usr/bin/env bash
# GENERATED by scripts/compiler/compile.sh — DO NOT EDIT BY HAND.
# Source: ${YAML_FILE}
# Behavior: ${BEHAVIOR_ID} (${BEHAVIOR_CATEGORY})
# Event:    ${EVENT}
# Matcher:  ${MATCHER}
# Action:   ${ACTION}
# Trigger:  index ${idx}
set -u

if [ -n "\${FORGE_LIB_PATH:-}" ]; then
    # shellcheck source=/dev/null
    . "\${FORGE_LIB_PATH}"
else
    HOOK_SCRIPT_DIR=\$(cd "\$(dirname "\$0")" && pwd)
    REPO_ROOT=\$(cd "\${HOOK_SCRIPT_DIR}/../../.." && pwd)
    # shellcheck source=/dev/null
    . "\${REPO_ROOT}/scripts/runtime/lib.sh"
fi

BEHAVIOR_ID='${ESC_BID}'
BEHAVIOR_NAME='${ESC_NAME}'
DEFAULT_LEVEL='${ESC_DEFAULT_LEVEL}'
ESCALATION_JSON='${ESC_ESCALATION}'
BLOCK_REASON='${ESC_BLOCK_REASON}'
RECOVERY_HINT='${ESC_RECOVERY}'
NUDGE_TEMPLATE='${ESC_NUDGE}'
WARNING_TEMPLATE='${ESC_WARNING}'
EVENT_NAME='${EVENT}'

PAYLOAD=\$(cat)
SESSION_ID=\$(printf '%s' "\$PAYLOAD" | forge_session_id)
TOOL_NAME=\$(printf '%s' "\$PAYLOAD" | jq -r '.tool_name // empty')
# For PreToolUse/PostToolUse, conditions see tool_input.
# For UserPromptSubmit/Stop, merge top-level payload fields (e.g., .prompt)
# into the condition context so DSL fields like \`prompt\` resolve.
TOOL_INPUT_JSON=\$(printf '%s' "\$PAYLOAD" | jq -c '(.tool_input // {}) + (del(.session_id, .tool_name, .tool_input, .transcript_path, .cwd, .hook_event_name))')
TOOL_INPUT_HASH=\$(printf '%s' "\$TOOL_INPUT_JSON" | forge_tool_input_hash)
TOOL_INPUT_SUMMARY=\$(printf '%s' "\$TOOL_INPUT_JSON" | cut -c1-100 | tr -d '\\n')

# Session-scope disable (set via /forge behavior off --session)
if forge_behavior_session_is_disabled "\$SESSION_ID" "\$BEHAVIOR_ID"; then
    exit 0
fi
HOOK_HEADER

    # Condition evaluation block (only when conditions exist).
    # Uses python3 re module for full regex support (\s, \b, etc.).
    if [ "$CONDITIONS_COUNT" -gt 0 ]; then
        ESC_CONDITIONS=$(_bash_sq_escape "$CONDITIONS_JSON")
        cat <<HOOK_CONDITIONS

# Conditions (logic: ${CONDITIONS_LOGIC})
CONDITIONS_JSON='${ESC_CONDITIONS}'
if ! python3 - "\$CONDITIONS_JSON" '${CONDITIONS_LOGIC}' "\$TOOL_INPUT_JSON" <<'PYCOND'
import sys, json, re
conditions = json.loads(sys.argv[1])
logic = sys.argv[2]
tool_input = json.loads(sys.argv[3] or '{}')

def get_field(f):
    return tool_input.get(f, '') or ''

def check(c):
    field = c.get('field', '')
    op = c.get('operator', '')
    val = c.get('value', '')
    v = get_field(field)
    sv = str(v) if v is not None else ''
    if op == 'regex_match':
        try:
            return bool(re.search(val, sv))
        except re.error:
            return False
    if op == 'contains':     return val in sv
    if op == 'not_contains': return val not in sv
    if op == 'equals':       return sv == str(val)
    if op == 'starts_with':  return sv.startswith(val)
    if op == 'ends_with':    return sv.endswith(val)
    if op == 'exists':       return bool(sv)
    if op == 'not_exists':   return not sv
    try:
        nv = float(sv) if sv != '' else 0.0
        nval = float(val)
    except (TypeError, ValueError):
        return False
    if op == 'gt':     return nv >  nval
    if op == 'lt':     return nv <  nval
    if op == 'gte':    return nv >= nval
    if op == 'lte':    return nv <= nval
    return False

results = [check(c) for c in conditions]
if logic == 'any':
    ok = any(results) if results else True
else:
    ok = all(results) if results else True
sys.exit(0 if ok else 1)
PYCOND
then
    exit 0
fi
HOOK_CONDITIONS
    fi

    # The evaluate helpers (render_template, emit_output, run_evaluate) are only
    # needed when the hook takes the evaluate path. Pure set_flag hooks emit
    # neither output nor counter mutations — so we omit the block entirely.
    needs_evaluate=0
    case "$ACTION" in
        evaluate) needs_evaluate=1 ;;
        check_flag) [ "$ON_ABSENT" = "violate" ] && needs_evaluate=1 ;;
    esac

    if [ "$needs_evaluate" = "1" ]; then
    cat <<HOOK_EVAL_HELPERS

render_template() {
    local tpl="\$1" counter="\$2" level="\$3"
    printf '%s' "\$tpl" \\
        | sed "s|{behavior_id}|\${BEHAVIOR_ID}|g" \\
        | sed "s|{behavior_name}|\${BEHAVIOR_NAME}|g" \\
        | sed "s|{counter}|\${counter}|g" \\
        | sed "s|{tool_name}|\${TOOL_NAME}|g" \\
        | sed "s|{level}|\${level}|g" \\
        | sed "s|{threshold}|\${counter}|g"
}

emit_output() {
    local level="\$1" counter="\$2"
    case "\$level" in
        silent)
            exit 0
            ;;
        nudge)
            local msg
            msg=\$(render_template "\$NUDGE_TEMPLATE" "\$counter" "\$level")
            jq -cn --arg m "\$msg" '{systemMessage: \$m}'
            exit 0
            ;;
        warning)
            local msg
            msg=\$(render_template "\$WARNING_TEMPLATE" "\$counter" "\$level")
            jq -cn --arg m "\$msg" '{systemMessage: \$m}'
            exit 0
            ;;
        soft_block)
            # Write pending_block BEFORE emitting so the next invocation can
            # detect reinvocation after user override.
            forge_pending_block_set "\$SESSION_ID" "\$BEHAVIOR_ID" "\$TOOL_INPUT_HASH" || true
            local msg
            msg=\$(render_template "\$BLOCK_REASON" "\$counter" "\$level")
            jq -cn --arg m "\$msg" --arg evt "\$EVENT_NAME" \\
                '{hookSpecificOutput: {hookEventName: \$evt, permissionDecision: "deny"}, systemMessage: \$m}'
            exit 0
            ;;
        hard_block)
            local msg
            msg=\$(render_template "\$BLOCK_REASON" "\$counter" "\$level")
            jq -cn --arg m "\$msg" --arg evt "\$EVENT_NAME" \\
                '{hookSpecificOutput: {hookEventName: \$evt, permissionDecision: "deny", override_allowed: false}, systemMessage: \$m}'
            exit 0
            ;;
    esac
    exit 0
}

run_evaluate() {
    # Step 0: try override detection via reinvocation. If the pending_block
    # matches this incoming tool_input hash within the window, record the
    # override and pass through silently — do NOT increment counter.
    if forge_pending_block_try_override "\$SESSION_ID" "\$BEHAVIOR_ID" \\
            "\$TOOL_NAME" "\$TOOL_INPUT_HASH" "\$TOOL_INPUT_SUMMARY"; then
        exit 0
    fi

    local counter calculated previous effective
    counter=\$(forge_counter_increment "\$SESSION_ID" "\$BEHAVIOR_ID" "\$TOOL_NAME")
    [ -n "\$counter" ] || { _forge_log "counter increment failed"; exit 0; }
    calculated=\$(forge_resolve_level "\$counter" "\$DEFAULT_LEVEL" "\$ESCALATION_JSON")
    previous=\$(jq -r --arg sid "\$SESSION_ID" --arg bid "\$BEHAVIOR_ID" \\
        '.sessions[\$sid].behaviors[\$bid].effective_level // "silent"' "\$FORGE_STATE_FILE")
    effective=\$(forge_level_max "\$previous" "\$calculated")
    forge_effective_level_set "\$SESSION_ID" "\$BEHAVIOR_ID" "\$effective"
    emit_output "\$effective" "\$counter"
}
HOOK_EVAL_HELPERS
    fi

    case "$ACTION" in
        evaluate)
            cat <<'HOOK_EVAL'

# Action: evaluate
run_evaluate
HOOK_EVAL
            ;;
        set_flag)
            cat <<HOOK_SETFLAG

# Action: set_flag
forge_flag_set "\$SESSION_ID" '${ESC_FLAG}' || true
exit 0
HOOK_SETFLAG
            ;;
        check_flag)
            cat <<HOOK_CHECKFLAG

# Action: check_flag
if forge_flag_consume "\$SESSION_ID" '${ESC_FLAG}'; then
    # Flag was present.
HOOK_CHECKFLAG
            if [ "$ON_PRESENT" = "keep" ]; then
                # Re-set to undo the consume — same semantics with one less state op.
                cat <<HOOK_KEEP
    forge_flag_set "\$SESSION_ID" '${ESC_FLAG}' || true
HOOK_KEEP
            fi
            cat <<'HOOK_PRESENT_TAIL'
    exit 0
else
    # Flag absent.
HOOK_PRESENT_TAIL
            if [ "$ON_ABSENT" = "skip" ]; then
                cat <<'HOOK_SKIP'
    exit 0
fi
HOOK_SKIP
            else
                cat <<'HOOK_VIOLATE'
    run_evaluate
fi
HOOK_VIOLATE
            fi
            ;;
    esac

    } > "$HOOK_PATH"

    chmod +x "$HOOK_PATH"

    # Syntax check
    bash -n "$HOOK_PATH" || _die "generated hook has syntax error: $HOOK_PATH"

    # Append to settings snippet
    SETTINGS_SNIPPET=$(printf '%s' "$SETTINGS_SNIPPET" | jq \
        --arg event "$EVENT" \
        --arg matcher "$MATCHER" \
        --arg cmd "$HOOK_PATH" '
        .hooks[$event] //= []
        | .hooks[$event] += [{
            matcher: $matcher,
            hooks: [{type: "command", command: $cmd}]
        }]
    ')

    _log "generated: $HOOK_PATH"
done

# ---------------------------------------------------------------------------
# Emit settings snippet
# ---------------------------------------------------------------------------

SETTINGS_SNIPPET_FILE="${OUTPUT_DIR}/${BEHAVIOR_ID}.settings.json"
printf '%s\n' "$SETTINGS_SNIPPET" | jq . > "$SETTINGS_SNIPPET_FILE"
_log "settings snippet: $SETTINGS_SNIPPET_FILE"
_log "compiled ${TRIGGER_COUNT} trigger(s) for behavior '${BEHAVIOR_ID}'"
