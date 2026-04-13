#!/usr/bin/env bash
# dotforge v3 runtime library — session state, locking, counters, flags, overrides.
# Sourced by compiled behavior hooks. Never invoked directly.
#
# Contracts:
#   RUNTIME.md §§2,4,5,6,7,8,10,11
#   SPEC.md    §§2,3
#
# Dependencies: bash 3.2+, jq, shasum (or md5sum as fallback).

set -u

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

FORGE_ROOT="${FORGE_ROOT:-.forge}"
FORGE_STATE_FILE="${FORGE_ROOT}/runtime/state.json"
FORGE_LOCK_DIR="${FORGE_ROOT}/runtime/state.lock"
FORGE_AUDIT_LOG="${FORGE_ROOT}/audit/overrides.log"
FORGE_LOCK_TIMEOUT="${FORGE_LOCK_TIMEOUT:-2}"
FORGE_SESSION_TTL_SECONDS="${FORGE_SESSION_TTL_SECONDS:-86400}"
FORGE_EMPTY_STATE='{"schema_version":"1","sessions":{}}'

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

_forge_log() {
    printf '[forge] %s\n' "$*" >&2
}

_forge_now_epoch() {
    date -u +%s
}

_forge_now_iso8601() {
    # Portable UTC ISO 8601 (macOS + Linux).
    date -u +%Y-%m-%dT%H:%M:%SZ
}

_forge_hash() {
    # Portable hash used only for session id fallback. First 36 hex chars.
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | cut -c1-36
    elif command -v md5sum >/dev/null 2>&1; then
        md5sum | cut -c1-36
    else
        _forge_log "no shasum or md5sum available — session id fallback degraded"
        printf 'forge-fallback-%s-%s' "$$" "$(date -u +%Y%m%d)"
    fi
}

_forge_require_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        _forge_log "jq not available — behavior hook degraded to silent pass-through"
        return 1
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------------

# forge_init — idempotent bootstrap of .forge/ tree. Safe to call repeatedly.
# Returns 0 on success, 1 if jq is missing.
forge_init() {
    _forge_require_jq || return 1
    mkdir -p "${FORGE_ROOT}/runtime" "${FORGE_ROOT}/audit" 2>/dev/null || {
        _forge_log "cannot create ${FORGE_ROOT}/ — disk full or permission denied"
        return 1
    }
    if [ ! -f "$FORGE_STATE_FILE" ]; then
        printf '%s\n' "$FORGE_EMPTY_STATE" > "$FORGE_STATE_FILE"
    fi
    if [ ! -f "$FORGE_AUDIT_LOG" ]; then
        : > "$FORGE_AUDIT_LOG"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# Session id (pure function — no state mutation)
# ---------------------------------------------------------------------------

# forge_session_id — read session id from hook JSON payload on stdin.
# Falls back to a deterministic hash of ${PWD}:${PPID}:$(date +%Y%m%d) if absent.
# Prints the session id on stdout. Does not hold the lock.
forge_session_id() {
    local payload
    payload=$(cat)
    local sid
    sid=$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null)
    if [ -n "$sid" ] && [ "$sid" != "null" ]; then
        printf '%s' "$sid"
        return 0
    fi
    printf '%s:%s:%s' "${PWD}" "${PPID}" "$(date -u +%Y%m%d)" | _forge_hash
}

# ---------------------------------------------------------------------------
# Locking
# ---------------------------------------------------------------------------

# forge_lock_acquire — mkdir-based lock with stale-lock detection.
# Returns 0 on success, 1 on timeout. See RUNTIME.md §8.
forge_lock_acquire() {
    local deadline
    deadline=$(( $(_forge_now_epoch) + FORGE_LOCK_TIMEOUT ))
    while ! mkdir "$FORGE_LOCK_DIR" 2>/dev/null; do
        if [ -f "${FORGE_LOCK_DIR}/pid" ]; then
            local pid
            pid=$(cat "${FORGE_LOCK_DIR}/pid" 2>/dev/null || true)
            if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
                rm -rf "$FORGE_LOCK_DIR" 2>/dev/null || true
                if mkdir "$FORGE_LOCK_DIR" 2>/dev/null; then
                    break
                fi
            fi
        fi
        if [ "$(_forge_now_epoch)" -ge "$deadline" ]; then
            return 1
        fi
        sleep 0.1
    done
    printf '%s' "$$" > "${FORGE_LOCK_DIR}/pid"
    return 0
}

