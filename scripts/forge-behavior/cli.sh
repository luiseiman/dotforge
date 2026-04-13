#!/usr/bin/env bash
# /forge behavior — status, on/off, strict/relaxed.
#
# Usage:
#   forge-behavior status [--session SESSION_ID]
#   forge-behavior on  <behavior_id> [--session SESSION_ID | --project]
#   forge-behavior off <behavior_id> [--session SESSION_ID | --project]
#   forge-behavior strict  <behavior_id>        # project scope only in v1
#   forge-behavior relaxed <behavior_id>        # project scope only in v1
#
# Scopes:
#   --project (default) mutates behaviors/index.yaml and/or behavior.yaml.
#                       Persistent across sessions.
#   --session SESSION_ID writes to .forge/runtime/state.json only.
#                       Ephemeral; ends when the session expires via TTL.
#
# Requires: bash 3.2+, jq, python3 with PyYAML.

set -u

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)
BEHAVIORS_DIR="${FORGE_BEHAVIORS_DIR:-${REPO_ROOT}/behaviors}"
INDEX_FILE="${BEHAVIORS_DIR}/index.yaml"

# shellcheck source=../runtime/lib.sh
. "${REPO_ROOT}/scripts/runtime/lib.sh"

_die() { printf '[forge behavior] error: %s\n' "$*" >&2; exit 1; }
_info() { printf '[forge behavior] %s\n' "$*"; }

# ---------------------------------------------------------------------------
# Helpers: YAML I/O via python3
# ---------------------------------------------------------------------------

_yaml_to_json() {
    python3 - "$1" <<'PY'
import json, sys, yaml
with open(sys.argv[1], 'r') as f:
    print(json.dumps(yaml.safe_load(f) or {}))
PY
}

_json_to_yaml_file() {
    # Heredoc redirects python's stdin to the script body itself, so we
    # cannot read the JSON from stdin here. Buffer it to a tmp file and
    # pass the path as an argument.
    local target="$1"
    local tmp
    tmp=$(mktemp)
    cat > "$tmp"
    python3 - "$target" "$tmp" <<'PY'
import json, sys, yaml
target, src = sys.argv[1], sys.argv[2]
with open(src) as f:
    data = json.loads(f.read())
with open(target, 'w') as f:
    yaml.safe_dump(data, f, sort_keys=False, default_flow_style=False)
PY
    rm -f "$tmp"
}

_require_index() {
    [ -f "$INDEX_FILE" ] || _die "index not found: $INDEX_FILE"
}

_behavior_yaml_path() {
    local bid="$1"
    printf '%s' "${BEHAVIORS_DIR}/${bid}/behavior.yaml"
}

_behavior_yaml_must_exist() {
    local bid="$1" path
    path=$(_behavior_yaml_path "$bid")
    [ -f "$path" ] || _die "behavior yaml not found: $path"
    printf '%s' "$path"
}

# ---------------------------------------------------------------------------
# Action: status
# ---------------------------------------------------------------------------

cmd_status() {
    local sid="${1:-}"

    printf 'Behaviors (project scope from %s):\n' "${INDEX_FILE#"${REPO_ROOT}/"}"
    if [ ! -f "$INDEX_FILE" ]; then
        printf '  (no index.yaml — create behaviors/index.yaml to list active behaviors)\n'
    else
        local index_json
        index_json=$(_yaml_to_json "$INDEX_FILE")
        printf '%s' "$index_json" | jq -r '
            .behaviors // [] | .[] |
            "  \(.id | . + (" " * (20 - length)))  enabled=\(.enabled)"
        '
    fi

    printf '\nRuntime state (.forge/runtime/state.json):\n'
    if [ ! -f "$FORGE_STATE_FILE" ]; then
        printf '  (no state.json — no sessions tracked yet)\n'
        return 0
    fi

    if [ -n "$sid" ]; then
        _print_session_row "$sid"
    else
        local sessions
        sessions=$(jq -r '.sessions | keys | .[]?' "$FORGE_STATE_FILE" 2>/dev/null)
        if [ -z "$sessions" ]; then
            printf '  (no active sessions)\n'
            return 0
        fi
        local s
        while IFS= read -r s; do
            [ -z "$s" ] && continue
            _print_session_row "$s"
        done <<< "$sessions"
    fi
}

