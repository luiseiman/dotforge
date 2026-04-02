---
globs: "**/*.sh,**/settings.json,**/settings.json.partial"
description: "Hook system design patterns and safety requirements"
domain: claude-code-engineering
last_verified: 2026-04-02
---

# Hook Architecture

## Events (25 total, source-verified)

Core: SessionStart, SessionEnd, Setup, Stop, StopFailure
Tool lifecycle: PreToolUse, PostToolUse, PostToolUseFailure
User: UserPromptSubmit, PermissionRequest, PermissionDenied, Elicitation, ElicitationResult
Agent: SubagentStart, SubagentStop, TeammateIdle, TaskCreated, TaskCompleted
Context: PreCompact, PostCompact, CwdChanged, FileChanged, InstructionsLoaded
System: ConfigChange, Notification, StatusLine, FileSuggestion

## Exit codes and types

- Exit codes: 0 = allow, 1 = warn/error (non-blocking), 2 = block (stops the operation)
- Hook types: `command` (bash), `http` (POST to URL), `prompt` (LLM decision), `agent` (subagent)
- In settings.json, hooks MUST be objects: {"type": "command", "command": "path/to/script.sh"}
- NEVER use plain strings — Claude Code rejects them silently

## Async hooks

- Declare `async: true` or `asyncRewake` in hook config, or stream `{"async":true}` as first JSON line
- Background hooks survive new user prompts but killed on hard cancel (Escape)
- Use for long-running validations that shouldn't block the main loop

## Timeouts

- Tool hooks: 10 minutes (TOOL_HOOK_EXECUTION_TIMEOUT_MS)
- SessionEnd hooks: 1.5 seconds default — session-report.sh MUST be fast
- Override: `hook.timeout` per-hook, or `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` env var

## Matchers and patterns

- Matchers: Bash, Read, Write, Edit, Grep, Glob — determine which tool triggers the hook
- Glob matching on tool names: `*` wildcard, prefix/suffix matching

## Key hooks

- block-destructive.sh: mandatory; supports profiles: minimal, standard, strict
- lint-on-save.sh: recommended; matcher = Write|Edit for post-save linting
- session-report.sh: runs on Stop; generates JSON metrics to ~/.claude/metrics/
- All hooks must be executable: chmod +x (permissions -rwxr-xr-x)
- Validate hooks with bash -n before deploying; shellcheck if available

## Event details

- PostCompact receives: `trigger` ("auto"/"manual") + `compact_summary` (full text) — VERIFIED
- PreCompact receives: `trigger` ("auto"/"manual") — NON-BLOCKING, exit code ignored
- SessionStart `source` field: "startup", "resume", "compact", "clear"
- PostToolUseFailure: fires when tool execution fails — use for error tracking
- FileChanged: fires on external file modification — use for auto-reload patterns
- TaskCreated/TaskCompleted: agent lifecycle — use for orchestration metrics
- PermissionDenied: audit trail for denied operations
- PermissionRequest: intercept permission dialog, can auto-allow/deny with exit 2
- SubagentStart: inject additionalContext into spawned subagent via stdout
- CwdChanged: fires on directory change, supports CLAUDE_ENV_FILE

## Plugin env vars

- `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${user_config.X}`
- Plugin options exposed as `CLAUDE_PLUGIN_OPTION_*` env vars
