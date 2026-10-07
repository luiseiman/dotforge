---
globs: "**/*.sh,**/settings.json,**/settings.json.partial"
description: "Hook system design patterns and safety requirements"
domain: claude-code-engineering
last_verified: 2026-10-06
---

# Hook Architecture

## Events (37 total, verified 2026-10-06 — code.claude.com/docs/en/hooks)

Five lifecycle cadences:

**Session-level** (once per session): SessionStart (matchers `startup|resume|clear|compact|fork`), SessionEnd (`clear|resume|logout|prompt_input_exit|other`), InstructionsLoaded, Setup
**Turn-level** (once per user prompt): UserPromptSubmit, UserPromptExpansion, Stop, StopFailure
**Tool-loop** (every tool call): PreToolUse, PostToolUse, PostToolUseFailure, PostToolBatch, PermissionRequest, PermissionDenied
**Display-level** (v2.1.152+, on each assistant message render): MessageDisplay
**Model switch** (v2.1.251+): PreModelSwitch (blockable — `permissionDecision` allow/deny/ask + reason), PostModelSwitch (observational, `additionalContext`). Matcher = model name. Use to pin production sessions to a vetted model or to annotate cost changes when `/model` or fallback switches
**Async/side**: Notification, SubagentStart, SubagentStop, TaskCreated, TaskCompleted, TeammateIdle, ConfigChange (`user_settings|project_settings|local_settings|policy_settings|skills`), CwdChanged, DirectoryAdded (v2.1.219+, matchers `slash_command|register_repo_root` — fires after `/add-dir` or the SDK registers a working directory mid-session), FileChanged (matcher = literal filename), WorktreeCreate, WorktreeRemove, PreCompact, PostCompact, Elicitation, ElicitationResult

`MessageDisplay` (v2.1.152+) is the first display-time event. It fires when assistant text is about to be rendered to the user; the hook can transform or hide the text. Use for output redaction (PII, secrets, internal IDs that leaked into tool output) or post-processing. Distinct from all prior events which are control-flow.

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
- Handler fields beyond `type`/`matcher`/`if`/`timeout`: `statusMessage` (custom spinner text), `once` (skills only — run once per session), `shell: bash|powershell` (command hooks), `async` + `asyncRewake` (background; rewake Claude on exit 2, ignores timeout — v2.1.219 docs), http `headers` + `allowedEnvVars` (env vars allowed to interpolate into headers), prompt/agent `model`. `agent`-type hooks do not run on PermissionRequest (v2.1.280)
- **Fail-closed (v2.1.248/288)**: stdout that looks like `{…}` but is invalid JSON is a hook error (was treated as plain text); PreToolUse/PermissionRequest hooks are blocked when matching fails or input cannot be serialized. dotforge template hooks emit plain text only; compiled behavior hooks use `jq -cn` — both safe
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

Prefer exec form whenever the hook consumes user-controlled values — and for every plugin hook: shell form with an unquoted `${CLAUDE_PLUGIN_ROOT}` breaks on install paths containing spaces (`claude plugin validate` warns since v2.1.281; an async Stop hook under `~/Library/Application Support` looped forever in v2.1.290). Since v2.1.248 a hook whose stdout is an invalid `{…}` JSON object is reported as a hook error (previously treated as plain text), and since v2.1.288 PreToolUse/PermissionRequest hooks fail closed when matching fails or the input cannot be serialized — every JSON-emitting hook must print strictly valid JSON or nothing.

## Effort visibility in hooks (v2.1.133+)

Every hook event's stdin JSON now includes `effort.level` (`"low" | "medium" | "high" | "xhigh" | "max"`). Bash tool subprocesses also see `$CLAUDE_EFFORT` with the same value. Enables effort-aware decisions — e.g. `block-destructive.sh` can tighten matching at `low`/`medium` and relax at `max`.

## Conditional hooks (v2.1.85+)

