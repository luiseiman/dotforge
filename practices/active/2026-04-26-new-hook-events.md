---
id: practice-2026-04-26-new-hook-events
title: New blockable hook events UserPromptExpansion and PostToolBatch
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [hooks, upstream, breaking-docs]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
The hook event catalogue grew beyond the "31 events" claim in dotforge:

- **`UserPromptExpansion`** — fires when a slash command expands. Matcher: command name. Blockable (can prevent the expansion).
- **`PostToolBatch`** — fires when a batch of parallel tool calls completes, before the next model call. No matcher. Blockable via `decision: "block"`.

Both are documented in the live hooks reference at code.claude.com/docs/en/hooks.

## Evidence
Fetched code.claude.com/docs/en/hooks (2026-04-26). Full event list now contains both events with explicit "Can Block? Yes" entries. dotforge's `.claude/rules/domain/hook-architecture.md` declares "31 total" and does not list either.

## Impact on dotforge
- `.claude/rules/domain/hook-architecture.md` — update event count (33+) and add both events with their matcher/blocking semantics
- `.claude/rules/domain/hook-events.md` — add field-level details (decision schema, when each fires, useful patterns)
- Consider whether any `template/hooks/` could leverage `PostToolBatch` for end-of-batch validation that currently runs per-tool in `PostToolUse`

## Decision
Pending
