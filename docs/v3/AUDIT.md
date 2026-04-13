# Audit Trail — dotforge v3.0 Behavior Governance

Specifies the triple-write audit architecture, overrides.log format, metrics exposed
to `/forge audit` and `/forge behavior status`, and integration with existing dotforge systems.

Reference: [SPEC.md](SPEC.md) Section 6 for the override protocol.
Reference: [RUNTIME.md](RUNTIME.md) Section 2 for the state.json schema.

---

## 1. Overview

Every soft_block override is recorded in three locations simultaneously. Each location serves
a distinct purpose; none is redundant.

| Location | Purpose | Scope | Persistence |
|----------|---------|-------|-------------|
| `.forge/audit/overrides.log` | Compliance audit trail | All time | Permanent — committed to git |
| `.forge/runtime/state.json` | Runtime inspection | Session (TTL 24h) | Ephemeral — gitignored |
| `registry/projects.yml` metrics | Cross-project trends | Snapshot | Permanent — committed to git |

**Why three places:**
- `overrides.log` — append-only, inspectable with grep, survives session resets. The authoritative record.
- `state.json` — in-memory view for the current session. Powers `/forge behavior status` without file parsing.
- Registry — aggregated `override_rate` enables cross-project governance dashboards and trend detection.

Directory layout:
```
.forge/
├── audit/
│   └── overrides.log   # permanent, committed to git
└── runtime/
    ├── state.json       # ephemeral, gitignored
    └── state.lock/      # transient mkdir lock
```

---

## 2. overrides.log Format

Location: `.forge/audit/overrides.log`

Append-only. One record per line. Pipe-delimited. No header row.

```
TIMESTAMP|SESSION_ID|BEHAVIOR_ID|TOOL_NAME|TOOL_INPUT_SUMMARY|COUNTER|REASON
```

**Example records:**
```
2026-04-13T12:15:00Z|a1b2c3d4|search-first|Edit|file_path=/src/utils.ts old_string=function|5|
2026-04-13T14:30:00Z|a1b2c3d4|search-first|Write|file_path=/src/new-module.ts content=import|7|urgent hotfix
2026-04-14T09:00:00Z|e5f6g7h8|search-first|Write|file_path=/tests/test_api.py content=def test|2|
2026-04-14T10:45:00Z|e5f6g7h8|verify-before-done|Bash|command=git commit -m "feat: add"|3|tests passed locally
2026-04-15T16:20:00Z|i9j0k1l2|search-first|Edit|file_path=/lib/parser.ts old_string=export|4|
```

**Field reference:**

| Field | Format | Notes |
|-------|--------|-------|
| `TIMESTAMP` | ISO 8601 with timezone (`Z` or offset) | UTC preferred |
| `SESSION_ID` | First 8 chars of Claude Code session UUID | From hook payload `session_id` |
| `BEHAVIOR_ID` | kebab-case behavior id | Matches `behavior.yaml` id field |
| `TOOL_NAME` | Tool that triggered the block | Write, Edit, Bash, etc. |
| `TOOL_INPUT_SUMMARY` | First 100 chars of key `tool_input` fields | Pipe chars escaped as `\|`, newlines as `\n` |
| `COUNTER` | Violation count at override moment | Integer; counter is already incremented (see SPEC.md §3.1) |
| `REASON` | User-provided reason string | Empty string if none; never contains pipe chars |

The `overrides[]` array in `state.json` (see RUNTIME.md §2) is the in-session subset of this log.
The log is the authoritative source; state.json is derived and ephemeral.

---

## 3. Log Rotation Policy

No rotation in v3.0. The file grows indefinitely.

Expected growth: fewer than 100 overrides per month for an active project equals fewer than 10 KB/month.
Rotation is reserved for v3.1 based on observed usage.

To count total overrides: `wc -l .forge/audit/overrides.log`

---

## 4. Metrics for /forge audit

The existing 13-item checklist and scoring formula (see `audit/scoring.md`) are unchanged.
Behavior governance metrics appear as a **separate section** appended after the checklist score.

**New section: Behavior Governance**

| Metric | Type | Source | Calculation |
|--------|------|--------|-------------|
| `behaviors_installed` | integer | `behaviors/*/behavior.yaml` file count | direct count |
| `behaviors_enabled` | integer | `behaviors/index.yaml` enabled entries | direct count |
| `violations_total` | integer | `state.json` sum of all counters | sum across all sessions and behaviors |
| `overrides_total` | integer | `overrides.log` line count | `wc -l` |
| `override_rate` | float | `overrides_total / violations_that_reached_block` | ratio; 0.0 if no blocks |
| `escalation_effectiveness` | string | threshold on `override_rate` | `healthy` < 0.3 / `review` 0.3–0.7 / `ineffective` > 0.7 |

