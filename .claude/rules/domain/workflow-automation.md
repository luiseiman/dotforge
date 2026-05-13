---
globs: "**/CLAUDE.md,**/skills/loop/**,**/skills/schedule/**,**/rules/_common.md"
description: "When to reach for /loop, /schedule, /batch — temporal workflow primitives"
domain: claude-code-engineering
last_verified: 2026-05-13
---

# Workflow Automation Primitives

Four workflow primitives cover temporal orchestration: `/goal` (condition-driven persistence), `/loop` (polling), `/schedule` (cron triggers), `/batch` (fan-out). Pick by the problem shape, not by familiarity.

## `/goal` — condition-driven persistence (v2.1.139+)

- `/goal <completion-condition>`: Claude keeps working across turns until the condition is met. Works in interactive, `-p` print mode, and Remote Control. Live overlay shows elapsed/turns/tokens
- Use for: open-ended tasks with a clear "done" signal (`all tests in <file> pass and the change is committed`, `the deploy reports HEALTHY for 60s`, `PR #N is approved and CI green`)
- Stop condition is judged by the model; phrase it concretely so the judgment is reliable
- Alternative to `/loop` when the stop condition is well-defined — `/goal` is condition-driven (semantic), `/loop` is cadence-driven (temporal)
- Fails closed when `disableAllHooks` or `allowManagedHooksOnly` is set (v2.1.140 — shows clear message instead of silent hang)

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

## Routines vs `/schedule` vs Desktop scheduled tasks

Three distinct cron-like primitives — don't confuse them:

- **Routines** (Anthropic-managed cloud): survives machine off; triggers on cron, API calls, or GitHub events. Use for unattended reports, overnight audits, dead-man switches that must run regardless of local state. Create via web/Desktop app or `/schedule` in the CLI.
- **Desktop scheduled tasks** (local machine): full file/tool access. Use when local state matters (reading local dev files, hitting `localhost`).
- **`/schedule`** (dotforge skill): session-bound local cron. Use for per-project recurring work during active development.

## Anti-patterns

- `sleep 300 && check-again` in Bash → use `/loop` with 270s cadence to stay in cache
- Hand-coded cron in a SessionStart hook → use `/schedule`
- Looping over files with Edit tool calls for a mechanical rename → use `/batch`
- `/loop` without a stop condition → will run until the session dies or the loop burns the context
