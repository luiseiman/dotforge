---
globs: "**/*.sh,**/settings.json"
description: "Hook event payloads and per-event behavior details"
domain: claude-code-engineering
last_verified: 2026-04-05
---

# Hook Event Details

## Context events

- PostCompact command: `trigger` ("auto"/"manual") + `compact_summary` (full text)
- PostCompact SDK: `compactType` + `messageCountBefore` + `messageCountAfter`
- PreCompact: `compactType` + `messageCount` — NON-BLOCKING, exit code ignored
- SessionStart `source`: "startup", "resume", "compact", "clear"
- CwdChanged: fires on directory change, supports CLAUDE_ENV_FILE
- FileChanged: fires on external file modification — use for auto-reload

## Tool events

- PostToolUseFailure: fires when tool execution fails — use for error tracking
- TaskCreated/TaskCompleted: agent lifecycle — use for orchestration metrics

## Permission events

- PermissionRequest: intercept permission dialog, auto-allow/deny with exit 2
- PermissionDenied: audit trail. Can return `{retry: true}` to re-attempt

## Agent events

- SubagentStart: inject additionalContext into spawned subagent via stdout
- TeammateIdle: fires when a team member has no pending work
