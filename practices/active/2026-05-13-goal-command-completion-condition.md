---
id: practice-2026-05-13-goal-command-completion-condition
title: /goal command — persistent completion condition across turns (v2.1.139)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [slash-commands, workflow-automation, loops, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
`/goal <condition>` defines a completion condition that Claude keeps working toward across multiple turns until it's met. Works in:

- Interactive sessions
- `-p` print mode
- Remote Control

Shows an overlay panel with live elapsed time, turn count, and tokens consumed. More structured than `/loop` (which polls on a cadence) — `/goal` is condition-driven and persists until the model judges the goal satisfied.

Example: `/goal "all tests in tests/test-tool-latency.sh pass and the file is committed"` — the model iterates until both clauses are true.

## Evidence
CHANGELOG v2.1.139: "Added `/goal` command: set a completion condition and Claude keeps working across turns until it's met. Works in interactive, `-p`, and Remote Control. Shows live elapsed/turns/tokens as an overlay panel".

CHANGELOG v2.1.140 also: "Fixed `/goal` silently hanging when `disableAllHooks` or `allowManagedHooksOnly` is set — now shows a clear message".

## Impact on dotforge
- `.claude/rules/domain/workflow-automation.md` — does not exist as a standalone rule but `/loop` is documented in `domain/cli-flags.md`. Candidate: new `domain/workflow-automation.md` covering `/goal`, `/loop`, `/schedule`, `/batch`, Routines, and when to use each
- `domain/context-control-patterns.md` — note that `/goal` is the structured alternative to `/loop` when the stop condition is well-defined
- Update `docs/claude-vs-forge.md` slash-command tables to include `/goal`

## Decision
Pending
