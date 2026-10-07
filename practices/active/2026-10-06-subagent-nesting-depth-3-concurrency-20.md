---
id: practice-2026-10-06-subagent-nesting-depth-3-concurrency-20
title: Subagent nesting default depth is 3 (not 5), concurrent cap 20, per-session spawn cap removed (v2.1.217–v2.1.224)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [subagents, agent-orchestration, limits, breaking-change]
tested_in: []
incorporated_in: [".claude/rules/domain/agent-orchestration.md"]
replaced_by: null
effectiveness: informational
error_type: null
---

## Description
- v2.1.219: subagents spawn nested subagents up to **depth 3** by default (was 1). `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH=1` disables nesting. Forks at the limit cannot spawn further.
- v2.1.217: 20 concurrent running subagents by default; `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` overrides; exempt when ultracode is active.
- v2.1.224: the 200-subagent-per-session spawn cap was removed. Lifetime spawn count is now unlimited.
- sub-agents docs confirm: "Max depth = 5 (old) → 3 (v2.1.219+)".

## Evidence
`agent-orchestration.md:17` says "Sub-agent nesting up to 5 levels deep (v2.1.172+)… a 5-level chain with fanout=3 = up to 243 leaf agents". `:113` repeats "up to 5 levels deep" for Agent Teams. Both wrong on current builds.

## Impact on dotforge
- `.claude/rules/domain/agent-orchestration.md`: rewrite nesting + concurrency paragraphs, add both env vars
- `.claude/rules/agents.md`: Agent Teams escalation criteria (depth math)
- `.claude/rules/domain/workflow-economics.md`: fan-out cost examples that assume depth 5

## Decision
Accepted 2026-10-06 — incorporated in dotforge v4.4.0 (/forge update, breaking batch).
