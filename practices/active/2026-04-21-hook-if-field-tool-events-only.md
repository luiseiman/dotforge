---
id: hook-if-field-tool-events-only
source: watch:code.claude.com/docs/en/hooks
status: active
captured: 2026-04-21
tags: [hooks, drift, medium-priority, v2.1.85]
tested_in: []
incorporated_in: ['3.3.0']
---

# Hook `if` field is evaluated only on tool events

## Observation

Per the official hooks doc: the `if` field (permission-rule syntax like `Bash(git *)`, added v2.1.85) is evaluated **only on tool events**: `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `PermissionRequest`. On any other event type (`Stop`, `SessionStart`, `InstructionsLoaded`, etc.) the `if` field is silently ignored and the hook always fires.

Our `domain/hook-architecture.md` mentions the `if` field in the "Common hook fields" code sample but does not state this restriction. A contributor writing `if: "Bash(git *)"` on a `Stop` hook would get unexpected behavior — hook fires unconditionally.

## Required update

Add a clarifying note to `domain/hook-architecture.md` conditional hooks section:

```
- `if` evaluated ONLY on tool events (PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest). Silently ignored on other events — hook fires unconditionally there.
```

## Affected files

- `.claude/rules/domain/hook-architecture.md`
