---
id: practice-2026-08-07-subagents-background-by-default
title: Subagents run in background by default (v2.1.198+) with narrower tool set
source: "/forge watch — Claude Code upstream docs"
source_type: upstream-doc
discovered: 2026-08-07
status: active
tags: [subagents, tools, breaking-change, agent-tool-lists]
tested_in: []
incorporated_in: [".claude/rules/domain/agent-orchestration.md"]
replaced_by: null
---

## Description
Since v2.1.198, subagents run in the background by default (foreground only when Claude needs the result before continuing). Background subagents get a **restricted built-in tool set** regardless of what their frontmatter `tools:` field lists. Tools outside this allowlist are silently removed:

**Background-safe built-in tools**: `Read`, `Grep`, `Glob`, `Bash`, `PowerShell`, `Edit`, `Write`, `NotebookEdit`, `WebFetch`, `WebSearch`, `TodoWrite`, `Skill`, `ToolSearch`, `EnterWorktree`, `ExitWorktree`, `Monitor`, `TaskStop`, `SendMessage`, `Artifact`.

Everything else (all built-ins not in this list) is removed silently. MCP tools are preserved. The removal reports no error unless it leaves `tools:` resolving to nothing.

Foreground subagents keep the broader tool set. Forks skip both filters.

## Evidence
Fetched from https://code.claude.com/docs/en/sub-agents (2026-08-07):
> "As of v2.1.198, subagents run in the background by default. Claude runs a subagent in the foreground when it needs the result before continuing. Background subagents run with a smaller built-in tool set than foreground subagents [...] Claude Code removes every other built-in tool from a background subagent, whether inherited or listed in the tools field, so the same definition can resolve to different tools in the foreground and the background."

## Impact on dotforge
- Audit `agents/*.md` tool lists — any agent relying on a tool outside the background allowlist may silently lose it. Candidates worth checking: `agents/architect.md`, `agents/security-auditor.md`, `agents/session-reviewer.md`
- Update `domain/agent-orchestration.md` — document the background/foreground tool split, list the background-safe allowlist
- Optional: for agents that MUST have a broader tool set (e.g. architect running EnterPlanMode/ExitPlanMode), consider `background: false` in frontmatter to force foreground execution
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` disables background entirely — env var worth mentioning for troubleshooting

## Decision
Pending
