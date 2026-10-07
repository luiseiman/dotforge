---
id: practice-2026-08-07-explore-inherits-main-model
title: Explore built-in subagent inherits main model (v2.1.198+, capped at Opus)
source: "/forge watch — Claude Code upstream docs"
source_type: upstream-doc
discovered: 2026-08-07
status: active
tags: [subagents, model-routing, cost, breaking-change]
tested_in: []
incorporated_in: [".claude/rules/domain/model-ids.md,.claude/rules/model-routing.md"]
replaced_by: null
---

## Description
Prior to v2.1.198, Claude Code's built-in `Explore` subagent always ran on Haiku — an intentional cost-optimization for read-only search work. Since v2.1.198 it inherits the main conversation's model, capped at Opus on the Claude API. A session running on Opus 4.7/4.8 now also pays Opus rates for exploration.

This invalidates dotforge's `.claude/rules/model-routing.md` assumption ("haiku → researcher, test-runner. Default agents: researcher, test-runner"). The built-in Explore is a distinct entity from dotforge's custom `researcher` agent — the model-routing rule covers the custom agent (which explicitly declares `model: haiku` in its frontmatter), but Claude routinely delegates to built-in Explore when the user asks for codebase exploration, and that path now runs at main-session cost.

Override: a user- or project-level subagent named `Explore` overrides the built-in and keeps its own `model` field. Setting `model: haiku` in a custom `~/.claude/agents/Explore.md` restores the old cost profile.

## Evidence
Fetched from https://code.claude.com/docs/en/sub-agents (2026-08-07):
> "As of v2.1.198, Explore inherits the main conversation's model instead of always running on Haiku. On the Claude API, the inherited model is capped at Opus [...] A user or project subagent named `Explore` overrides the built-in and keeps its own `model` field, so define one with `model: haiku` to keep exploration on a lower-cost model."

## Impact on dotforge
- Update `.claude/rules/model-routing.md` — add note distinguishing custom `researcher` agent (pinned to haiku) from built-in `Explore` (inherits main model unless overridden)
- Update `domain/model-ids.md` — add cost-implication note for production-tier projects on Opus 4.7/4.8
- Consider shipping a `template/agents/Explore.md` with `model: haiku` as opt-in override for cost-conscious projects
- Related: `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1` disables built-in Explore/Plan entirely (Claude reads files directly)

## Decision
Pending
