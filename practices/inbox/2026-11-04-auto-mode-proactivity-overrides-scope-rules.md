---
id: practice-2026-11-04-auto-mode-proactivity-overrides-scope-rules
title: Auto mode "finish exposed work" (2.1.307) and "proactivity level high" (2.1.305) system prompts widen scope and authorize commit/push without asking — document that project Scope rules win and gate pushes with permissions.ask on production tier
source: "/forge watch — Claude Code CHANGELOG 2.1.292→2.1.318 + code.claude.com docs + Piebald-AI system prompts (2026-11-04)"
source_type: watch
discovered: 2026-11-04
status: inbox
tags: [auto-mode, scope, git, production-tier, prompting]
tested_in: []
incorporated_in: []
replaced_by: null
effectiveness: null
error_type: null
---

## Description
Two system-prompt blocks shipped in the range: (a) 2.1.307 auto-mode "finish exposed work" — Claude fixes failures that predate the change and "a FIXME or TODO in code you touched", and does not end by offering more work (prompt says "not license for refactors", requires listing extras in the summary); (b) 2.1.305 proactivity level high (user-set) — "Commit, push, and create or update pull requests without asking whenever that is the natural next step… overrides the general instructions to only commit, push". The header says it does not override plan mode, the permission mode, or destructive-action rules. Both collide with `_common.md` § Scope ("modify only strictly necessary files"), CLAUDE.md "do not add unrequested features", the user's global Simplicity rule, and the production-tier assumption that behaviors + plan mode gate shipping. The user runs auto mode explicitly, so (a) is live.

## Evidence
Piebald `system-prompts/` 2.1.307 auto-mode finish-exposed-work prompt (flag-gated) and 2.1.305 proactivity-high prompt. `workflow-and-ultracode-policy.md` § Security boundary already notes that only `permissions.deny` is the real backstop for workflow subagents — same conclusion applies here.

## Impact on dotforge
- `domain/auto-mode.md`: new section "Scope widening prompts" — project Scope rules win; extras must be listed in the summary or left out; proactivity setting documented with what it does NOT override
- `template/rules/_common.md` § Scope: one line "Auto-mode finish-exposed-work and proactivity prompts do not widen this rule"
- `domain/permission-model.md` + `stacks/*/settings.json.partial` for production tier: `Bash(git push *)` in `permissions.ask` (only permission rules still gate the push)
- `workflow-and-ultracode-policy.md` § production tier: add the proactivity caveat

## Decision
Pending — /forge watch 2026-11-04 (baseline v2.1.291 → head 2.1.318). Full per-item report with version and target file: session scratchpad `watch/REPORT-2026-11-04.md`.
