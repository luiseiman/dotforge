---
globs: "**/*.sh,**/settings.json"
description: "Hook event payloads and per-event behavior details"
domain: claude-code-engineering
last_verified: 2026-05-13
---

# Hook Event Details

## Context events

- PostCompact command: `trigger` ("auto"/"manual") + `compact_summary` (full text)
- PostCompact SDK: `compactType` + `messageCountBefore` + `messageCountAfter`
- PreCompact: `compactType` + `messageCount` — **BLOCKABLE since v2.1.105** (exit 2 prevents compaction)
- SessionStart `source`: "startup", "resume", "compact", "clear". dotforge wires three hooks here (v3.7.0+): `check-updates.sh` (version check), `session-restore.sh` (re-injects last-compact.md when source=compact), `session-startup.sh` (snapshot + drift detection on every other source — writes `.claude/session/last-startup.md` plus rotating `startup-history/<ISO>.md`, last 5)
- CwdChanged: fires on directory change, supports CLAUDE_ENV_FILE
- FileChanged: fires on external file modification — use for auto-reload
- InstructionsLoaded: fires when CLAUDE.md or `.claude/rules/*.md` loads. `load_reason`: `session_start` | `nested_traversal` | `path_glob_match` | `include` | `compact`. Observability-only, no decision control.
- Setup: fires for `--init-only` / `--maintenance` runs. Matchers: `init` | `maintenance`. Use for credential rotation, env-var provisioning, prerequisite checks BEFORE session starts. dotforge wires `pre-session-check.sh` (v3.7.0+) — validates settings.json JSON, behaviors/index.yaml YAML, all wired hooks present + executable, block-destructive.sh executable. Exit 2 blocks session start.

## Tool events

- PreToolUse/PostToolUse: receive ABSOLUTE file paths since v2.1.90
- PostToolUse/PostToolUseFailure: input includes `duration_ms` (v2.1.119+) — tool execution time excluding permission prompts and PreToolUse hooks. Use for per-tool latency metrics without external timing
- PostToolUseFailure: fires when tool execution fails — use for error tracking
- PostToolUse `continueOnBlock: true` (v2.1.139+) — when set in the hook config, a `decision: "block"` feeds the `reason` back to Claude and the turn continues instead of stopping. Use for non-fatal validators (lint, type-check, drift detection)
- PostToolUse `hookSpecificOutput.updatedToolOutput` (v2.1.121+): replaces tool output for the model. Pre-v2.1.121 was MCP-only (`updatedMCPToolOutput`); now works for Bash, Edit, Write, Read, etc. Use sparingly — rewriting can hide errors and breaks audit trail
- PostToolBatch (v2.1.x+): fires when a batch of parallel tool calls completes, before the next model call. No matcher. Blockable via `decision: "block"` — point of choice for end-of-batch validation
- UserPromptExpansion: fires when a slash command expands. Matcher: command name. Blockable — can prevent the expansion
- UserPromptSubmit: hook can return `hookSpecificOutput.sessionTitle: "..."` (v2.1.94+) to set the session display title (shown in `/resume` and terminal title)
- TaskCreated/TaskCompleted: agent lifecycle — use for orchestration metrics
- Hook output >50K chars: saved to disk, file path + preview sent (v2.1.89)

## Permission events

- PermissionRequest: intercept permission dialog, auto-allow/deny with exit 2
- PermissionDenied: fires on auto mode classifier denials only (not manual deny or PreToolUse block). Input: tool_name, tool_input, tool_use_id, reason. Return `{retry: true}` to allow retry
- PreToolUse `defer`: pause execution for async external approval (Slack, mobile notification). Combine with `asyncRewake: true` for human-in-the-loop flows (v2.1.89+)

## Agent events

- SubagentStart: inject additionalContext into spawned subagent via stdout
- TeammateIdle: fires when a team member has no pending work
- Subagent API requests carry `x-claude-code-agent-id` / `x-claude-code-parent-agent-id` headers (v2.1.139+); OTEL `claude_code.llm_request` spans include `agent_id` / `parent_agent_id` attributes — use for distributed tracing of agent trees

## Shared payload fields

- `session_id` — present in every hook input; matches `$CLAUDE_CODE_SESSION_ID` exported into Bash tool subprocesses (v2.1.132+)
- `effort.level` — present in every hook input (v2.1.133+); values `"low" | "medium" | "high" | "xhigh" | "max"`. Bash tool subprocesses see the same value as `$CLAUDE_EFFORT`. Enables effort-aware hook decisions (stricter at low, relaxed at max)
- `cwd` — absolute working directory
- `transcript_path` — path to the session transcript jsonl

## MCP elicitation events (v2.1.76+)

- Elicitation: fires when an MCP server requests structured user input mid-tool-call. Hook can return `action: "accept" | "decline" | "cancel"` and override field values via `content: {field: "new_value"}`
- ElicitationResult: fires after the user (or hook) responds. Observability + audit
- Combined with `disableSkillShellExecution` and managed settings, lets enterprises pre-validate MCP form submissions before they reach the server
