---
globs: "**/*.sh,**/settings.json,**/settings.json.partial"
description: "Hook system design patterns and safety requirements"
domain: claude-code-engineering
last_verified: 2026-04-05
---

# Hook Architecture

## Events (26 total, verified v2.1.90+)

Core: SessionStart, SessionEnd, Stop, StopFailure
Tool lifecycle: PreToolUse, PostToolUse, PostToolUseFailure
User: UserPromptSubmit
Permissions: PermissionRequest, PermissionDenied
Elicitation: Elicitation, ElicitationResult
Agent: SubagentStart, SubagentStop, TeammateIdle, TaskCreated, TaskCompleted
Context: PreCompact, PostCompact, CwdChanged, FileChanged, InstructionsLoaded
System: ConfigChange, Notification
Worktree: WorktreeCreate, WorktreeRemove

## Exit codes, types, and decisions

- Exit codes: 0 = allow, 1 = warn (non-blocking), 2 = block
- PreToolUse: also supports `defer` (pause for SDK integrations, v2.1.89+)
- Types: `command` (bash), `http` (POST), `prompt` (LLM decision), `agent` (subagent)
- Hooks MUST be objects: `{"type": "command", "command": "path.sh"}`
- NEVER plain strings — Claude Code rejects them silently

## Conditional hooks (v2.1.85+)

- `if` field: filter by permission rule syntax (e.g., `"if": "Bash(git *)"`) — replaces matcher + script logic

## Async, timeouts, matchers

- Async: `async: true` or stream `{"async":true}` as first JSON line
- Tool hooks: 10min timeout. SessionEnd: 1.5s default. Override: `hook.timeout`
- Matchers: Bash, Read, Write, Edit, Grep, Glob. Wildcard `*` supported

## Key hooks

- block-destructive.sh: mandatory; profiles: minimal, standard, strict
- lint-on-save.sh: matcher = Write|Edit for post-save linting
- session-report.sh: Stop event; JSON metrics to ~/.claude/metrics/
- All hooks: chmod +x, validate with `bash -n`, shellcheck if available

## Plugin env vars

- `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${user_config.X}`
- Plugin options exposed as `CLAUDE_PLUGIN_OPTION_*` env vars
