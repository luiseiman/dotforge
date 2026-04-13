# Runtime State Management — dotforge v3.0

Specifies the session state format, lifecycle, TTL purge, locking protocol, and counter mechanics
that implement the evaluation algorithm defined in [SPEC.md](SPEC.md) Section 2.

---

## 1. Overview

The runtime maintains per-session, per-behavior counters and effective levels across hook invocations.
State lives in a single JSON file: `.forge/runtime/state.json`.
Sessions are keyed by `session_id` from the Claude Code hook payload.
All state access is serialized via a mkdir-based lock.

Directory layout:

```
.forge/
├── runtime/
│   ├── state.json          # mutable session state (gitignored)
│   └── state.lock/         # mkdir lock directory (transient, gitignored)
└── audit/
    └── overrides.log       # permanent audit trail (NOT gitignored)
```

`.gitignore` entry required: `.forge/runtime/`
`.forge/audit/` is committed to git — it is permanent audit evidence.

---

## 2. state.json Schema

```json
{
  "schema_version": "1",
  "sessions": {
    "a1b2c3d4-e5f6-7890-abcd-ef1234567890": {
      "created_at": "2026-04-13T10:00:00Z",
      "last_accessed_at": "2026-04-13T14:30:00Z",
      "behaviors": {
        "search-first": {
          "counter": 4,
          "effective_level": "warning",
          "last_violation_at": "2026-04-13T14:28:00Z",
          "last_violation_tool": "Write",
          "flags": {},
          "pending_block": null,
          "overrides": [
            {
              "timestamp": "2026-04-13T12:15:00Z",
              "tool_name": "Edit",
              "tool_input_summary": "Edit file_path=/src/utils.ts old_stri...",
              "counter_at_override": 5,
              "reason": ""
            }
          ]
        },
        "no-destructive-git": {
          "counter": 0,
          "effective_level": "silent",
          "last_violation_at": null,
          "last_violation_tool": null,
          "flags": {},
          "pending_block": null,
          "overrides": []
        }
      }
    },
    "e5f6g7h8-1234-5678-abcd-000000000001": {
      "created_at": "2026-04-12T08:00:00Z",
      "last_accessed_at": "2026-04-12T16:00:00Z",
      "behaviors": {}
    }
  }
}
```

### Field reference

| Field | Type | Description |
|-------|------|-------------|
| `schema_version` | string | Always `"1"` in v3.0. Used for migration detection. |
| `sessions` | object | Map of `session_id → session entry`. |
| `created_at` | ISO 8601 | When the session entry was first created. |
| `last_accessed_at` | ISO 8601 | Updated on every hook invocation. TTL applies to this field. |
| `behaviors` | object | Map of `behavior_id → behavior state`. |
| `counter` | integer | Violation count. Increments before level resolution. Never negative. |
| `effective_level` | string | Monotonic level: silent \| nudge \| warning \| soft_block \| hard_block |
| `last_violation_at` | ISO 8601 \| null | Timestamp of last violation. Null until first violation. |
| `last_violation_tool` | string \| null | Tool name that caused last violation. Null until first violation. |
| `flags` | object | Key-value session flags set by PostToolUse `flag_on_match` triggers and cleared by PreToolUse `consume_flag`. Used for temporal behaviors (e.g., search-first). See SCHEMA.md Section 3. |
| `pending_block` | object \| null | Set when soft_block fires. Contains `tool_name`, `timestamp`, `counter_at_block`. Cleared on override detection or after 30s expiry. See SPEC.md Section 6.2. |
| `overrides` | array | Audit records for soft_block overrides in this session. Subset of `.forge/audit/overrides.log`. |

---

## 3. Session Lifecycle

### Creation

A session entry is created on first hook invocation for a given `session_id`.
Session ID comes from the hook's JSON stdin payload field `session_id` — Claude Code generates a UUID at init and includes it in all hook payloads (confirmed: present in PostCompact, PreToolUse, and all other hook events).

If `session_id` is absent (older Claude Code versions), use this portable fallback:

```bash
SESSION_ID=$(echo "$$-$PWD-$(date +%s)" | shasum | cut -d' ' -f1 | cut -c1-12)
```

`shasum` is available on both Linux and macOS (part of Perl core). The fallback produces a 12-char hex ID, stable within a process for the same second. Uses `$$` (PID), `$PWD`, and epoch seconds for uniqueness.

### Access

Every hook invocation updates `last_accessed_at` to the current UTC timestamp before releasing the lock.
This applies even when no behavior violation occurs.

### Expiry

Sessions with `last_accessed_at` older than 24 hours (86400 seconds) are purged.
TTL is measured from last access, not from creation.
Purge runs inline on every state access — no background job required.

---

## 4. Counter Mechanics

- Counter is per-behavior, per-session.
- Increments by 1 on each violation (triggered tool call). See SPEC.md Section 3.1.
- **Increments BEFORE level calculation** — the first violation resolves against counter=1.
- Never decreases within a session.
- Resets to 0 only when the session is purged by TTL.
- One violation per behavior per tool call, even if multiple triggers match internally.

Example sequence for `search-first` with `default_level: silent`, escalation `after: 1 → nudge`, `after: 3 → warning`, `after: 5 → soft_block`:

| Tool call | Counter after increment | Calculated level | Effective level |
|-----------|------------------------|-----------------|----------------|
| 1st       | 1                      | nudge           | nudge          |
| 2nd       | 2                      | nudge           | nudge          |
| 3rd       | 3                      | warning         | warning        |
| 4th       | 4                      | warning         | warning        |
| 5th       | 5                      | soft_block      | soft_block     |

---

