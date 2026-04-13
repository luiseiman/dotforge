# Behavior Enforcement Specification v1

Formal semantics for dotforge v3.0 behavior governance.
This document is the single source of truth for enforcement levels, evaluation algorithm, and output protocol.

Reference: [DECISIONS.md](DECISIONS.md) for closed design decisions.

---

## 1. Canonical Level Table

| Level | Exit Code | Output Channel | Agent Sees | Override | Use Case |
|-------|-----------|---------------|------------|----------|----------|
| silent | 0 | none | nothing | n/a | telemetry-only, baseline counting |
| nudge | 0 | stdout JSON `systemMessage` (1 line) | neutral reminder | n/a | gentle first reminder |
| warning | 0 | stdout JSON `systemMessage` (2-4 lines) | firm warning with expected behavior and correction | n/a | repeated violation, clear guidance |
| soft_block | 0 | stdout JSON `hookSpecificOutput` + `systemMessage` | block with correction instruction; override available | yes, audited | serious violation, escapable |
| hard_block | 0 | stdout JSON `hookSpecificOutput` + `systemMessage` | definitive block, no escape | no (v3.0) | safety-critical, non-negotiable |

All levels exit 0. Enforcement is communicated via JSON stdout, not exit codes.
Exit code 2 remains available for v2.9 compatibility hooks but is NOT used by behavior-generated hooks.

---

## 2. Evaluation Algorithm

Pseudocode for the behavior evaluation loop executed by a compiled hook on each tool call.

```
FUNCTION evaluate_behaviors(tool_call, hook_event, behaviors_index):
  # 1. Load ordered behavior list
  behaviors = read_index("behaviors/index.yaml")
  state = lock_and_read(".forge/runtime/state.json")
  session = get_or_create_session(state, session_id)

  accumulated_outputs = []
  block_hit = false

  # 2. Evaluate each behavior in declaration order
  FOR behavior IN behaviors:
    IF NOT behavior.enabled:
      CONTINUE

    IF NOT matches_event(behavior, hook_event):
      CONTINUE

    IF NOT matches_applies_to(behavior, tool_call):
      CONTINUE

    # 3. Evaluate each trigger in declaration order.
    #    Triggers dispatch by action. See Section 2.3 for flag semantics.
    violation_occurred = false
    FOR trigger IN behavior.policy.triggers:
      IF NOT trigger_matches(trigger, hook_event, tool_call):
        CONTINUE

      action = trigger.action OR "evaluate"

      IF action == "set_flag":
        session.flags[trigger.flag] = {"set_at": NOW()}
        CONTINUE  # no counter, no output

      IF action == "check_flag":
        IF trigger.flag IN session.flags:
          IF trigger.on_present == "consume":
            DELETE session.flags[trigger.flag]
          # on_present: keep → leave as-is
          CONTINUE  # no counter, no output
        ELSE:
          IF trigger.on_absent == "skip":
            CONTINUE
          # on_absent: violate → fall through to the standard evaluate path below
          violation_occurred = true
          BREAK

      IF action == "evaluate":
        violation_occurred = true
        BREAK

    IF NOT violation_occurred:
      CONTINUE

    # 4. Increment counter BEFORE level calculation
    session.behaviors[behavior.id].counter += 1
    session.behaviors[behavior.id].last_violation_at = NOW()
    session.behaviors[behavior.id].last_violation_tool = tool_call.tool_name

    # 5. Calculate effective level (monotonic)
    calculated_level = resolve_level(
      behavior.policy.enforcement,
      session.behaviors[behavior.id].counter
    )
    previous_level = session.behaviors[behavior.id].effective_level
    effective_level = max_level(previous_level, calculated_level)
    session.behaviors[behavior.id].effective_level = effective_level

    # 6. Generate output for this behavior
    output = render_output(behavior, effective_level)
    accumulated_outputs.append(output)

    # 7. First block cuts chain
    IF effective_level IN [soft_block, hard_block]:
      block_hit = true
      BREAK

  # 8. Write state and release lock
  update_last_accessed(session)
  purge_expired_sessions(state)  # inline TTL cleanup
  write_and_unlock(state)

  # 9. Merge and emit output
  RETURN merge_outputs(accumulated_outputs, block_hit)
```

### 2.1 resolve_level

