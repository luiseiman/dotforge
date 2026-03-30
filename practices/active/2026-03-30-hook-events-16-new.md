---
id: practice-2026-03-30-hook-events-16-new
title: "16 new hook events not documented in hook-architecture.md (as of v2.1.76-v2.1.85)"
source: "watch-upstream — code.claude.com/docs/en/hooks + CHANGELOG"
source_type: research
discovered: 2026-03-30
status: active
tags: [hooks, documentation, hook-architecture]
tested_in: []
incorporated_in: [.claude/rules/domain/hook-architecture.md]
replaced_by: null
effectiveness: not-applicable
error_type: null
---

## Description

Claude Code now documents 25 hook events. hook-architecture.md only covered ~9. Missing events added in v2.1.76–v2.1.85.

## Incorporated

Added 4 high-value events to `.claude/rules/domain/hook-architecture.md`:
- PermissionRequest — intercept permission dialog, can auto-allow/deny
- SubagentStart — inject additionalContext into spawned subagent
- CwdChanged — directory changed mid-session, supports CLAUDE_ENV_FILE
- StopFailure — turn ended by API error (rate_limit, billing_error, etc.)

Also updated event list in header from 6 to 13 events.
Full list of 16 new events documented in the inbox practice file for reference.
