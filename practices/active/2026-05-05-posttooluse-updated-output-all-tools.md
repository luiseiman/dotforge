---
id: posttooluse-updated-output-all-tools
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-05-05
tags: [hooks, post-tool-use, capability, high-priority, v2.1.121]
tested_in: []
incorporated_in: ['3.6.0']
---

# `PostToolUse.hookSpecificOutput.updatedToolOutput` now works for ALL tools (v2.1.121)

## Observation

v2.1.121 changelog: `PostToolUse` hooks can replace tool output for any tool — Bash, Edit, Write, Read, etc. — via `hookSpecificOutput.updatedToolOutput`. Previously this field only worked for MCP tools (named `updatedMCPToolOutput`).

## Why it matters for dotforge

`domain/hook-events.md` documents `updatedMCPToolOutput` for MCP tools only. The expanded capability changes hook design tradeoffs:

- Lint/format hooks could rewrite Bash output (e.g. strip trailing whitespace from `cat` results) before the model reads it
- `block-destructive.sh` could be paired with a PostToolUse handler that redacts sensitive output from `git diff` or `env` calls
- Test runners could compress verbose output to a one-line summary before consumption

But also new risks:
- Output rewriting can hide errors the model needs to see (failing tests pass silently if output is overwritten)
- Audit trail confusion: what the model sees ≠ what the tool actually returned

## Required update

1. `domain/hook-events.md` — replace `updatedMCPToolOutput` notes with `updatedToolOutput` (general, since v2.1.121); preserve historical note that pre-v2.1.121 it was MCP-only.
2. `domain/hook-architecture.md` — section on PostToolUse should call out the design tradeoff.
3. Consider whether dotforge ships any hook that should use this (lint-on-save? session-report? probably not — both are fine emitting alongside, not replacing).

## Affected files

- `.claude/rules/domain/hook-events.md`
- `.claude/rules/domain/hook-architecture.md`