```
FUNCTION resolve_level(enforcement, counter):
  # Walk escalation thresholds from highest to lowest
  FOR threshold IN enforcement.escalation SORTED BY after DESC:
    IF counter >= threshold.after:
      RETURN threshold.level
  RETURN enforcement.default_level
```

### 2.2 max_level

Level ordering: silent < nudge < warning < soft_block < hard_block.
`max_level(a, b)` returns the higher of the two.

### 2.3 Flag actions

Triggers with `action: set_flag` or `action: check_flag` do not participate in the counter/level/rendering path. Their effect is limited to the `session.flags` map:

```
# set_flag: unconditional mark
FUNCTION apply_set_flag(session, trigger):
  session.flags[trigger.flag] = {"set_at": NOW()}
  # Idempotent — re-setting updates set_at but does not duplicate the entry.

# check_flag: read-and-maybe-consume
FUNCTION apply_check_flag(session, trigger):
  IF trigger.flag IN session.flags:
    IF trigger.on_present == "consume":
      DELETE session.flags[trigger.flag]
    # on_present: keep → no state mutation
    RETURN "pass"       # no violation, continue to next trigger
  ELSE:
    IF trigger.on_absent == "skip":
      RETURN "pass"
    # on_absent: violate
    RETURN "violate"    # fall through to the standard evaluate path
```

Properties:

- Flag actions never emit output of their own. Output is produced only by the `evaluate` path, reached from `check_flag` via `on_absent: violate`.
- Flag actions never cut the chain. Only `evaluate` triggers that resolve to `soft_block` or `hard_block` cut the chain.
- Flag actions do not increment counters. A `check_flag` that routes to `violate` increments the counter once, exactly as an `evaluate` trigger would.
- Within a single behavior, multiple triggers are evaluated in declaration order. The first `violate` result or first `evaluate` match stops further trigger evaluation for that behavior (one violation per behavior per tool call, per SPEC §3.1).

See [RUNTIME.md §4](RUNTIME.md#4-flags) for the storage shape and concurrency semantics of `session.flags`.

### 2.4 merge_outputs

```
FUNCTION merge_outputs(outputs, block_hit):
  IF block_hit:
    # Last output is the block — emit it directly
    RETURN outputs[-1]

  IF outputs is empty:
    # No violations — silent pass
    RETURN {}

  # Concatenate all non-blocking messages
  messages = [o.systemMessage FOR o IN outputs WHERE o.systemMessage]
  IF messages:
    RETURN {"systemMessage": join(messages, "\n\n")}

  RETURN {}
```

---

## 3. Escalation Mechanics

### 3.1 Counter rules

- One counter per behavior per session
- Increments by 1 on each violation (triggered tool call)
- **One violation per behavior per tool call** — even if multiple triggers match internally
- Counter increments BEFORE level calculation (the first violation sees counter=1, not 0)
- Counter never decreases within a session
- Counter resets when session expires via TTL purge
- Triggers with `action: set_flag` or `action: check_flag` (when routing to `on_present` or `on_absent: skip`) do **not** increment counters. Only `evaluate` triggers and `check_flag` triggers routing to `on_absent: violate` count as violations.

### 3.2 Monotonic effective level

The effective level for a behavior within a session can only rise, never fall.
If the calculated level from the current counter is lower than the previously stored effective level, the stored level is preserved.

### 3.3 Escalation threshold format

Defined in `behavior.yaml` under `policy.enforcement.escalation`:

```yaml
enforcement:
  default_level: silent
  escalation:
    - after: 1    # counter >= 1
      level: nudge
    - after: 3    # counter >= 3
      level: warning
    - after: 5    # counter >= 5
      level: soft_block
```

Resolution: walk thresholds from highest `after` to lowest. First match wins.
If counter is 0 (no violations yet), no evaluation occurs (the trigger didn't match).

---

## 4. Chain Rules

### 4.1 Evaluation order

Behaviors are evaluated in the order declared in `behaviors/index.yaml`.
This order is deterministic and under user control.

### 4.2 First block cuts chain

When a behavior's effective level is `soft_block` or `hard_block`, evaluation stops immediately.
No subsequent behaviors in the chain are evaluated for this tool call.

### 4.3 Non-blocking accumulation

All non-blocking violations (silent, nudge, warning) accumulate.
Their outputs are merged and presented together after the full chain completes.

### 4.4 Silent behavior

A `silent` behavior still increments its counter and updates state.
It produces no output. It never cuts the chain.

---

## 5. Output Protocol

All behavior hook output is JSON on stdout. Hooks always exit 0.

### 5.1 No violation (pass)

No output. Empty stdout. Exit 0.

### 5.2 silent

No output. Counter incremented in state.json only.

### 5.3 nudge

```json
{
  "systemMessage": "search-first: Consider using Grep or Glob before writing code (violation 2/5)"
}
```

Exit 0. The `systemMessage` is injected into the agent's context as a system reminder.
Maximum 1 line (~120 chars). Must include behavior name and counter context.

### 5.4 warning

```json
{
  "systemMessage": "**[search-first]** You have written code 3 times without searching first.\nExpected: use Grep/Glob to find existing patterns before implementing.\nAction: search for related code, then proceed.\nNext violation triggers a block."
}
```

Exit 0. The `systemMessage` is 2-4 lines. Must include:
- Behavior name (bold)
- What happened (violation description)
- What was expected
- What to do now
- What happens next (escalation preview)

### 5.5 soft_block

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny"
  },
  "systemMessage": "**[search-first] BLOCKED:** You must search the codebase before writing new code.\nRun Grep or Glob first, then retry.\nThis block can be overridden — the user will be prompted to allow or deny."
}
```

Exit 0. The `permissionDecision: "deny"` triggers Claude Code's native permission denial flow.
The `systemMessage` explains why and how to proceed.
The user sees a permission prompt and can choose to override.

When overridden, the override is recorded in three places (see [Section 6](#6-override-protocol)).

### 5.6 hard_block

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "override_allowed": false
  },
  "systemMessage": "**[no-destructive-git] BLOCKED:** Force push to main/master is permanently blocked.\nThis restriction cannot be overridden."
}
```

