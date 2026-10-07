---
id: practice-2026-08-07-subagent-output-scanning
title: Subagent output scanning (v2.1.210+) adds backslash/marker to instruction-shaped patterns
source: "/forge watch — Claude Code upstream docs"
source_type: upstream-doc
discovered: 2026-08-07
status: active
tags: [subagents, prompt-injection, security, defense-in-depth]
tested_in: []
incorporated_in: [".claude/rules/domain/agent-orchestration.md"]
replaced_by: null
---

## Description
Since v2.1.210, Claude Code scans every subagent's final report BEFORE the main conversation reads it. Two automatic transformations:

1. **Backslash insertion**: text that imitates Claude Code output (e.g. `<system-reminder>` tags, lines starting with `Human:` or `Assistant:`) gets a backslash inserted so it reads as ordinary text.
2. **Marker line**: prepends `[harness: subagent output matched instruction-shaped pattern(s):` when the report imitates a `<system-reminder>` tag or mentions permission settings like `bypassPermissions` or `--dangerously-skip-permissions`.

This is a defense against prompt injection: a subagent that reads a hostile file/URL/tool-output could otherwise return text engineered to hijack the main conversation. The scan doesn't judge intent — it flags. Downstream permission checks and sandboxing still apply to any tool call the marked report might steer Claude toward.

## Evidence
Fetched from https://code.claude.com/docs/en/sub-agents#subagent-output-scanning (2026-08-07):
> "Claude Code scans each subagent's final report before Claude reads it. A subagent may have read files, web pages, or command output you never reviewed, and text from those sources can carry instructions aimed at the main conversation."

dotforge `domain/agent-orchestration.md` and `agents/*.md` don't mention this defense layer.

## Impact on dotforge
- Update `domain/agent-orchestration.md` — document the scanner as a subagent-level defense (adjacent to existing sandbox / permission notes)
- Update `agents/researcher.md`, `agents/session-reviewer.md` — clarify that reading untrusted content (web fetches, log files) is still safe because scanner flags injected patterns before main conversation sees them
- Not a substitute for the existing rule that subagents should be restricted (`tools:` allowlist, `permissionMode`, `disallowedTools`)

## Decision
Pending
