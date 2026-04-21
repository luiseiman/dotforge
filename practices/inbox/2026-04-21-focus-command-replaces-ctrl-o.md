---
id: focus-command-replaces-ctrl-o
source: watch:code.claude.com/docs/en/changelog
status: inbox
captured: 2026-04-21
tags: [ui, drift, context-control, medium-priority, v2.1.110]
tested_in: []
incorporated_in: []
---

# Ctrl+O no longer toggles focus view — `/focus` is the new command

## Observation

v2.1.110: `Ctrl+O` changed to toggle verbose transcript only. The focus view (last prompt + tool summary + response) is now accessed via the `/focus` command.

## Required update

`domain/context-control-patterns.md` "Manual pruning" section says:

> `Ctrl+O`: toggle transcript viewer — focus view = last prompt + tool summary + response only

This needs rewriting:
- `Ctrl+O` → toggles verbose transcript viewer
- `/focus` → toggles focus view (new in v2.1.110)

## Affected files

- `.claude/rules/domain/context-control-patterns.md`
