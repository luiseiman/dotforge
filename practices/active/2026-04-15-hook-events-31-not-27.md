---
id: hook-events-31-not-27
source: watch:code.claude.com/docs/en/hooks
status: active
captured: 2026-04-15
tags: [hooks, domain-knowledge, drift, high-priority]
tested_in: []
incorporated_in: [v3.1.0]
---

# Hook event count: 27 → 31

## Observation

`.claude/rules/domain/hook-architecture.md` declares "Events (27 total, verified v2.1.92)".
Official reference at https://code.claude.com/docs/en/hooks now lists **31 hook events**
across three lifecycle cadences:

- Session-Level (3): `SessionStart`, `SessionEnd`, `InstructionsLoaded`
- Turn-Level (3): `UserPromptSubmit`, `Stop`, `StopFailure`
- Tool Loop (5): `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`, `PermissionDenied`
- Async/Side (20): `Notification`, `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`,
  `TeammateIdle`, `ConfigChange`, `CwdChanged`, `FileChanged`, `WorktreeCreate`, `WorktreeRemove`,
  `PreCompact`, `PostCompact`, `Elicitation`, `ElicitationResult`

`InstructionsLoaded` is mentioned in our rule but not counted. `Elicitation`/`ElicitationResult`
are not documented at all.

## Action

Update `hook-architecture.md`:
1. Change "27 total" → "31 total, verified v2.1.108"
2. Add `InstructionsLoaded` to Session-Level group
3. Add `Elicitation`/`ElicitationResult` to Async/Side
4. Note that `PreCompact` is now blockable (exit 2 prevents compaction)
5. Note `load_reason` field on `InstructionsLoaded`

## Affected files
- `.claude/rules/domain/hook-architecture.md`
- `.claude/rules/domain/hook-events.md` (Elicitation details)