**Display format in `/forge audit` output:**
```
── Behavior Governance ──
Installed: 6 (4 core, 2 opinionated)
Enabled:   4
Violations (current session): 12
Overrides (all time): 3
Override rate: 0.25 (healthy)
```

`escalation_effectiveness` interpretation:
- `healthy` — overrides are rare; enforcement is accepted
- `review` — override rate is high; consider adjusting thresholds or behavior wording
- `ineffective` — most blocks are overridden; the behavior adds friction without governance value

---

## 5. Metrics for /forge behavior status

Per-behavior display, sourced from `state.json` for the current session:

```
── search-first (core) ──
Status:    enabled
Counter:   4 (this session)
Level:     warning (escalates to soft_block at 5)
Overrides: 1 (this session)
Last:      2026-04-13T14:28:00Z via Write

── no-destructive-git (core) ──
Status:    enabled
Counter:   0
Level:     hard_block (always)
Overrides: 0
Last:      never
```

Session aggregate at bottom:
```
── Session Summary ──
Total violations: 12
Total overrides:  1
Active behaviors: 4/6
Session started:  2026-04-13T10:00:00Z
```

`Last` field shows `last_violation_at` and `last_violation_tool` from `state.json`.
`Level` shows `effective_level` with the next escalation threshold if applicable.

---

## 6. Registry Integration

New fields added to each project entry in `registry/projects.yml`:

```yaml
projects:
  - slug: soma
    # ... existing fields ...
    behaviors:
      installed: 6
      enabled: 4
      override_rate: 0.25
      last_audit: "2026-04-13"
```

These fields are snapshot values written by `/forge audit` when behavior governance is active.
They are not real-time. `override_rate` is computed from `overrides.log` at audit time.

`/forge status` can aggregate `override_rate` across projects to surface systemic governance gaps.

---

## 7. Integration with session-report.sh

Four new fields added to the JSON output written to `~/.claude/metrics/{slug}/{date}.json`
by the Stop hook (`hooks/session-report.sh`):

```json
{
  "behavior_violations": 12,
  "behavior_overrides": 1,
  "behaviors_active": 4,
  "behavior_blocks": 3
}
```

These fields are appended alongside existing fields (`sessions`, `errors_added`, `hook_blocks`,
`lint_blocks`, etc.). Backwards compatible — consumers that don't read these fields are unaffected.

`behavior_violations` — sum of all behavior counters in the current session from `state.json`.
`behavior_overrides` — count of overrides recorded in this session (from `state.json overrides[]`).
`behaviors_active` — count of enabled behaviors from `behaviors/index.yaml`.
`behavior_blocks` — number of soft_block or hard_block events this session (counter reached block threshold).

---

## 8. Audit Trail Security

- `.forge/audit/overrides.log` permissions: `0644`
- `.forge/audit/` is committed to git — permanent audit evidence
- `.forge/runtime/` is gitignored — ephemeral session state only
- `tool_input_summary` is truncated to 100 chars — no secrets in full form
- Pipe chars in `tool_input_summary` are escaped as `\|` before writing
- Newlines in `tool_input_summary` are escaped as `\n` before writing
- No tool input values beyond the summary are persisted in any audit location
- The `REASON` field must be sanitized to strip pipe chars before appending

---

## 9. Grep One-Liners

Useful commands for audit analysis:

```bash
# All overrides for a specific behavior
grep '|search-first|' .forge/audit/overrides.log

# Override count by behavior (ranked)
cut -d'|' -f3 .forge/audit/overrides.log | sort | uniq -c | sort -rn

# Overrides in last 7 days (macOS + Linux portable)
awk -F'|' -v d="$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)" '$1 >= d' .forge/audit/overrides.log

# Overrides by tool
cut -d'|' -f4 .forge/audit/overrides.log | sort | uniq -c | sort -rn

# All overrides with a non-empty reason
awk -F'|' '$7 != ""' .forge/audit/overrides.log

# Total override count
wc -l .forge/audit/overrides.log

# Override rate per behavior requires violations from state.json
# Use /forge behavior status — grep on overrides.log alone is insufficient for rate calculation
```
