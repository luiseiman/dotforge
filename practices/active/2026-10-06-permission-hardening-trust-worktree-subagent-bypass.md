---
id: practice-2026-10-06-permission-hardening-trust-worktree-subagent-bypass
title: Trust gating expanded, worktree sessions cannot touch main checkout, subagent bypassPermissions blocked (v2.1.222–v2.1.267)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291 + docs/en/sub-agents"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [permissions, security, worktree, subagents, trust]
tested_in: []
incorporated_in: [".claude/rules/domain/parallel-sessions.md", ".claude/rules/domain/agent-orchestration.md", ".claude/rules/domain/permission-model.md", ".claude/rules/domain/permission-managed-settings.md", ".claude/rules/domain/sandboxing.md"]
replaced_by: null
effectiveness: monitoring
error_type: security
---

## Description
- v2.1.222: worktree-isolated sessions and their subagents can no longer run destructive git commands against the main checkout. PreToolUse auto-allow hooks no longer bypass tool restrictions in background agent tasks. `isolation: worktree` enforces working-dir checks (v2.1.203) and repository boundaries (v2.1.210); PowerShell gets working-dir check only.
- v2.1.223: an agent definition with `permissionMode: bypassPermissions` honors the org policy that disables bypass. v2.1.267: subagent `bypassPermissions` only if main also uses it; if main is in `bypassPermissions|acceptEdits|auto`, subagent inherits that mode regardless of its `permissionMode`.
- v2.1.232: nested git repos no longer inherit trust from a parent. v2.1.238: inline `mcpServers` in `.claude/agents/` or `--add-dir` agent files require trust (not needed for `~/.claude/agents/`, `--agents` JSON, managed). v2.1.225: `claude agents` / `claude --bg` ask for workspace trust first.
- v2.1.284/285: fork subagents keep parent's `plan`/`dontAsk` and cannot exit plan mode.
- v2.1.290: a PreToolUse hook that rewrote input skipped some permission rules/safety checks — fixed (broader than the v2.1.110 deny re-check). v2.1.257: `permissions.ask` rule skipped in auto mode inside compound/subshell commands — fixed.

## Evidence
`parallel-sessions.md` worktree section and `agent-orchestration.md` § Agent Teams describe isolation without the destructive-git block. `permission-model.md` workspace-trust section only covers subagent frontmatter hooks (v2.1.218). `permission-managed-settings.md` `updatedInput` note cites only the v2.1.110 deny re-check.

## Impact on dotforge
- `.claude/rules/domain/parallel-sessions.md`, `agent-orchestration.md`: isolation guarantees + permissionMode inheritance table
- `.claude/rules/domain/permission-model.md`: trust gating list (hooks, mcpServers, nested repos, bg sessions)
- `.claude/rules/domain/permission-managed-settings.md`: `updatedInput` re-check scope
- `agents/*.md`: confirm none sets `permissionMode: bypassPermissions`

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.5.0 (/forge update, security block).
