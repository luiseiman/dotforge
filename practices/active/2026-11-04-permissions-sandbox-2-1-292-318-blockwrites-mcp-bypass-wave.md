---
id: practice-2026-11-04-permissions-sandbox-2-1-292-318-blockwrites-mcp-bypass-wave
title: Permissions & sandbox 2.1.292→2.1.318: blockWritesOutsideWorkingDirectories (breaks sync-all unless dirs widened), allowNestedUserNamespaces, hard-link guarded-file refusal, MCP allow rules per server (mcp__<server>__*), 5th bypass-fix wave with version floors, auto-mode deny without classifier verdict, rm prompts on mounted drives, sed -i no longer simulated
source: "/forge watch — Claude Code CHANGELOG 2.1.292→2.1.318 + code.claude.com docs + Piebald-AI system prompts (2026-11-04)"
source_type: watch
discovered: 2026-11-04
status: active
tags: [permissions, sandbox, auto-mode, security, mcp]
tested_in: []
incorporated_in: [".claude/rules/domain/permission-model.md", ".claude/rules/domain/sandboxing.md", ".claude/rules/domain/permission-managed-settings.md", ".claude/rules/domain/auto-mode.md"]
replaced_by: null
effectiveness: monitoring
error_type: security
---

## Description
- 2.1.314 `permissions.blockWritesOutsideWorkingDirectories`: Write/Edit/NotebookEdit refuse paths outside working directories in every mode incl. `bypassPermissions`; `true` from any scope wins; no allow rule lifts it; also refuses writes to Claude Code settings files and removes EnterWorktree/ExitWorktree; shell commands not limited. Conflicts with `/forge sync-all` (writes every repo under ~/Documents) and `global/sync.sh` (~/.claude) unless `additionalDirectories` is widened. Recommend for production tier next to the read twin (`permission-model.md` has only `blockReadsOutsideWorkingDirectories`).
- 2.1.305 `sandbox.allowNestedUserNamespaces` (Linux/WSL2): lets sandboxed commands create user namespaces (Chromium, rootless podman) — turns off a security boundary. 2.1.317: sandbox refuses to initialize when a guarded file has extra hard links; `dangerouslyDisableSandbox` retries are refused too ("if you did not create that link, treat the file as untrusted"). 2.1.309: `excludedCommands` now ask before writing to write-list paths when the sandbox is enabled but cannot run; startup files ran outside the sandbox before 2.1.309; macOS `denyWrite` via symlink and Linux background-command deny lifting fixed; 2.1.314: worktree entered via `-p --resume`/`--continue` had no sandbox before. 2.1.292: with strict sandbox mode, `FOO=bar python3 app.py` runs unprompted. 2.1.304: `[user-id]` bracket globs broke Linux startup before.
- 2.1.299 MCP rules: `mcp__a` no longer allows `a__b`; write `mcp__<server>__*`; deny/ask for servers with `__` in the normalized name now apply; agent `tools:` lists take only the named server's tools. 2.1.305: `allowedMcpServers` stopped filtering managed-mcp.json stdio servers that use `${VAR}` only in `env`. 2.1.318: `deniedMcpServers` URL entries also block Anthropic-provided servers and cloud connectors.
- 5th bypass-fix wave (extend `permission-model.md` list to 2.1.309): `BASH_ARGV0` assignment (2.1.296), for-loops over globs (2.1.295), variable set by a command whose redirect can fail, wrapped/prefixed `cd` before git, `Edit(path)` deny vs Bash redirect in a subshell, worktree guard vs locale-prefixed commands and zsh arithmetic, PowerShell `Set-Location`/`cd` with extra args (2.1.309). 2.1.299: plan mode no longer runs a write that a PreToolUse hook or mod `tool.check` allowed. 2.1.292: network/UNC path reads always prompt regardless of allow rules, hooks, or auto mode.
- Auto mode: 2.1.314 — when the classifier returns no verdict and auto-mode deny rules exist, the call is refused with no prompt (`hard_deny`/`classifyAllShell` turn classifier outages into blocks); 2.1.316 — managed `autoMode.allow` without `"$defaults"` no longer regains built-in exceptions from `--settings`, `/permissions` or `/auto-mode-setup`; 2.1.302/304 `CLAUDE_CODE_AUTO_MODE_MODEL` (client-side classifier only) and `/auto-mode-setup`; 2.1.317 gateway 403/422 no longer fails every turn.
- `rm` prompts: runtime-built rm in an unreadable script no longer prompts unless `CLAUDE_CODE_STRICT_INLINE_SHELL_RM_PROMPT=1` (2.1.299); `rm -r` of a mounted drive or top-level folder (`/Volumes`, `/media`, `/mnt/c`) now prompts (2.1.304, `CLAUDE_CODE_DISABLE_MOUNTED_DRIVE_RM_PROMPT`); Desktop/VS Code bypass mode denies at once with a rewrite hint; `CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS=1` removes the critical-path rm prompt in bypass mode. 2.1.309: `sed -i` gets the standard Bash prompt and runs as written (no simulated preview, `/rewind` does not restore it).
- Managed: `forceRemoteSettingsRefresh` only truly fail-closed since 2.1.314 (stored copy expiry hole); server-managed settings apply without approval prompt and unverifiable copies are refused (2.1.316); file tools ask before editing the local copy (2.1.314); `axScreenReader`/`CLAUDE_AX_SCREEN_READER` in `env` apply only from user/managed/`--settings` (2.1.307) → add to the inert-in-project-scope list. 2.1.317: Claude asks before a web/shell call sends the account email to the network.

## Evidence
CHANGELOG `## 2.1.314` (blockWrites, classifier no-verdict, forceRemoteSettingsRefresh), `## 2.1.305`, `## 2.1.317`, `## 2.1.309`, `## 2.1.299`, `## 2.1.296`, `## 2.1.292`; official `settings.md` exceptions table (blockWrites v2.1.314), `permissions.md` § Network paths (v2.1.292), `settings-reference.md` `allowNestedUserNamespaces`.

## Impact on dotforge
- `domain/permission-model.md`: write-side block + sync-all caveat; bypass wave 2.1.295–309; plan-mode-vs-hook-allow fix; network paths; `sed -i`; rm prompt env vars
- `domain/sandboxing.md`: `allowNestedUserNamespaces`, hard-link refusal, `excludedCommands` ask behavior, version floors
- `domain/permission-managed-settings.md`: MCP rule syntax, `allowedMcpServers` `${VAR}` exception, `deniedMcpServers` by URL, `axScreenReader` scope, server-managed approval change
- `domain/auto-mode.md`: no-verdict refusal, `$defaults` tightening, `CLAUDE_CODE_AUTO_MODE_MODEL`, `/auto-mode-setup`, email-egress prompt
- Production-tier stacks (`trading`, `vps-ssh`): evaluate `blockWritesOutsideWorkingDirectories` + `additionalDirectories` in `settings.json.partial`

## Decision
Accepted 2026-11-04 — incorporated in dotforge v4.10.0 (/forge update, watch batches 2–6). Origin: /forge watch 2026-11-04 (baseline v2.1.291 → head 2.1.318). Full per-item report with version and target file: session scratchpad `watch/REPORT-2026-11-04.md`.
