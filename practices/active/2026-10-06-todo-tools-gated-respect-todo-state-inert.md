---
id: practice-2026-10-06-todo-tools-gated-respect-todo-state-inert
title: TaskCreate/TodoWrite tools removed on Opus 4.8+/Sonnet 5+/Fable — respect-todo-state behavior is inert (v2.1.233, v2.1.268)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [behaviors, v3, tools, native-first, breaking-change]
tested_in: []
incorporated_in: ["behaviors/index.yaml", ".claude/rules/domain/agent-orchestration.md", ".claude/rules/domain/rule-effectiveness.md", ".claude/rules/domain/prompting-patterns.md", "global/settings.json.tmpl"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
- v2.1.233: task-tracking tools (`TaskCreate/Get/Update/List`, `TodoWrite`) no longer available on Opus 4.8, Sonnet 5, Fable 5, Mythos 5 and newer.
- v2.1.268: offered only on Claude 3.x, Opus 4.0–4.7, Sonnet 4.0–4.6, Haiku 4.5. `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` restores elsewhere. `TaskOutput` removed (v2.1.277).
- Confirmed live in this session (Fable 5.1): `TaskCreate/Get/List/Update` reported unavailable by the harness.

## Evidence
`behaviors/respect-todo-state/behavior.yaml` triggers on `TaskCreate`/`TaskUpdate`; compiled hook `.claude/hooks/generated/respect-todo-state__pretooluse__taskcreate__1.sh` never fires on current models. `agent-orchestration.md` lists `TodoWrite` in the background-safe tool set without caveat. `rule-effectiveness.md:69` and `prompting-patterns.md:33` treat "Use TodoWrite VERY frequently" as a hardcoded system-prompt instruction to override — stale.

## Impact on dotforge
- `behaviors/respect-todo-state/`: mark inert / require env var, or retire (ties into `native-vs-dotforge-boundary.md` behaviors verdict)
- `behaviors/index.yaml`: evaluation order
- `.claude/rules/domain/agent-orchestration.md`, `rule-effectiveness.md`, `prompting-patterns.md`: remove stale TodoWrite claims
- `template/settings.json.tmpl`: do NOT add `CLAUDE_CODE_ENABLE_TODO_TOOLS` by default (project `env` is honored, but opting back in should be per-project)

## Decision
Accepted 2026-10-06 — incorporated in dotforge v4.4.0 (/forge update, breaking batch).
