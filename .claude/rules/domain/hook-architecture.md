---
globs: "**/*.sh,**/settings.json,**/settings.json.partial"
description: "Hook system design patterns and safety requirements"
domain: claude-code-engineering
last_verified: 2026-05-13
---

# Hook Architecture

## Events (32+ total, verified 2026-05-05 — code.claude.com/docs/en/hooks)

Three lifecycle cadences:

**Session-level** (once per session): SessionStart, SessionEnd, InstructionsLoaded, Setup
**Turn-level** (once per user prompt): UserPromptSubmit, UserPromptExpansion, Stop, StopFailure
**Tool-loop** (every tool call): PreToolUse, PostToolUse, PostToolUseFailure, PostToolBatch, PermissionRequest, PermissionDenied
**Async/side**: Notification, SubagentStart, SubagentStop, TaskCreated, TaskCompleted, TeammateIdle, ConfigChange, CwdChanged, FileChanged, WorktreeCreate, WorktreeRemove, PreCompact, PostCompact, Elicitation, ElicitationResult

`Setup` fires for `--init-only` / `--maintenance` runs with matchers `init` and `maintenance` respectively. Use for env-var provisioning, credential rotation, prerequisite checks BEFORE the session starts. Distinct from `SessionStart` which fires on every session — `Setup` only fires when explicitly requested.

`PostToolUse.hookSpecificOutput.updatedToolOutput` was MCP-only before v2.1.121; **now works for ALL tools** (Bash, Edit, Write, Read, etc.). Design tradeoff: rewriting tool output can hide errors the model needs to see (e.g. failing tests passing silently), and creates audit-trail confusion (model-visible ≠ actual). Prefer `additionalContext` for augmentation; reserve `updatedToolOutput` for redaction (sensitive data) or compression (verbose-to-summary).

`InstructionsLoaded` fires when CLAUDE.md or `.claude/rules/*.md` loads. `load_reason` field: `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`. Observability-only — no decision control.

`PreCompact` is **blockable** since v2.1.105 (exit 2 prevents compaction). Was non-blocking before.

`UserPromptExpansion` fires when a slash command expands; matcher = command name; blockable (deny prevents the expansion). Useful for gating destructive or expensive commands.

`PostToolBatch` fires when a batch of parallel tool calls completes, before the next model call; no matcher; blockable via `decision: "block"`. Use for end-of-batch validation that would be redundant per-tool in PostToolUse.

`Elicitation`/`ElicitationResult` fire during MCP tool execution when an MCP server requests structured user input. Support `accept`/`decline`/`cancel` actions and field overrides.

## Exit codes, types, and decisions

- Exit codes: 0 = allow, 1 = warn (non-blocking), 2 = block
- PreToolUse: also supports `defer` (pause for SDK integrations, v2.1.89+)
- Types: `command` (bash), `http` (POST), `prompt` (LLM decision), `agent` (subagent), `mcp_tool` (v2.1.118+ — invoke an MCP tool directly with `${tool_input.*}` substitution)
- Hooks MUST be objects: `{"type": "command", "command": "path.sh"}`
- NEVER plain strings — Claude Code rejects them silently
- `continueOnBlock: true` on a PostToolUse hook (v2.1.139+) flips the contract: a `decision: "block"` no longer halts the turn — the hook's `reason` is fed back to Claude as feedback and the turn continues. Use for non-fatal validators (lint, type-check) so failures self-heal in the same turn instead of stopping the agent.

## Command hook forms

Two ways to spawn a `type: "command"` hook:

- **Shell form** (`command: "..."`): a single string, interpreted by `/bin/sh`. Convenient for pipes, redirects, and short scripts. Path placeholders need quoting: `"./hook.sh \"${tool_input.file_path}\""`.
- **Exec form** (`command + args: string[]`, v2.1.139+): spawns directly via `execve`, no shell. Path placeholders never need quoting. Safer when interpolating `${tool_input.*}` — eliminates shell injection via crafted payloads.

```json
{
  "type": "command",
  "command": ".claude/hooks/validate.sh",
  "args": ["${tool_input.file_path}", "--strict"]
}
```

Prefer exec form whenever the hook consumes user-controlled values.

## Effort visibility in hooks (v2.1.133+)

Every hook event's stdin JSON now includes `effort.level` (`"low" | "medium" | "high" | "xhigh" | "max"`). Bash tool subprocesses also see `$CLAUDE_EFFORT` with the same value. Enables effort-aware decisions — e.g. `block-destructive.sh` can tighten matching at `low`/`medium` and relax at `max`.

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
