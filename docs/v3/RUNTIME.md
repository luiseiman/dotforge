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
      "flags": {
        "search_context_ready": {
          "set_at": "2026-04-13T14:29:30Z"
        }
      },
      "behaviors": {
        "search-first": {
          "counter": 4,
          "effective_level": "warning",
          "last_violation_at": "2026-04-13T14:28:00Z",
          "last_violation_tool": "Write",
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
          "pending_block": null,
          "overrides": []
        }
      }
    },
    "e5f6g7h8-1234-5678-abcd-000000000001": {
      "created_at": "2026-04-12T08:00:00Z",
      "last_accessed_at": "2026-04-12T16:00:00Z",
      "flags": {},
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
| `flags` | object | Map of `flag_name → flag entry`. Session-scoped, shared across behaviors. See [Section 4.1](#41-flags). |
| `flags.<name>.set_at` | ISO 8601 | Timestamp when the flag was set or last re-set. |
| `behaviors` | object | Map of `behavior_id → behavior state`. |
| `counter` | integer | Violation count. Increments before level resolution. Never negative. |
| `effective_level` | string | Monotonic level: silent \| nudge \| warning \| soft_block \| hard_block |
| `last_violation_at` | ISO 8601 \| null | Timestamp of last violation. Null until first violation. |
| `last_violation_tool` | string \| null | Tool name that caused last violation. Null until first violation. |
| `pending_block` | object \| null | Short-lived record emitted when a hook fires soft_block. Holds `tool_input_hash` and `blocked_at` (ISO 8601). Consumed by the next matching tool call to detect reinvocation after user override. Null in steady state. See Section 12. |
| `overrides` | array | Audit records for soft_block overrides in this session. Subset of `.forge/audit/overrides.log`. |

---

## 3. Session Lifecycle

### Creation

A session entry is created on first hook invocation for a given `session_id`.
Session ID comes from the hook's JSON stdin payload field `session_id` — Claude Code generates a UUID at init and includes it in all hook payloads (confirmed: present in PostCompact, PreToolUse, and all other hook events).

If `session_id` is absent (older Claude Code versions):

```bash
SESSION_ID=$(echo "${PWD}:${PPID}:$(date +%Y%m%d)" | md5sum | cut -c1-36)
```

This fallback is stable within a process tree on a given day, and deterministic across hooks in the same session.

### Access

Every hook invocation updates `last_accessed_at` to the current UTC timestamp before releasing the lock.
This applies even when no behavior violation occurs.

### Expiry

Sessions with `last_accessed_at` older than 24 hours (86400 seconds) are purged.
TTL is measured from last access, not from creation.
Purge runs inline on every state access — no background job required.

---

## 4. Flags

Flags are session-scoped boolean markers that enable temporal behaviors — behaviors that need to remember that something happened earlier in the same session (e.g., "a search tool was used before this write"). They exist alongside counters in the session state but are independent of any single behavior.

### 4.1 Lifecycle

- **Creation:** a trigger with `action: set_flag` creates or re-sets the named flag. Idempotent — re-setting updates `set_at`.
- **Consumption:** a trigger with `action: check_flag` and `on_present: consume` deletes the flag after reading it.
- **Persistence:** a trigger with `action: check_flag` and `on_present: keep` leaves the flag in place.
- **Expiry:** flags live until consumed or until the session is purged by TTL. No per-flag TTL in v1.

### 4.2 Shape

```json
"flags": {
  "search_context_ready": {
    "set_at": "2026-04-13T14:29:30Z"
  }
}
```

Only `set_at` is stored in v1. `set_by_tool`, `consumed_at`, and `consumed_by_tool` are reserved for future versions.

### 4.3 Properties

- **Session-scoped, not behavior-scoped.** Any behavior can set or check any flag. Sharing by convention: flag names should be descriptive (e.g., `search_context_ready`, not `flag1`).
- **No effect on counters.** Setting or checking a flag never increments a counter and never changes `effective_level`.
- **No effect on chain evaluation.** Flag triggers do not cut the chain even when another behavior produces a block on the same tool call.
- **Shape is closed.** DSL cannot read arbitrary flag fields. Flags are manipulated only via `set_flag` and `check_flag` actions. See SCHEMA.md for allowed trigger syntax.

### 4.4 Concurrency

Flag mutations go through the same lock as counter mutations — serialized by `acquire_lock`. Parallel tool calls that both attempt to set the same flag produce a single entry with the latest `set_at`. Parallel consume operations are race-safe: at most one sees the flag.

---

## 5. Counter Mechanics

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

## 6. Effective Level Calculation

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

## 7. TTL Purge Protocol

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

## 8. Locking Protocol

Uses mkdir-based locking — POSIX-portable, works on macOS and Linux without flock.

Lock path: `.forge/runtime/state.lock/` (a directory, not a file).

```bash
LOCK_DIR=".forge/runtime/state.lock"
LOCK_TIMEOUT=2  # seconds

acquire_lock() {
  local deadline=$(($(date +%s) + LOCK_TIMEOUT))
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    # Check for stale lock
    if [ -f "$LOCK_DIR/pid" ]; then
      local pid
      pid=$(cat "$LOCK_DIR/pid" 2>/dev/null)
      if [ -n "$pid" ] && ! kill -0 "$pid" 2>/dev/null; then
        # Process is dead — remove stale lock and retry once
        rm -rf "$LOCK_DIR"
        mkdir "$LOCK_DIR" 2>/dev/null && break
      fi
    fi
    if [ "$(date +%s)" -ge "$deadline" ]; then
      return 1  # timeout
    fi
    sleep 0.1
  done
  echo $$ > "$LOCK_DIR/pid"
  return 0
}

release_lock() {
  rm -rf "$LOCK_DIR"
}
```

### Lock timeout behavior

On timeout (2 seconds elapsed without acquiring lock):
- Hook proceeds using `default_level` for all behaviors.
- No state is read or written.
- Warning logged to stderr: `[forge] state lock timeout — using default levels`
- Tool call is not blocked.

### Stale lock detection

If `state.lock/` exists and the PID in `state.lock/pid` is not running (`! kill -0 $pid`),
the lock is stale. Remove it and retry lock acquisition once.

---

## 9. Concurrency Scenarios

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

## 10. Error Recovery

| Condition | Action |
|-----------|--------|
| Corrupted `state.json` (JSON parse failure) | Replace with `{"schema_version": "1", "sessions": {}}`. Log warning to stderr. All counters reset. |
| Missing `.forge/` directory | `mkdir -p .forge/runtime .forge/audit` on first access. |
| Missing `state.json` | Create with `{"schema_version": "1", "sessions": {}}`. |
| Stale lock directory | Check PID, `rm -rf` if process dead, retry once. |
| Disk full on write | Log warning to stderr, proceed with `default_level`. Do not crash. |
| `jq` not available | Emit warning to stderr, exit 0 (allow). All behaviors degrade to silent pass-through. SessionStart hook must check for `jq`. |
| Hook timeout (10 min default) | Claude Code kills the process. Tool call proceeds. Lock must be cleaned by next invocation via stale lock detection. |

---

## 11. Full Access Sequence

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

---

## 12. Override Detection via Reinvocation

Claude Code's native hook system does NOT fire a `PermissionDenied` event when a `PreToolUse` hook emits `permissionDecision: "deny"`. `PermissionDenied` fires only for auto-mode classifier denials. Confirmed empirically in Phase 0.

This means override detection cannot rely on a separate event hook. Instead, behavior hooks detect overrides via the **reinvocation pattern**: when a user approves a denied tool call, Claude Code re-invokes the same `PreToolUse` hook with the same `tool_input`. The hook observes that it just blocked the same input seconds ago and treats the new invocation as evidence of override.

### 12.1 pending_block shape

```json
"pending_block": {
  "tool_input_hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4",
  "blocked_at": "2026-04-13T14:30:05Z"
}
```

| Field | Type | Description |
|-------|------|-------------|
| `tool_input_hash` | string | First 40 hex chars of `sha256(canonical_json(tool_input))`. Stable for identical inputs. |
| `blocked_at` | ISO 8601 | UTC timestamp when the soft_block was emitted. |

### 12.2 Writer (on soft_block)

Inside the same state mutation that records the violation, when `effective_level` becomes `soft_block`:

1. Compute `tool_input_hash` from the incoming `tool_input` JSON (canonical serialization via `jq -S -c`).
2. Write `pending_block = {tool_input_hash, blocked_at}` into the behavior state.
3. Emit the standard soft_block JSON output and exit 0.

### 12.3 Reader (next invocation)

On every hook invocation, before counter increment:

1. Read `pending_block` for this behavior in this session.
2. If absent → normal evaluate path.
3. If present, compute `tool_input_hash` for the current incoming `tool_input`.
4. If the hash does NOT match the stored hash → clear `pending_block` (stale from a different tool call), continue to normal evaluate.
5. If the hash matches, check age: `now - blocked_at < FORGE_OVERRIDE_WINDOW_SECONDS` (default 60).
6. If stale (outside window) → clear `pending_block`, continue to normal evaluate.
7. If fresh match → **this is a reinvocation after user override**:
    - Append an entry to `overrides[]` with `{timestamp, tool_name, tool_input_summary, counter_at_override, reason: ""}`
    - Append a line to `.forge/audit/overrides.log`
    - Clear `pending_block`
    - Exit 0 with empty stdout (pass through silently — the user already approved once, don't re-block)

### 12.4 Properties

- **No counter mutation on override.** The override is a "pass", not a new violation. Counter stays at whatever it was.
- **One override per soft_block instance.** After the reinvocation is recorded, `pending_block` is cleared. The next Write must re-escalate if conditions hold.
- **Window is configurable.** `FORGE_OVERRIDE_WINDOW_SECONDS` env var. Default 60.
- **Stale pending_blocks self-heal.** If Claude Code never reinvokes (user denies, walks away, etc.), the `pending_block` lingers until the next invocation observes it as stale and clears it. No background job needed.
- **Hash collision safety.** SHA-256 truncated to 40 hex chars provides ~160 bits of collision resistance — sufficient for a per-session, per-behavior, 60-second window.
- **Different tool_input during retry = different operation.** If the user edits the file path between block and retry, hashes differ, `pending_block` is cleared as stale, and the new operation is evaluated fresh. This is by design: the override applies only to the exact operation that was blocked.

### 12.5 Limitations

- Cannot distinguish "user approved" from "Claude Code re-sent the same call autonomously within 60s for unrelated reasons". In practice the latter is extremely rare — Claude Code does not retry `PreToolUse` denials without user interaction.
- If a user runs the same operation twice within 60s on purpose (not an override, just a coincidence), the second one would be recorded as an override. Acceptable false positive given the alternative (missing all real overrides).
- First implementation in Phase 1. Signature refinement and window tuning may happen based on real usage in Phase 2+.

