---
id: practice-2026-05-13-claude-bg-background-sessions
title: claude --bg + 5 subcommands for background session lifecycle (v2.1.139)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [cli, background-sessions, paralellism, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
New paradigm for background work alongside the existing `--worktree` / `--fork-session` flags. Six new CLI surfaces:

- `claude --bg "<task>"` — starts a background agent and returns immediately. Prints session ID + management commands. Combinable with `--agent <name>`.
- `claude attach <id>` — attach to a running background session in the current terminal
- `claude logs <id>` — print recent output
- `claude respawn <id>` — restart a stopped session with conversation intact (`--all` restarts every stopped session)
- `claude rm <id>` — remove from the agent-view list
- `claude stop <id>` (alias `claude kill <id>`) — stop a running session

Unlike worktree isolation (filesystem-level), background sessions are process-level — they run in the same working tree but with their own context. Pairs with the v2.1.139 `claude agents` agent-view that shows running/blocked/done sessions.

## Evidence
CHANGELOG v2.1.139:
- "Added agent view (Research Preview): a single list of every Claude Code session — running, blocked on you, or done. Run `claude agents` to get started"
- CLI reference rows for `--bg`, `claude attach`, `claude logs`, `claude respawn`, `claude rm`, `claude stop`

## Impact on dotforge
- `.claude/rules/domain/parallel-sessions.md` — new section "Background sessions" covering `--bg` + the 5 subcommands; clarify vs `--worktree` (filesystem isolation) vs `--fork-session` (history clone)
- `.claude/rules/agents.md` — possibly add background dispatch as an alternative to Agent Teams for long-running independent tasks
- `skills/benchmark/SKILL.md` — `--bg` could fit the parallel-comparison flow (full vs minimal in two backgrounds, then `claude logs` to harvest)

## Decision
Pending