Exit 0. Same structure as soft_block but with `override_allowed: false`.
No override is possible in v3.0.

> **Note:** The `override_allowed` field is included explicitly in both soft_block (`true` implied by absence) and hard_block (`false`). Soft_block omits `override_allowed` because Claude Code's default behavior when `permissionDecision: "deny"` is to show the override prompt. Hard_block sets `override_allowed: false` to signal that the denial is final.

### 5.7 Multiple non-blocking outputs

When multiple behaviors produce nudge/warning on the same tool call:

```json
{
  "systemMessage": "search-first: Consider using Grep or Glob before writing code (violation 2/5)\n\n**[verify-before-done]** Reminder: run tests before marking task complete."
}
```

Messages are concatenated with `\n\n` separator. Order follows index.yaml declaration order.

---

## 6. Override Protocol

Overrides apply only to `soft_block` level.

### 6.1 Flow

1. Behavior hook emits `permissionDecision: "deny"` + `systemMessage`
2. Claude Code's native permission system presents the denial to the user
3. User chooses to allow (override) or deny (respect block)
4. If overridden, Claude Code re-invokes the tool — the hook fires again
5. The hook detects the override via the PermissionDenied→allow flow and records the audit trail

### 6.2 Override detection (reinvocation pattern)

Claude Code does NOT fire a `PermissionDenied` event when a `PreToolUse` hook emits `permissionDecision: "deny"` — `PermissionDenied` is scoped to auto-mode classifier denials only. Phase 0 verified this empirically.

Therefore the compiled hook detects overrides through the reinvocation pattern: after emitting a `soft_block`, the hook writes a short-lived `pending_block` into the behavior state (`tool_input_hash` + `blocked_at`). On the next invocation of the same hook, it compares the incoming `tool_input_hash` against the stored one within a configurable window (default 60s). A match within the window is treated as reinvocation after user override: the hook records the audit entry, clears the `pending_block`, and passes through silently.