## 5. Effective Level Calculation

Implements SPEC.md Section 2.1 (`resolve_level`) plus monotonic enforcement (Section 3.2).

```
# resolve_level: walk thresholds from highest after to lowest
FUNCTION resolve_level(enforcement, counter):
  FOR threshold IN enforcement.escalation SORTED BY after DESC:
    IF counter >= threshold.after:
      RETURN threshold.level
  RETURN enforcement.default_level

# monotonic: effective level can only rise
FUNCTION update_effective_level(behavior_state, enforcement):
  calculated = resolve_level(enforcement, behavior_state.counter)
  previous   = behavior_state.effective_level
  behavior_state.effective_level = max_level(previous, calculated)
```

Level ordering for `max_level`: `silent < nudge < warning < soft_block < hard_block`.

---

## 6. TTL Purge Protocol

Runs **inline on every state.json access**, after lock acquisition, before business logic.
Not a background job. Idempotent.

```bash
purge_expired_sessions() {
  local state_file="$1"
  local now
  now=$(date +%s)
  local cutoff=$((now - 86400))

  # For each session, check last_accessed_at epoch vs cutoff
  # Remove sessions where epoch(last_accessed_at) < cutoff
  jq --argjson cutoff "$cutoff" '
    .sessions |= with_entries(
      select(
        (.value.last_accessed_at | fromdateiso8601) >= $cutoff
      )
    )
  ' "$state_file" > "${state_file}.tmp" && mv "${state_file}.tmp" "$state_file"
}
```

If all sessions have expired, the result is:

```json
{"schema_version": "1", "sessions": {}}
```

---

## 7. Locking Protocol

Uses mkdir-based locking — POSIX-portable, works on macOS and Linux without flock.

Lock path: `.forge/runtime/state.lock/` (a directory, not a file).

```bash
LOCK_DIR=".forge/runtime/state.lock"
LOCK_TIMEOUT=2  # seconds

acquire_lock() {
  local i
  for i in $(seq 1 20); do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      return 0
    fi
    sleep 0.1
  done
  return 1  # timeout after ~2s
}

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null
}
```

No PID file inside the lock directory — `rmdir` requires an empty directory and is atomic.
Stale lock recovery: if a process crashes without calling `release_lock`, the next invocation's 2s timeout will expire. The hook then proceeds with `default_level` (see below). On next successful acquisition, the stale lock will have been cleaned up by the crashing process's shell trap or by manual intervention.

### Lock timeout behavior

On timeout (2 seconds elapsed without acquiring lock):
- Hook proceeds using `default_level` for all behaviors.
- No state is read or written.
- Warning logged to stderr: `[forge] state lock timeout — using default levels`
- Tool call is not blocked.

### Stale lock recovery

No PID tracking. If a process crashes without releasing the lock, the lock directory persists. Next invocation's 2s timeout expires → hook proceeds with `default_level`. The generated hook should register a shell EXIT trap to clean up:

```bash
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT
```

This covers normal exits, Ctrl+C (SIGINT), and SIGTERM. SIGKILL is untrappable — the lock persists until timeout handles it.

---

## 8. Concurrency Scenarios

### Multi-agent (VPS + local + Telegram)

Each Claude Code instance generates its own `session_id`. State is shared via `.forge/runtime/state.json`.
Lock serializes concurrent writes. Instances see independent session entries — counters do not cross-contaminate.
Brief lock contention resolves within milliseconds under normal load.

### Parallel tool calls within a single session

Claude Code executes up to 10 concurrent tool calls (per domain rule: `gW5 = 10`).
Each tool call triggers a PreToolUse hook. All hooks share the same `session_id`.
Lock serializes access — each hook reads, mutates, and writes state atomically.
Counter increments are cumulative: 10 concurrent triggers on the same behavior → counter increases by 10 (one per serialized write).

### Subagent with independent context

Subagents may receive the same `session_id` as the parent (shared counters — correct for session-scoped governance)
or a new `session_id` (independent counters — correct for subagent isolation).
Both cases are valid. The runtime handles both without special logic.

---

## 9. Error Recovery

| Condition | Action |
|-----------|--------|
| Corrupted `state.json` (JSON parse failure) | Replace with `{"schema_version": "1", "sessions": {}}`. Log warning to stderr. All counters reset. |
| Missing `.forge/` directory | `mkdir -p .forge/runtime .forge/audit` on first access. |
| Missing `state.json` | Create with `{"schema_version": "1", "sessions": {}}`. |
| Stale lock directory | 2s timeout expires, hook proceeds with default_level. Cleaned by shell EXIT trap or manually (`rmdir .forge/runtime/state.lock`). |
| Disk full on write | Log warning to stderr, proceed with `default_level`. Do not crash. |
| `jq` not available | Emit warning to stderr, exit 0 (allow). All behaviors degrade to silent pass-through. SessionStart hook must check for `jq`. |
| Hook timeout (10 min default) | Claude Code kills the process. Tool call proceeds. Lock must be cleaned by next invocation via stale lock detection. |

---

## 10. Full Access Sequence

Every hook invocation follows this sequence:

```
1. acquire_lock()
   → on timeout: use default_level, exit 0

2. read_or_initialize(".forge/runtime/state.json")
   → on parse failure: reset to empty, log warning

3. purge_expired_sessions(state)

4. get_or_create_session(state, session_id)

5. run evaluation loop (SPEC.md Section 2)
   → increment counters
   → resolve effective levels
   → accumulate outputs

6. update last_accessed_at

7. write_state(".forge/runtime/state.json")
   → on write failure: log warning, continue

8. release_lock()

9. emit JSON output to stdout, exit 0
```