- `if` field: filter by permission rule syntax (e.g., `"if": "Bash(git *)"`) — replaces matcher + script logic
- **`if` is evaluated ONLY on tool events** (PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest). Silently ignored on other events — hook fires unconditionally there. Writing `if: "Bash(git *)"` on a `Stop` or `SessionStart` hook is a no-op filter.
- **PowerShell `if:` patterns** (2026 fix): `if: "PowerShell(git push*)"` and similar wildcarded PowerShell rules now actually match. Pre-fix only `PowerShell(*)` matched; specific patterns silently failed. Affects Windows users + Linux/macOS with `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`. If you have legacy `PowerShell(*)` rules added as a workaround, you can now tighten to specific commands.

## ConfigChange matcher values

`ConfigChange` hook accepts a `config_source` matcher with documented values: `user_settings`, `project_settings`, `policy_settings`, `skills`. Use to detect when a managed admin pushes a settings update, when a project's `.claude/settings.json` changes mid-session, or when skills are added/removed.

```json
{
  "ConfigChange": [
    {"matcher": "policy_settings", "hooks": [{"type": "command", "command": ".claude/hooks/managed-policy-changed.sh"}]},
    {"matcher": "skills",          "hooks": [{"type": "command", "command": ".claude/hooks/skills-reload.sh"}]}
  ]
}
```

`policy_settings` matcher is the highest-signal — fires when managed-settings.json was refetched and changed. Useful for enterprises that want to log every policy refresh. `skills` matcher pairs with `SessionStart.reloadSkills: true` (v2.1.152+) for live skill development workflows.

## Settings.json hook parsing resilience (2026 fix)

Pre-fix: an unrecognized event name in `settings.json` `hooks` section (typo, deprecated event, or hook from a newer Claude Code version) silently invalidated the **entire** hooks section. Symptom: every hook stopped firing, hard to diagnose because no error surfaced.

Post-fix: the unrecognized event is logged and skipped. Remaining hooks still load. Explains historical "why aren't my hooks running" mysteries — check older sessions' logs for the typo, fix it, hooks resume.

dotforge implication: when defining hooks for very recent events (MessageDisplay, PostToolBatch, Setup), older Claude Code versions on collaborator machines won't reject the whole config — they'll just skip the new event and run the rest. Safer to ship hooks for new events.

## Async, timeouts, matchers

- Async: `async: true` or stream `{"async":true}` as first JSON line
- Tool hooks: 10min timeout. SessionEnd: 1.5s default. Override: `hook.timeout`
- Matchers: Bash, Read, Write, Edit, Grep, Glob. Wildcard `*` supported
- **Hyphenated matchers exact-match (BREAKING, v2.1.195)**: pre-fix, `matcher: "code-reviewer"` substring-matched (`code-reviewers`, `my-code-reviewer` also fired). Post-fix exact-match only. Audit dotforge agent matchers using hyphens (`code-reviewer`, `security-auditor`, `session-reviewer`, `test-runner`) and any hook keyed on `mcp__<server-with-hyphen>` matchers. Wildcards still cover the substring case explicitly: `matcher: "code-*"` matches `code-reviewer` + `code-reviewers`

## Stop hook convergence contract (v2.1.143+)

Stop hooks that return `decision: "block"` repeatedly used to loop forever. Cap added: **8 consecutive blocks** terminate the turn with a warning. Override via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP=<n>`.

Design implication: a Stop hook gating on a flaky check (failing test, missing file, pending review) MUST converge. Patterns:

- Count attempts in a state file under `.claude/session/` and let the turn pass after N retries
- Emit `decision: "block"` only when the gate is concretely actionable; otherwise `continue: true` with a `systemMessage`
- Never use `decision: "block"` as "force the model to retry indefinitely" — that's the anti-pattern v2.1.143 closes

## Key hooks

- block-destructive.sh: mandatory; profiles: minimal, standard, strict
- lint-on-save.sh: matcher = Write|Edit for post-save linting
- session-report.sh: Stop event; JSON metrics to ~/.claude/metrics/
- All hooks: chmod +x, validate with `bash -n`, shellcheck if available

## Plugin system

- Env vars: `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${user_config.X}`
- Plugin options exposed as `CLAUDE_PLUGIN_OPTION_*` env vars
- `bin/` directory: executables added to PATH during skill/hook execution (v2.1.91+). Ship compiled helpers, scripts, CLIs alongside markdown instructions
