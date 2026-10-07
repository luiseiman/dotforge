---
id: practice-2026-10-06-cli-flags-env-vars-misc-bundle
title: CLI/env additions bundle — autocompact, system-prompt-snapshot, bashOutputMaxChars, claude purge rename, doctor/daemon/import/gateway, misc env vars (v2.1.213–v2.1.290)
source: "/forge watch — docs/en/cli + CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [cli, env-vars, automation, context, skills]
tested_in: []
incorporated_in: [".claude/rules/domain/cli-flags.md", ".claude/rules/domain/prompting-patterns.md", ".claude/rules/domain/context-window-optimization.md", ".claude/rules/domain/auth.md", "skills/reset-project/SKILL.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
Flags: `--autocompact <auto|tokens>` session-only (v2.1.221); `/autocompact` saved per model (v2.1.288); Opus/Fable auto-compact shortly before 1M (v2.1.260). `--system-prompt-snapshot off` rebuilds prompt every request (v2.1.257; default records prompt on first request and reuses until compaction, incl. across `--resume`); `--system-prompt` combinable with its `-file` form (v2.1.283); `__SYSTEM_PROMPT_DYNAMIC_BOUNDARY__` line in custom prompt splits cached/dynamic (v2.1.275). `--advisor <model>` / `advisorModel` setting. `--desktop` (v2.1.285). `--permission-mode manual` alias (v2.1.200). `--worktree #<PR>|<GitLab MR URL>` (v2.1.233). `--mcp-config` with `-p` waits for servers up to `MCP_TIMEOUT` / `CLAUDE_CODE_MCP_STARTUP_WAIT_MS` (v2.1.221). `--forward-subagent-text` forwards depth-2+ (v2.1.219). `--bare` connects only CLI-named MCP servers, no system reminders, no bg tasks (v2.1.286). `--permission-prompt-tool` cannot approve MCP tools marked user-interaction (v2.1.199).
Subcommands: `claude purge` (was `claude project purge`, old name warns, v2.1.288); `claude doctor` (read-only CLI diagnostics); `claude daemon status|stop`; `claude import [codex|...] --dry-run` (v2.1.213); `claude auto-mode reset [-y]` (v2.1.212), `defaults --label <prefix>` (v2.1.208); `claude mcp login|logout <name> [--no-browser]`; `claude gateway --config` (apps gateway); `claude self-hosted-runner setup|doctor|orchestrator` (v2.1.224); `claude ultrareview --post|--no-post` (v2.1.227); `--environment ccpool_… --ref <branch>`; `claude auth status` JSON has `configDirectory` + `authMethod` (v2.1.268).
Settings/env: `bashOutputMaxChars` up to 128K (v2.1.261; `taskOutputMaxChars`/`TASK_MAX_OUTPUT_LENGTH` no effect, 1 GB disk cap v2.1.265/277); `CLAUDE_CODE_NONSTREAMING_TIMEOUT_RETRIES`, `CLAUDE_CODE_MAX_MCP_DESCRIPTION_LENGTH`, `CLAUDE_CODE_DISABLE_STRUCTURED_OUTPUTS`, `CLAUDE_CODE_GATEWAY_HINT_HEADERS`, `CLAUDE_CODE_NEW_INIT=1` (`/init` reads AGENTS.md/.windsurf/.clinerules), `ANTHROPIC_WORKSPACE_ID`. `-p` stream-json init event has `mcp_server_errors` (v2.1.219). Status line JSON: `rate_limits.spend_limit`, `prompt_cache` (v2.1.251). OTel: `prompt_text` on `user_prompt`, `OTEL_METRICS_INCLUDE_REPOSITORY`, `claude_code.managed_settings_resolved`, `OTEL_LOG_TOOL_CONTENT=1` (v2.1.269/287). `SendFeedback` tool + `feedbackDrafts` setting (v2.1.247) — feedback upload now includes system prompt incl. CLAUDE.md, tool defs, model params (secrets redacted, v2.1.224) → egress surface.

## Evidence
`skills/reset-project/SKILL.md:87-96` uses `claude project purge` + `--help` probe. `context-window-optimization.md:42-43` says "Bash truncation: 30K chars". `prompting-patterns.md` headless section predates snapshot semantics (iterating `--append-system-prompt` across `--continue` silently keeps the first prompt). 0 hits for the rest.

## Impact on dotforge
- `skills/reset-project/SKILL.md`: `claude purge`
- `.claude/rules/domain/cli-flags.md`: flags + subcommands + env sections
- `.claude/rules/domain/prompting-patterns.md`: snapshot caveat for `-p` scripts; boundary line in `vps-control` lean pattern
- `.claude/rules/domain/context-window-optimization.md`: `bashOutputMaxChars`, `--autocompact`
- `.claude/rules/domain/sandboxing.md` / `_common.md`: `feedbackDrafts` + feedback egress note for production tier
- `.claude/rules/domain/auth.md`: `authMethod` values, `configDirectory`

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.6.0 (/forge update, catalogue block).
