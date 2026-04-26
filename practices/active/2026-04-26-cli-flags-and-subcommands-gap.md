---
id: practice-2026-04-26-cli-flags-and-subcommands-gap
title: New CLI flags and subcommands not documented in domain/parallel-sessions.md
source: "official documentation"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [cli, docs, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
`.claude/rules/domain/parallel-sessions.md` documents the worktree/automation flag surface but is missing several flags and subcommands that have shipped through 2026:

**CLI flags missing:**
- `--name`/`-n` — display name for the session (resumable via `claude --resume <name>`)
- `--betas` — beta headers (API-key only)
- `--chrome` / `--no-chrome` — browser integration
- `--debug-file <path>` — debug logs to file
- `--disable-slash-commands` — disable all skills/commands for the session
- `--input-format`, `--include-partial-messages` — print/SDK streaming
- `--allow-dangerously-skip-permissions` — adds `bypassPermissions` to the Shift+Tab cycle without starting in it (different from `--dangerously-skip-permissions`)
- `--remote-control` (`--rc`), `--remote-control-session-name-prefix`
- `--session-id` — explicit UUID for the session
- `--strict-mcp-config` — only honor `--mcp-config` MCP servers
- `--system-prompt`, `--system-prompt-file`, `--append-system-prompt`, `--append-system-prompt-file`
- `--tools` (restrict built-in tools), `--allowedTools`, `--disallowedTools`
- `--ide`, `--init`, `--plugin-dir`
- `--channels`, `--dangerously-load-development-channels`

**CLI subcommands missing:**
- `claude install [version]` — install/reinstall native binary
- `claude auth (login|logout|status)`
- `claude agents` — list configured subagents
- `claude auto-mode (defaults|config)` — print built-in classifier rules
- `claude remote-control` — server mode
- `claude setup-token` — generate long-lived OAuth token for CI

## Evidence
Fetched code.claude.com/docs/en/cli (2026-04-26). Cross-checked against `.claude/rules/domain/parallel-sessions.md` — only the worktree/headless subset is covered.

`claude setup-token` in particular is the canonical CI auth flow and worth a dedicated reference in any GitHub Actions or GitLab CI guidance dotforge ships.

## Impact on dotforge
- `.claude/rules/domain/parallel-sessions.md` — extend the flags table; consider a subsection for CLI subcommands
- `skills/benchmark/SKILL.md` — uses `claude --print`; note relevant flags (`--max-budget-usd`, `--max-turns`, `--no-session-persistence`, `--input-format`, `--effort`)
- New `.claude/rules/domain/ci-headless.md` candidate covering `claude setup-token` + the subset of flags relevant to CI

## Decision
Pending
