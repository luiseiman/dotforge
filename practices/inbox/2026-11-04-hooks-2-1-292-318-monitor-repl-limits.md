---
id: practice-2026-11-04-hooks-2-1-292-318-monitor-repl-limits
title: Hooks 2.1.292→2.1.318: Bash matchers now cover Monitor-tool commands, Code Mode/REPL batches tool calls (verify block-destructive fires inside), per-source hook limits (1,024 hooks / 16,384 matcher chars), 24 concurrent prompt/agent hooks, updatedInput validated, <system-reminder> escaped, PreCompact output capped at 10K, managed continue:false ends the turn
source: "/forge watch — Claude Code CHANGELOG 2.1.292→2.1.318 + code.claude.com docs + Piebald-AI system prompts (2026-11-04)"
source_type: watch
discovered: 2026-11-04
status: inbox
tags: [hooks, security, hook-events, compiler]
tested_in: []
incorporated_in: []
replaced_by: null
effectiveness: null
error_type: null
---

## Description
Hook-contract additions since v2.1.291, all verified in the raw CHANGELOG or official hooks doc:
- 2.1.314: hooks matching `Bash` run on shell commands started by the Monitor tool; they can block or ask, not approve or rewrite; `if: "Monitor(tail *)"` matches like `Bash(tail *)`. Extends `block-destructive.sh` coverage for free.
- 2.1.318 (system prompt): Code Mode / REPL tool batches tool calls in JS; auto mode refuses dynamically constructed commands and calls rewritten by a hook; sub-agents started from code are refused; retry rule "send this code once more, in a response with no other tool calls". Open question: does a `PreToolUse` `Bash` hook fire for commands issued inside a REPL script? Must be verified empirically before trusting `block-destructive.sh` in sessions with Code Mode.
- 2.1.304: skills from one source may register at most 1,024 hooks and 16,384 matcher characters per session; `once` hook collision fix.
- 2.1.312: prompt/agent hooks run at most 24 at a time per session (+12 queued past timeout); `timeout` < 1s counts as 1s. 2.1.302: at most 12 prompt/agent hooks of one event concurrently.
- 2.1.300: agent hooks honor `model`; unavailable model falls back to the caller's model instead of allowing. `updatedInput` from PreToolUse/PermissionRequest is validated like Claude's own input — unknown keys dropped, rejected input denies the call.
- 2.1.299: `UserPromptSubmit` runs before a skill/slash command expands (a blocking hook also stops embedded shell commands); plugin hooks that can block are refused (not let through) when they cannot be handed the action.
- 2.1.296: managed PreToolUse hooks that deny with `continue:false` end the turn; managed PostToolUse applies `updatedMCPToolOutput`; async multi-line JSON honored (2.1.295); async SessionStart context deduped on resume; `CLAUDE_ENV_FILE` reaches PowerShell and survives in-app `/resume`.
- 2.1.294: instruction-style `prompt`/`agent` hooks ("Block commands that…") used to allow what they should block — fixed; evaluators now require `{ok, reason}` and treat event JSON as data.
- 2.1.292: `<system-reminder>` tags in hook output are escaped before reaching Claude.
- 2.1.314: each PreCompact hook's output cut at 10,000 chars. 2.1.311: `SubagentStop` fired ~2×/min per running subagent before the fix (metrics overcounted).
- 2.1.318 reminder: a call is refused when a PreToolUse hook with `onFailure: "block"` times out or an agent hook ends without a decision — conditional, consistent with the official default fall-through documented in v4.9.0.

## Evidence
CHANGELOG lines in `## 2.1.314` (Monitor, PreCompact cap, blockWrites), `## 2.1.312`, `## 2.1.304`, `## 2.1.300`, `## 2.1.299`, `## 2.1.296`, `## 2.1.294`, `## 2.1.292`; Piebald `system-reminder-pretooluse-hook-timeout-recovery.md` (ccVersion 2.1.318) and the Code Mode tool prompts; official `hooks.md` § Block the action when a hook fails.

## Impact on dotforge
- `domain/hook-architecture.md`: Monitor coverage, limits, concurrency caps, prompt/agent evaluator contract, `<system-reminder>` escaping, Code Mode section
- `domain/hook-events.md`: UserPromptSubmit ordering, managed `continue:false`, PreCompact 10K, SubagentStop floor, `updatedInput` validation note
- Empirical test: run a REPL script containing a STANDARD pattern with `block-destructive.sh` wired; add a `REPL` matcher if it does not fire
- `scripts/compiler/compile.sh`: consider emitting `Monitor` in the generated matcher for Bash-targeted behaviors

## Decision
Pending — /forge watch 2026-11-04 (baseline v2.1.291 → head 2.1.318). Full per-item report with version and target file: session scratchpad `watch/REPORT-2026-11-04.md`.
