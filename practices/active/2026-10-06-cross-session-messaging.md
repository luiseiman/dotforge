---
id: practice-2026-10-06-cross-session-messaging
title: Cross-session messaging — SendMessage/ListAgents between sessions, @name mentions, crossSessionInbound policy (v2.1.220–v2.1.251)
source: "/forge watch — docs/en/whats-new W32 + CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [sessions, agents, security, prompt-injection, parallel-sessions]
tested_in: []
incorporated_in: [".claude/rules/domain/parallel-sessions.md", ".claude/rules/agents.md"]
replaced_by: null
effectiveness: monitoring
error_type: security
---

## Description
- macOS/Linux (v2.1.220–224): sessions message each other via `SendMessage` + `ListAgents`; typing `@` mentions another session by name (v2.1.232). Remote Control machines appear as device cards on phone (W34).
- Settings: `crossSessionInbound: accept|hold|refuse` (invalid value warns and holds/refuses, v2.1.251); `dialogExpiry`; `notify_when_idle` (v2.1.236); inbound messages to sessions running with bypassed permissions are held (v2.1.248). `SendMessage` to other sessions is classified by auto mode before dispatch (v2.1.222). Background subagents can reply to unnamed sibling/parent (v2.1.251); teammate final answer reaches lead in idle notification.
- Session plumbing: `claude attach|logs <partial-name>` (v2.1.290); `claude daemon status|stop --any [--keep-workers]` supervisor; `claude rm --discard-unpushed <commit>@<wt>` / `--force-remove-worktree <wt>` (v2.1.260/268); `--continue` opens finished bg sessions (v2.1.257); `--resume <id>` searches every project on the machine (v2.1.223); `--resume` on a running bg session attaches (v2.1.285); `--setting-sources` forwarded to spawned sessions (v2.1.286); `claude --bg` checks workspace trust; background sessions hold the worktree lock while running (v2.1.248).

## Evidence
0 hits for `crossSessionInbound`, `ListAgents` (cross-session sense), `claude daemon`. `parallel-sessions.md` covers bg lifecycle up to v2.1.145 and `agents.md` SendMessage only in the subagent-continuation sense. Inbound session messages are an injection surface on production-tier sessions (TRADINGBOT, cotiza) — policy needed.

## Impact on dotforge
- `.claude/rules/domain/parallel-sessions.md`: cross-session section + daemon + rm flags
- `.claude/rules/domain/agent-orchestration.md`: `ListAgents`, inbound policy
- `stacks/trading/settings.json.partial` + production-tier guidance in `workflow-and-ultracode-policy.md`: `crossSessionInbound: "hold"` (or `refuse`) default
- `.claude/rules/agents.md`: disambiguate subagent `SendMessage` vs session `SendMessage`

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.6.0 (/forge update, catalogue block).
