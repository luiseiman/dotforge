---
id: practice-2026-03-20-session-reviewer
title: "session-reviewer agent as 7th standard agent in claude-kit"
source_type: project-observation
source: claude-kit (agents/session-reviewer.md)
status: evaluating
evaluated_date: 2026-03-20
evaluation_notes: "Good agent, needs testing in 2+ external projects. Fix transcript dependency docs, remove emojis from output format."
tags: [agents, orchestration, session-analysis, pattern-detection]
date: 2026-03-20
tested_in: [claude-kit]
incorporated_in: []
---

## Observation

A `session-reviewer` agent was created during a real project session and committed to claude-kit. It handles session analysis, pattern detection, and feeds `/forge insights`.

## Current State

- Agent definition exists at `agents/session-reviewer.md`
- Delegation rule added to `.claude/rules/agents.md` (item 8)
- Currently only referenced by claude-kit itself — not yet in the base template

## Evaluation Needed

1. **Generalizability**: Does this agent add value in projects that don't use `/forge insights`? Or is it claude-kit-specific?
2. **Template inclusion**: Should it be added to `template/.claude/rules/agents.md` as a standard agent, or remain optional?
3. **Agent count**: Going from 6 to 7 agents — does the orchestration decision tree stay clean?
4. **Memory policy**: The agent has `memory: project` — verify it follows the memory.md protocol correctly.

## Recommendation

Evaluate after 2-3 more sessions using the agent in different projects. If it proves useful beyond claude-kit, promote to template.
