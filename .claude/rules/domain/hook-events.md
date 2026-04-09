---
globs: "**/*.sh,**/settings.json"
description: "Hook event payloads and per-event behavior details"
domain: claude-code-engineering
last_verified: 2026-04-07
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

- PreToolUse/PostToolUse: receive ABSOLUTE file paths since v2.1.90
- PostToolUseFailure: fires when tool execution fails — use for error tracking
- TaskCreated/TaskCompleted: agent lifecycle — use for orchestration metrics
- Hook output >50K chars: saved to disk, file path + preview sent (v2.1.89)

## Permission events

- PermissionRequest: intercept permission dialog, auto-allow/deny with exit 2
- PermissionDenied: fires on auto mode classifier denials only (not manual deny or PreToolUse block). Input: tool_name, tool_input, tool_use_id, reason. Return `{retry: true}` to allow retry
- PreToolUse `defer`: pause execution for async external approval (Slack, mobile notification). Combine with `asyncRewake: true` for human-in-the-loop flows (v2.1.89+)

## Agent events

- SubagentStart: inject additionalContext into spawned subagent via stdout
- TeammateIdle: fires when a team member has no pending work
