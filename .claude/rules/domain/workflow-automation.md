---
globs: "**/CLAUDE.md,**/skills/loop/**,**/skills/schedule/**,**/rules/_common.md"
description: "When to reach for /loop, /schedule, /batch — temporal workflow primitives"
domain: claude-code-engineering
last_verified: 2026-04-20
---

# Workflow Automation Primitives

Three bundled or dotforge-provided workflow skills cover temporal orchestration: `/loop` (polling), `/schedule` (cron triggers), `/batch` (fan-out). Pick by the problem shape, not by familiarity.

## `/loop` — time-bounded polling

- Use for: watching a long-running build, waiting for a PR check to finish, polling an external service with a known-short settling time, iterating on a prompt until a condition holds
- Default cadence heuristic: sleep <5min stays in prompt cache; 5–60min pays one cache miss; 20–30min is the sweet spot for idle polls. See `ScheduleWakeup` docs for the full rationale. With `ENABLE_PROMPT_CACHING_1H=1` (v2.1.108+) the 5-min boundary extends to 60min — see `context-window-optimization.md`
- Never use `sleep N` in Bash as a polling mechanism — it burns a tool call, freezes Claude, and wastes context. `/loop` or `ScheduleWakeup` instead
- Stop condition MUST be explicit in the loop prompt — otherwise `/loop` runs forever

## `/schedule` — recurring work

- Use for: nightly reports, weekly audits, periodic scans, scheduled maintenance, dead-man's-switch monitors
- Cron-based, survives session end. Edit/list/delete via the skill
- NOT for polling-until-done (that's `/loop`) — scheduled triggers fire regardless of state
- Keep the scheduled prompt self-contained — no assumed session context, no references to prior conversation turns

## `/batch` — fan-out across many independent changes

- Use for: renaming a symbol across 50 files, migrating 30 components between frameworks, applying the same refactor to every file matching a pattern
- Each change must be independent (no shared mutable state, no order dependency)
- When blast radius is wide, stage into a branch first — batch failures are harder to unwind than sequential
- If changes are <10, sequential is usually faster than `/batch` setup overhead

## Anti-patterns

- `sleep 300 && check-again` in Bash → use `/loop` with 270s cadence to stay in cache
- Hand-coded cron in a SessionStart hook → use `/schedule`
- Looping over files with Edit tool calls for a mechanical rename → use `/batch`
- `/loop` without a stop condition → will run until the session dies or the loop burns the context