_print_session_row() {
    local sid="$1"
    local exists
    exists=$(jq -r --arg sid "$sid" '.sessions[$sid] // empty' "$FORGE_STATE_FILE")
    if [ -z "$exists" ] || [ "$exists" = "null" ]; then
        printf '  session %s: (not found)\n' "$sid"
        return 0
    fi
    printf '  session %s:\n' "$sid"
    jq -r --arg sid "$sid" '
        .sessions[$sid] as $s |
        ($s.behaviors // {}) | to_entries[] |
        "    \(.key | . + (" " * (20 - length)))  counter=\(.value.counter)  level=\(.value.effective_level)  overrides=\(.value.overrides | length)  pending=\(.value.pending_block != null)"
    ' "$FORGE_STATE_FILE"

    local override_keys
    override_keys=$(jq -r --arg sid "$sid" \
        '.sessions[$sid].behavior_overrides // {} | keys | .[]?' "$FORGE_STATE_FILE")
    if [ -n "$override_keys" ]; then
        printf '    session overrides:\n'
        while IFS= read -r bid; do
            [ -z "$bid" ] && continue
            local enabled
            enabled=$(jq -r --arg sid "$sid" --arg bid "$bid" \
                '.sessions[$sid].behavior_overrides[$bid].enabled' "$FORGE_STATE_FILE")
            printf '      %s: enabled=%s\n' "$bid" "$enabled"
        done <<< "$override_keys"
    fi
}

# ---------------------------------------------------------------------------
# Action: on / off
# ---------------------------------------------------------------------------

cmd_on_off() {
    local action="$1" bid="$2" scope="$3" sid="${4:-}"
    local target_enabled
    case "$action" in
        on)  target_enabled=true ;;
        off) target_enabled=false ;;
        *)   _die "internal: cmd_on_off action must be on|off" ;;
    esac

    case "$scope" in
        project)
            _require_index
            local idx_json mutated
            idx_json=$(_yaml_to_json "$INDEX_FILE")
            if ! printf '%s' "$idx_json" | jq -e --arg bid "$bid" \
                '.behaviors[] | select(.id == $bid)' >/dev/null; then
                _die "behavior '$bid' not listed in index.yaml"
            fi
            mutated=$(printf '%s' "$idx_json" | jq --arg bid "$bid" --argjson e "$target_enabled" '
                .behaviors |= map(
                    if .id == $bid then .enabled = $e else . end
                )
            ')
            printf '%s' "$mutated" | _json_to_yaml_file "$INDEX_FILE"
            _info "project scope: $bid enabled=$target_enabled in $INDEX_FILE"
            _info "note: recompile the behavior to apply: scripts/compiler/compile.sh $(_behavior_yaml_path "$bid") <output_dir>"
            ;;
        session)
            [ -n "$sid" ] || _die "--session requires --session-id SESSION_ID"
            if [ "$target_enabled" = "false" ]; then
                forge_behavior_session_disable "$sid" "$bid" || _die "lock error"
                _info "session $sid: $bid disabled"
            else
                forge_behavior_session_enable "$sid" "$bid" || _die "lock error"
                _info "session $sid: $bid enabled (override cleared)"
            fi
            ;;
        *) _die "unknown scope: $scope" ;;
    esac
}

# ---------------------------------------------------------------------------
# Action: strict / relaxed
# ---------------------------------------------------------------------------

cmd_strictness() {
    local direction="$1" bid="$2"
    local yaml_path
    yaml_path=$(_behavior_yaml_must_exist "$bid")

    python3 - "$yaml_path" "$direction" <<'PY'
import sys, yaml
path, direction = sys.argv[1], sys.argv[2]
with open(path, 'r') as f:
    data = yaml.safe_load(f) or {}

esc = data.get('policy', {}).get('enforcement', {}).get('escalation', [])
if not esc:
    print(f"[forge behavior] no escalation to modify in {path}", file=sys.stderr)
    sys.exit(1)

if direction == 'strict':
    for e in esc:
        e['after'] = max(1, e['after'] // 2)
elif direction == 'relaxed':
    for e in esc:
        e['after'] = e['after'] * 2
else:
    print(f"[forge behavior] unknown direction: {direction}", file=sys.stderr)
    sys.exit(1)

data['policy']['enforcement']['escalation'] = esc
with open(path, 'w') as f:
    yaml.safe_dump(data, f, sort_keys=False, default_flow_style=False)

print(f"[forge behavior] {direction}: updated escalation in {path}")
for e in esc:
    print(f"  after={e['after']:<3}  level={e['level']}")
PY
}

# ---------------------------------------------------------------------------
# Dispatcher
# ---------------------------------------------------------------------------

main() {
    local cmd="${1:-}"
    [ -n "$cmd" ] || _die "usage: $0 <status|on|off|strict|relaxed> [...]"
    shift

    case "$cmd" in
        status)
            local sid=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --session)
                        [ $# -ge 2 ] || _die "--session requires SESSION_ID"
                        sid="$2"; shift 2
                        ;;
                    *) shift ;;
                esac
            done
            cmd_status "$sid"
            ;;
        on|off)
            local action="$cmd"
            local bid="${1:-}"
            [ -n "$bid" ] || _die "usage: $0 $action <behavior_id> [--project | --session SESSION_ID]"
            shift
            local scope=project sid=""
            while [ $# -gt 0 ]; do
                case "$1" in
                    --project) scope=project; shift ;;
                    --session)
                        [ $# -ge 2 ] || _die "--session requires SESSION_ID"
                        scope=session; sid="$2"; shift 2
                        ;;
                    *) _die "unknown flag: $1" ;;
                esac
            done
            cmd_on_off "$action" "$bid" "$scope" "$sid"
            ;;
        strict|relaxed)
            local direction="$cmd"
            local bid="${1:-}"
            [ -n "$bid" ] || _die "usage: $0 $direction <behavior_id>"
            cmd_strictness "$direction" "$bid"
            ;;
        *)
            _die "unknown command: $cmd (expected status|on|off|strict|relaxed)"
            ;;
    esac
}

main "$@"
