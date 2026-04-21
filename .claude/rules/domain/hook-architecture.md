---
globs: "**/*.sh,**/settings.json,**/settings.json.partial"
description: "Hook system design patterns and safety requirements"
domain: claude-code-engineering
last_verified: 2026-04-21
---

# Hook Architecture

## Events (31 total, verified v2.1.114 — code.claude.com/docs/en/hooks)

Three lifecycle cadences:

**Session-level** (once per session): SessionStart, SessionEnd, InstructionsLoaded
**Turn-level** (once per user prompt): UserPromptSubmit, Stop, StopFailure
**Tool-loop** (every tool call): PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, PermissionDenied
**Async/side**: Notification, SubagentStart, SubagentStop, TaskCreated, TaskCompleted, TeammateIdle, ConfigChange, CwdChanged, FileChanged, WorktreeCreate, WorktreeRemove, PreCompact, PostCompact, Elicitation, ElicitationResult

`InstructionsLoaded` fires when CLAUDE.md or `.claude/rules/*.md` loads. `load_reason` field: `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`. Observability-only — no decision control.

`PreCompact` is **blockable** since v2.1.105 (exit 2 prevents compaction). Was non-blocking before.

`Elicitation`/`ElicitationResult` fire during MCP tool execution when an MCP server requests structured user input. Support `accept`/`decline`/`cancel` actions and field overrides.

## Exit codes, types, and decisions

- Exit codes: 0 = allow, 1 = warn (non-blocking), 2 = block
- PreToolUse: also supports `defer` (pause for SDK integrations, v2.1.89+)
- Types: `command` (bash), `http` (POST), `prompt` (LLM decision), `agent` (subagent)
- Hooks MUST be objects: `{"type": "command", "command": "path.sh"}`
- NEVER plain strings — Claude Code rejects them silently

## Conditional hooks (v2.1.85+)

- `if` field: filter by permission rule syntax (e.g., `"if": "Bash(git *)"`) — replaces matcher + script logic
- **`if` is evaluated ONLY on tool events** (PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest). Silently ignored on other events — hook fires unconditionally there. Writing `if: "Bash(git *)"` on a `Stop` or `SessionStart` hook is a no-op filter.

## Async, timeouts, matchers

- Async: `async: true` or stream `{"async":true}` as first JSON line
- Tool hooks: 10min timeout. SessionEnd: 1.5s default. Override: `hook.timeout`
- Matchers: Bash, Read, Write, Edit, Grep, Glob. Wildcard `*` supported

## Key hooks

- block-destructive.sh: mandatory; profiles: minimal, standard, strict
- lint-on-save.sh: matcher = Write|Edit for post-save linting
- session-report.sh: Stop event; JSON metrics to ~/.claude/metrics/
- All hooks: chmod +x, validate with `bash -n`, shellcheck if available

## Plugin system

- Env vars: `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${user_config.X}`
- Plugin options exposed as `CLAUDE_PLUGIN_OPTION_*` env vars
- `bin/` directory: executables added to PATH during skill/hook execution (v2.1.91+). Ship compiled helpers, scripts, CLIs alongside markdown instructions