# forge_lock_release — unconditional release. Safe to call without holding.
forge_lock_release() {
    rm -rf "$FORGE_LOCK_DIR" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# State I/O
# ---------------------------------------------------------------------------

# _forge_state_read — read state.json into stdout. Recovers from corruption.
_forge_state_read() {
    if [ ! -f "$FORGE_STATE_FILE" ]; then
        printf '%s' "$FORGE_EMPTY_STATE"
        return 0
    fi
    local content
    content=$(cat "$FORGE_STATE_FILE" 2>/dev/null || true)
    if [ -z "$content" ]; then
        printf '%s' "$FORGE_EMPTY_STATE"
        return 0
    fi
    if ! printf '%s' "$content" | jq -e . >/dev/null 2>&1; then
        _forge_log "state.json corrupted — resetting to empty"
        printf '%s' "$FORGE_EMPTY_STATE"
        return 0
    fi
    printf '%s' "$content"
}

# _forge_state_write — atomic write (tmp + mv). Input on stdin.
_forge_state_write() {
    local tmp="${FORGE_STATE_FILE}.tmp.$$"
    cat > "$tmp" || {
        _forge_log "cannot write ${tmp} — disk full"
        rm -f "$tmp" 2>/dev/null || true
        return 1
    }
    mv -f "$tmp" "$FORGE_STATE_FILE" || {
        _forge_log "cannot rename ${tmp} → ${FORGE_STATE_FILE}"
        rm -f "$tmp" 2>/dev/null || true
        return 1
    }
    return 0
}

# _forge_purge_expired — apply TTL filter to state JSON on stdin. See RUNTIME.md §7.
_forge_purge_expired() {
    local now cutoff
    now=$(_forge_now_epoch)
    cutoff=$(( now - FORGE_SESSION_TTL_SECONDS ))
    jq --argjson cutoff "$cutoff" '
        .sessions |= with_entries(
            select(
                (.value.last_accessed_at | fromdateiso8601) >= $cutoff
            )
        )
    '
}

# _forge_touch_session — ensure session entry exists and update last_accessed_at.
# Input: state JSON on stdin. Args: session_id. Output: mutated state.
_forge_touch_session() {
    local sid="$1"
    local now
    now=$(_forge_now_iso8601)
    jq --arg sid "$sid" --arg now "$now" '
        if .sessions[$sid] == null then
            .sessions[$sid] = {
                "created_at": $now,
                "last_accessed_at": $now,
                "flags": {},
                "behaviors": {}
            }
        else
            .sessions[$sid].last_accessed_at = $now
            | (.sessions[$sid].flags //= {})
            | (.sessions[$sid].behaviors //= {})
        end
    '
}

# ---------------------------------------------------------------------------
# Atomic public mutations
# ---------------------------------------------------------------------------

# _forge_run_mutation — acquire lock, read+purge state, pipe through a jq
# expression, write back, release lock. Central choke point for mutations.
#
# Args:
#   $1: jq filter (stdin=state, stdout=mutated state)
#   $@: additional args appended to jq invocation (e.g. --arg key value)
#
# On lock timeout: logs warning, returns 1, does NOT mutate.
# On jq failure: logs warning, returns 1, does NOT write.
_forge_run_mutation() {
    local filter="$1"
    shift
    forge_init || return 1
    if ! forge_lock_acquire; then
        _forge_log "state lock timeout — using default levels"
        return 1
    fi
    # shellcheck disable=SC2064
    trap "forge_lock_release" EXIT INT TERM
    local state purged mutated
    state=$(_forge_state_read)
    purged=$(printf '%s' "$state" | _forge_purge_expired) || {
        _forge_log "purge failed — proceeding with unpurged state"
        purged="$state"
    }
    if ! mutated=$(printf '%s' "$purged" | jq "$@" "$filter" 2>/dev/null); then
        _forge_log "mutation filter failed — state unchanged"
        forge_lock_release
        trap - EXIT INT TERM
        return 1
    fi
    if ! printf '%s' "$mutated" | _forge_state_write; then
        forge_lock_release
        trap - EXIT INT TERM
        return 1
    fi
    forge_lock_release
    trap - EXIT INT TERM
    return 0
}

# forge_counter_increment — increment counter for behavior in session.
# Args: session_id behavior_id tool_name
# Prints new counter on stdout on success.
forge_counter_increment() {
    local sid="$1" bid="$2" tool="$3"
    local now
    now=$(_forge_now_iso8601)
    local filter='
        .sessions[$sid] //= {
            "created_at": $now,
            "last_accessed_at": $now,
            "flags": {},
            "behaviors": {}
        }
        | .sessions[$sid].last_accessed_at = $now
        | (.sessions[$sid].flags //= {})
        | (.sessions[$sid].behaviors //= {})
        | .sessions[$sid].behaviors[$bid] //= {
            "counter": 0,
            "effective_level": "silent",
            "last_violation_at": null,
            "last_violation_tool": null,
            "overrides": []
        }
        | .sessions[$sid].behaviors[$bid].counter += 1
        | .sessions[$sid].behaviors[$bid].last_violation_at = $now
        | .sessions[$sid].behaviors[$bid].last_violation_tool = $tool
    '
    if ! _forge_run_mutation "$filter" --arg sid "$sid" --arg bid "$bid" --arg now "$now" --arg tool "$tool"; then
        return 1
    fi
    jq -r --arg sid "$sid" --arg bid "$bid" \
        '.sessions[$sid].behaviors[$bid].counter' "$FORGE_STATE_FILE"
}

# forge_effective_level_set — write the effective level for a behavior.
# Args: session_id behavior_id level
# The caller is responsible for computing the monotonic max via forge_resolve_level.
forge_effective_level_set() {
    local sid="$1" bid="$2" level="$3"
    local filter='
        .sessions[$sid].behaviors[$bid].effective_level = $level
    '
    _forge_run_mutation "$filter" --arg sid "$sid" --arg bid "$bid" --arg level "$level"
}

# forge_flag_set — create or re-set a session flag. Idempotent.
# Args: session_id flag_name
forge_flag_set() {
    local sid="$1" flag="$2"
    local now
    now=$(_forge_now_iso8601)
    local filter='
        .sessions[$sid] //= {
            "created_at": $now,
            "last_accessed_at": $now,
            "flags": {},
            "behaviors": {}
        }
        | .sessions[$sid].last_accessed_at = $now
        | (.sessions[$sid].flags //= {})
        | (.sessions[$sid].behaviors //= {})
        | .sessions[$sid].flags[$flag] = {"set_at": $now}
    '
    _forge_run_mutation "$filter" --arg sid "$sid" --arg flag "$flag" --arg now "$now"
}

# forge_flag_check — returns 0 if flag present, 1 if absent. Read-only.
forge_flag_check() {
    local sid="$1" flag="$2"
    forge_init || return 1
    local state
    state=$(_forge_state_read)
    local present
    present=$(printf '%s' "$state" | jq -r --arg sid "$sid" --arg flag "$flag" \
        '.sessions[$sid].flags[$flag] // empty' 2>/dev/null)
    if [ -n "$present" ] && [ "$present" != "null" ]; then
        return 0
    fi
    return 1
}

# forge_flag_consume — atomically: check if present, delete if so.
# Returns 0 if flag was present and was deleted. Returns 1 if absent.
# Race-safe: competing consumes see the flag exactly once between them.
forge_flag_consume() {
    local sid="$1" flag="$2"
    forge_init || return 1
    if ! forge_lock_acquire; then
        _forge_log "state lock timeout — consume treated as absent"
        return 1
    fi
    # shellcheck disable=SC2064
    trap "forge_lock_release" EXIT INT TERM
    local state purged present
    state=$(_forge_state_read)
    purged=$(printf '%s' "$state" | _forge_purge_expired) || purged="$state"
    present=$(printf '%s' "$purged" | jq -r --arg sid "$sid" --arg flag "$flag" \
        '.sessions[$sid].flags[$flag] // empty' 2>/dev/null)
    if [ -z "$present" ] || [ "$present" = "null" ]; then
        # Still touch last_accessed_at so the session does not drift toward TTL.
        local now
        now=$(_forge_now_iso8601)
        local mutated
        mutated=$(printf '%s' "$purged" | _forge_touch_session "$sid") || mutated="$purged"
        printf '%s' "$mutated" | _forge_state_write || true
        forge_lock_release
        trap - EXIT INT TERM
        return 1
    fi
    local now mutated
    now=$(_forge_now_iso8601)
    mutated=$(printf '%s' "$purged" | jq --arg sid "$sid" --arg flag "$flag" --arg now "$now" '
        .sessions[$sid].last_accessed_at = $now
        | del(.sessions[$sid].flags[$flag])
    ')
    printf '%s' "$mutated" | _forge_state_write
    forge_lock_release
    trap - EXIT INT TERM
    return 0
}

# ---------------------------------------------------------------------------
# Level resolution (pure function)
# ---------------------------------------------------------------------------

# forge_resolve_level — compute level from counter + default + escalation JSON.
# Args:
#   $1: counter (integer)
#   $2: default_level (string)
#   $3: escalation JSON array — e.g. '[{"after":1,"level":"nudge"},...]'
# Prints the resolved level on stdout.
forge_resolve_level() {
    local counter="$1" default="$2" escalation="$3"
    printf '%s' "$escalation" | jq -r --argjson c "$counter" --arg d "$default" '
        ([.[] | select(.after <= $c)] | sort_by(.after) | last | .level) // $d
    '
}

# forge_level_max — return the higher of two levels (monotonic comparator).
forge_level_max() {
    local a="$1" b="$2"
    local rank_a rank_b
    case "$a" in silent) rank_a=0;; nudge) rank_a=1;; warning) rank_a=2;;
        soft_block) rank_a=3;; hard_block) rank_a=4;; *) rank_a=0;; esac
    case "$b" in silent) rank_b=0;; nudge) rank_b=1;; warning) rank_b=2;;
        soft_block) rank_b=3;; hard_block) rank_b=4;; *) rank_b=0;; esac
    if [ "$rank_a" -ge "$rank_b" ]; then
        printf '%s' "$a"
    else
        printf '%s' "$b"
    fi
}

