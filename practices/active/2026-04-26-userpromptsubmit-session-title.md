---
id: practice-2026-04-26-userpromptsubmit-session-title
title: UserPromptSubmit hook can set session title via hookSpecificOutput.sessionTitle (v2.1.94)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [hooks, ux, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
A `UserPromptSubmit` hook can return `hookSpecificOutput.sessionTitle: "..."` and the harness will set the session's display title (the same name shown in `/resume` and the terminal title). Available since v2.1.94.

This lets a hook auto-name sessions deterministically — for example, derive the title from the first prompt's first 60 chars, the active branch, or a project-specific convention — without the user needing `/rename`.

## Evidence
CHANGELOG v2.1.94: "Added `hookSpecificOutput.sessionTitle` to `UserPromptSubmit` hooks for setting the session title".

## Impact on dotforge
- `.claude/rules/domain/hook-events.md` — document the field under UserPromptSubmit
- `.claude/rules/domain/hook-architecture.md` — reference in the decision-control patterns section
- Optional: a `template/hooks/auto-title.sh` that names sessions like `<branch>-<first-prompt-slug>` — would be a low-cost dev-experience win

## Decision
Pending
