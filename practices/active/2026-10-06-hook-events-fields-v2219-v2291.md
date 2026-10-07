---
id: practice-2026-10-06-hook-events-fields-v2219-v2291
title: New hook events (PreModelSwitch, PostModelSwitch, DirectoryAdded), new fields, and fail-closed JSON parsing (v2.1.219–v2.1.291)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291 + docs/en/hooks"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [hooks, hook-events, templates, security]
tested_in: []
incorporated_in: [".claude/rules/domain/hook-architecture.md", ".claude/rules/domain/hook-events.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
Events: `PreModelSwitch` (blockable: `permissionDecision` allow/deny/ask) + `PostModelSwitch` (v2.1.251); `DirectoryAdded` (matchers `slash_command`, `register_repo_root`, v2.1.219); `SessionStart` matcher `fork`; `SessionEnd` matchers `clear|resume|logout|prompt_input_exit|other`; `ConfigChange` matcher `local_settings`.
Fields: `once` (skills only), `statusMessage`, `shell: bash|powershell`, http `allowedEnvVars`, `asyncRewake` (bg + wake on exit 2, ignores timeout), `${CLAUDE_PROJECT_DIR}` placeholder. Outputs: SessionStart `initialUserMessage`; MessageDisplay `displayContent`; PermissionRequest `decision.ruleApply`; WorktreeCreate (http) `worktreePath`.
Inputs: `scratchpad_dir` common field (v2.1.257); `cloud_credential_error` StopFailure matcher (v2.1.267); SessionStart resume receives `seconds_since_last_response`, `context_tokens`, `prompt_cache_likely_expired`, `estimated_cache_write_usd` (v2.1.251); `InstructionsLoaded` carries `agent_id`, `agent_type`, `effort` (v2.1.288).
Semantics: hooks printing invalid `{…}` stdout are now **hook errors** with the parse message, not plain text (v2.1.248); PreToolUse/PermissionRequest fail-closed when matching fails or input can't be serialized (v2.1.288); `agent`-type hooks no longer run on PermissionRequest (v2.1.280); PermissionRequest hooks fire in `--print` (v2.1.268); Elicitation `decision: block` declines (v2.1.284); `TeammateIdle` not fired from subagents/forks (v2.1.290); `idle_prompt` silenced while bg agents run (v2.1.288); `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` now extends hooks without per-hook `timeout` (v2.1.268). `.claude/rules` `paths:` and nested CLAUDE.md now also load on Write/Edit in scope, not only Read (v2.1.288).

## Evidence
grep of `.claude/rules/`, `template/`, `stacks/`: 0 hits for `PreModelSwitch`, `DirectoryAdded`, `scratchpad_dir`, `initialUserMessage`, `displayContent`, `allowedEnvVars`, `statusMessage`, `CLAUDE_PROJECT_DIR`. `asyncRewake` already covered (5 hits).

## Impact on dotforge
- `.claude/rules/domain/hook-architecture.md`, `hook-events.md`: events table, fields, inputs, fail-closed contract
- `template/hooks/*.sh` + `scripts/compiler/compile.sh` templates: audit every JSON-emitting hook for strictly valid stdout (fail-closed since v2.1.248)
- `template/hooks/session-restore.sh`: use `prompt_cache_likely_expired` / `estimated_cache_write_usd` to decide re-injection size
- `.claude/rules/domain/rule-effectiveness.md`: `paths:` trigger set
- `stacks/hookify/rules/hookify.md:45`: `agent` hooks caveat

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.5.0 (/forge update, security block).