# ---------------------------------------------------------------------------
# Override audit (triple-write: state.json + overrides.log)
# ---------------------------------------------------------------------------

# forge_override_append — record a soft_block override.
# Args: session_id behavior_id tool_name tool_input_summary counter reason
forge_override_append() {
    local sid="$1" bid="$2" tool="$3" summary="$4" counter="$5" reason="${6:-}"
    local now
    now=$(_forge_now_iso8601)
    local filter='
        .sessions[$sid].behaviors[$bid].overrides += [{
            "timestamp": $now,
            "tool_name": $tool,
            "tool_input_summary": $summary,
            "counter_at_override": ($counter | tonumber),
            "reason": $reason
        }]
    '
    _forge_run_mutation "$filter" \
        --arg sid "$sid" --arg bid "$bid" --arg now "$now" \
        --arg tool "$tool" --arg summary "$summary" \
        --arg counter "$counter" --arg reason "$reason" || return 1
    # Append to permanent audit log (pipe-delimited).
    printf '%s|%s|%s|%s|%s|%s|%s\n' \
        "$now" "$sid" "$bid" "$tool" "$summary" "$counter" "$reason" \
        >> "$FORGE_AUDIT_LOG"
}

# ---------------------------------------------------------------------------
# Debug / test helpers
# ---------------------------------------------------------------------------

# forge_state_dump — read current state to stdout without mutating.
forge_state_dump() {
    forge_init || return 1
    _forge_state_read
}

# forge_state_reset — wipe state.json to empty. Test use only.
forge_state_reset() {
    forge_init || return 1
    printf '%s\n' "$FORGE_EMPTY_STATE" > "$FORGE_STATE_FILE"
}