See [RUNTIME.md §12](RUNTIME.md#12-override-detection-via-reinvocation) for the complete semantics, field shapes, and edge cases.

### 6.3 Triple-write audit

Every override is recorded in three locations:

| Location | Scope | Persistence | Format |
|----------|-------|-------------|--------|
| `.forge/audit/overrides.log` | permanent | committed to git | pipe-delimited append-only |
| `.forge/runtime/state.json` | session | TTL 24h | JSON array in behavior's `overrides[]` |
| `registry/projects.yml` metrics | project | permanent | aggregated `override_rate` |

Fields per override record:
- `timestamp` — ISO 8601
- `session_id` — from hook payload
- `behavior_id` — which behavior was overridden
- `tool_name` — which tool triggered the block
- `tool_input_summary` — first 100 chars of tool input, sanitized
- `counter_at_override` — violation count at override moment

See [AUDIT.md](AUDIT.md) for exact formats.

---

## 7. Edge Cases

### 7.1 Multiple behaviors at same level on same tool call

All non-blocking behaviors (silent/nudge/warning) accumulate. Their outputs merge.
If two behaviors both resolve to soft_block, only the first (by index.yaml order) fires — it cuts the chain.

### 7.2 Counter at 0 (no prior violations)

If a behavior's trigger matches for the first time, counter goes from 0 to 1.
Level is resolved against counter=1. If `default_level` is `silent` and first escalation is `after: 1, level: nudge`, the agent sees a nudge on first violation.

### 7.3 TTL expired mid-conversation

If the session entry in state.json has `last_accessed_at` older than 24h, it is purged during the next access. The behavior starts fresh with counter=0. This is by design — the session is considered stale.

### 7.4 Hook timeout

If the behavior hook exceeds the configured timeout (default: 10 minutes for tool hooks), Claude Code kills the process. The tool call proceeds as if no hook fired. State may be partially written — the lock file must be cleaned up by the next invocation.

### 7.5 jq not available

`jq` is a runtime dependency. If not found, the hook emits a warning to stderr and exits 0 (allow). The behavior degrades to silent pass-through. A SessionStart hook should check for `jq` and warn the user.

### 7.6 state.json locked by concurrent process

The hook attempts to acquire the lock with a 2-second timeout. On timeout, the hook proceeds with `default_level` for all behaviors (no state read/write). A warning is logged to stderr. The tool call is not blocked by lock contention.

### 7.7 state.json corrupted (truncated write)

On JSON parse failure, the hook replaces state.json with an empty object `{}`. All sessions and counters are lost. A warning is logged to stderr. Behaviors restart from counter=0.

### 7.8 Behavior with no matching triggers

If a behavior has no triggers matching the current hook event, it is skipped entirely. No counter increment, no output.

### 7.9 Empty behaviors/index.yaml

If no behaviors are declared, the hook exits 0 immediately. No state access.

---

## 8. Compatibility with v2.9

### 8.1 Exit code mapping

| v3.0 Level | v2.9 Exit Code | Notes |
|------------|---------------|-------|
| silent | 0 | identical |
| nudge | 0 | v2.9 had no equivalent |
| warning | 1 | v2.9 used exit 1 for warnings |
| soft_block | 2 (via JSON deny) | v2.9 used exit 2 for blocks |
| hard_block | 2 (via JSON deny) | v2.9 had no distinction |

### 8.2 Coexistence

v3.0 behavior hooks coexist with v2.9 hooks. Existing hooks (e.g., `block-destructive.sh`) continue using exit codes. Behavior-generated hooks use JSON output. Both patterns are valid in Claude Code's hook system.

Behavior hooks are registered AFTER existing hooks in settings.json. Existing hooks run first. If an existing hook blocks (exit 2), behavior hooks do not fire.

### 8.3 Migration path

v2.9 hooks are not automatically converted to behaviors. They continue working as-is.
Users can optionally replace v2.9 hooks with equivalent behaviors when the catalog covers the same functionality. This is opt-in, not forced.

---

## 9. Glossary

| Term | Definition |
|------|-----------|
| **behavior** | A declarative YAML resource defining an expected agent behavior, its enforcement policy, and its communication rendering |
| **violation** | A tool call that matches a behavior's trigger conditions |
| **trigger** | A set of conditions on tool_input and/or session_state that detect a violation |
| **level** | One of 5 enforcement severities: silent, nudge, warning, soft_block, hard_block |
| **effective level** | The current enforcement level for a behavior in a session, monotonically non-decreasing |
| **escalation** | The mapping from violation counter thresholds to enforcement levels |
| **counter** | Per-behavior, per-session integer tracking violation count |
| **override** | User decision to proceed despite a soft_block denial |
| **chain** | The ordered sequence of behavior evaluations per tool call |
| **index** | `behaviors/index.yaml` — the ordered list of active behaviors |
| **policy** | The behavioral expectation and enforcement rules (what to enforce) |
| **rendering** | The communication templates (how to tell the agent) |
