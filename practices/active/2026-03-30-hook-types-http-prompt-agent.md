---
id: practice-2026-03-30-hook-types-http-prompt-agent
title: "Hook types http/prompt/agent not documented in claude-kit — only 'command' covered"
source: "watch-upstream — code.claude.com/docs/en/hooks"
source_type: research
discovered: 2026-03-30
status: active
tags: [hooks, documentation, hook-types]
tested_in: []
incorporated_in: [.claude/rules/domain/hook-architecture.md, stacks/hookify/rules/hookify.md]
replaced_by: null
effectiveness: not-applicable
error_type: null
---

## Description

Claude Code supports 4 hook handler types. claude-kit only documented `command`.

| Type | Description |
|------|-------------|
| `command` | Shell script (bash/powershell) |
| `http` | HTTP POST to endpoint |
| `prompt` | Single-turn LLM prompt for decision |
| `agent` | Spawn full subagent for verification |

## Incorporated

- Added hook types to `.claude/rules/domain/hook-architecture.md`
- Added "Hook types in settings.json" section to `stacks/hookify/rules/hookify.md` with examples
  and note that hookify generates `command` type; others must be added manually to settings.json
