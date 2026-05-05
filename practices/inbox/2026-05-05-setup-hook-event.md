---
id: setup-hook-event
source: watch:code.claude.com/docs/en/hooks
status: inbox
captured: 2026-05-05
tags: [hooks, lifecycle, drift, medium-priority]
tested_in: []
incorporated_in: []
---

# `Setup` hook event missing from domain rules — should be 32 events not 31

## Observation

Per current hooks doc, the lifecycle event roster includes `Setup` — fires for `--init-only` and `--maintenance` runs with matchers `init` and `maintenance` respectively.

`domain/hook-architecture.md` opens with: "Events (31 total, verified v2.1.114 — code.claude.com/docs/en/hooks)" and groups session-level events as `SessionStart, SessionEnd, InstructionsLoaded`. **`Setup` is not listed.**

## Why it matters

- CI/automation flows that use `claude --init-only` or `--maintenance` rely on `Setup` hooks to provision env vars, validate prerequisites, or rotate creds before the session starts.
- Contributors writing init-time hooks may put them on `SessionStart` and miss the `Setup` lifecycle entirely (or the inverse — Setup hooks they expect to run on every session do not).

## Required update

1. `domain/hook-architecture.md` — add `Setup` to session-level events; bump verified tag and total count to 32.
2. `domain/hook-events.md` — document `Setup` payload + matchers `init|maintenance`; note non-blockable.
3. CLI flag refs in `domain/parallel-sessions.md` — cross-reference `--init-only` / `--maintenance` to the `Setup` hook.

## Affected files

- `.claude/rules/domain/hook-architecture.md`
- `.claude/rules/domain/hook-events.md`
- `.claude/rules/domain/parallel-sessions.md`
