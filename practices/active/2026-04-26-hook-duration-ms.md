---
id: practice-2026-04-26-hook-duration-ms
title: PostToolUse/PostToolUseFailure hooks include duration_ms (v2.1.119)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [hooks, telemetry, observability, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
`PostToolUse` and `PostToolUseFailure` hook input payloads now include `duration_ms` — tool execution time in milliseconds, excluding permission prompts and PreToolUse hook time. Available since v2.1.119.

## Evidence
CHANGELOG v2.1.119: "Hooks: `PostToolUse` and `PostToolUseFailure` hook inputs now include `duration_ms` (tool execution time, excluding permission prompts and PreToolUse hooks)".

This is a free observability win: dotforge's `template/hooks/session-report.sh` currently has to derive timings externally (or skip them). Native `duration_ms` makes per-tool latency reporting trivial.

## Impact on dotforge
- `template/hooks/session-report.sh` — read `duration_ms` from stdin JSON and emit per-tool latency
- `.claude/rules/domain/hook-events.md` — document the new field under PostToolUse / PostToolUseFailure
- `.claude/rules/domain/hook-architecture.md` — note the field

## Decision
Pending
