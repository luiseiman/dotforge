---
id: routines-anthropic-managed-cron
source: watch:code.claude.com/docs/en/overview
status: inbox
captured: 2026-04-21
tags: [workflow-automation, routines, medium-priority]
tested_in: []
incorporated_in: []
---

# Routines — Anthropic-managed cron (separate from /schedule + /loop)

## Observation

The Claude Code overview documents three temporal workflows:
- **Routines** — Anthropic-managed infrastructure cron. Keeps running when your computer is off. Can trigger on API calls or GitHub events.
- **Desktop scheduled tasks** — run on the user's machine with local file access.
- **`/loop`** — repeats a prompt within a CLI session for polling.

Our `domain/workflow-automation.md` covers `/loop`, `/schedule`, `/batch` — but `/schedule` is our dotforge skill, not to be confused with Routines.

## Why it matters

- Routines are the right tool for "keep running overnight when my laptop is closed" workflows.
- `/schedule` (dotforge) and Desktop scheduled tasks run on the user's machine.
- This is a category our rule doesn't name explicitly.

## Required update

Add a section to `domain/workflow-automation.md`:
```
## Routines vs /schedule vs Desktop scheduled tasks

- **Routines** (Anthropic cloud): survives machine off; triggers on cron, API calls, or GitHub events. Use for unattended reports, overnight audits.
- **Desktop scheduled tasks**: local machine, full file/tool access. Use when local state matters.
- **`/schedule`** (dotforge skill): local session-bound cron. Use for per-project recurring work.
```

## Affected files

- `.claude/rules/domain/workflow-automation.md`
