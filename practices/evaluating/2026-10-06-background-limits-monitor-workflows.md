---
id: practice-2026-10-06-background-limits-monitor-workflows
title: Background command time limits, Monitor deadlines, /goal backoff, /loop changes (v2.1.233–v2.1.288)
source: "/forge watch — CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: evaluating
tags: [workflows, background, monitor, loop, goal, automation]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
- Background Bash/PowerShell stop after a time limit — default 30 min, max 2 h (v2.1.285); from v2.1.288 applies only in unattended `-p`/SDK/CI/cloud sessions. 1 h limit on subagent background commands removed (v2.1.260). Non-interactive sessions auto-continue a response cut off mid-stream (v2.1.246). SIGTERM in print/SDK exits 143 without recording an interrupted turn (v2.1.236).
- Monitor watches always have a deadline (max 30 min, 10 min in `-p`); `persistent` option removed (v2.1.271).
- `/goal`: clears itself on unrecoverable error; check-ins on background work back off 30 min → 1 h → 2 h, capped at 3 per goal; `CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` opts out; restored on resume from picker (v2.1.233–246).
- `/loop`: self-paced mode always available (v2.1.248); `/usage` Loops breakdown; idle wake-ups folded (v2.1.243). `--continue` skips sessions whose first prompt was `/loop` unless `-p`.
- `--max-budget-usd`: subagent spend counts; at cap, spawning fails with `Budget limit reached` and running bg subagents are stopped (v2.1.217). Cost estimates include 1.1x US-only-inference premium for data-residency workspaces (v2.1.239).
- `/batch` runs where a `WorktreeCreate` hook provides worktrees (v2.1.281). Web search: 100 calls/hour refill replaces 200-call cap (`CLAUDE_CODE_WEB_SEARCH_REFILLS_PER_HOUR`); WebFetch fails after 5 min (`CLAUDE_CODE_WEBFETCH_DEADLINE_MS`, v2.1.268); `CLAUDE_CODE_DISABLE_WEB_FETCH`.

## Evidence
`workflow-automation.md` § `/loop` says "Never use `sleep N`" and documents cadence heuristics but not the 30 min/2 h bg cap or Monitor deadline — a `/loop` wrapping a long bg job in CI now dies silently at 30 min. `vps-control` watchdog and `/forge watch` (WebFetch-heavy) are affected by the 5-min WebFetch deadline + hourly search refill.

## Impact on dotforge
- `.claude/rules/domain/workflow-automation.md`: limits section per primitive; `--max-budget-usd` subagent semantics
- `.claude/rules/domain/agent-orchestration.md`: Monitor deadline
- `skills/watch-upstream/SKILL.md`: budget WebFetch/WebSearch calls (hourly refill)
- `.claude/rules/domain/cli-flags.md`: env vars

## Decision
Pending
