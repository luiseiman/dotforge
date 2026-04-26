---
id: agent-memory-underused
source: session-insights
status: inbox
captured: 2026-04-21
tags: [insights, agents, agent-memory, low-priority, needs-more-info]
tested_in: [dotforge]
incorporated_in: []
---

# Agent memory is underused — 1–2 entries per agent across ~5 months

## Observation

`.claude/agent-memory/` in dotforge has:
- architect.md: 1 entry (2026-03-21)
- code-reviewer.md: 2 entries (2026-04-13)
- implementer.md: 2 entries
- security-auditor.md: 1 entry

Agents have persistent memory enabled but accumulate little content. Either agents aren't being used as often as needed, or they're not saving learnings.

## Hypotheses

1. Agent prompts don't instruct "persist learning after task" (verify each agent's system prompt)
2. Agents are used but their output gets summarized into main thread — the "structured summary" culture drops the nuances worth remembering
3. Main thread does the work directly (single-file fixes per `rules/agents.md` decision tree) — legitimate, low use

## Suggested action

1. Add a post-task checklist to each memory-enabled agent: "Before returning, did you discover a non-obvious pattern worth persisting? Write it to agent-memory/<agent>.md."
2. In `/forge insights`, add a "agents underused" warning if any memory file has < 3 entries after N weeks of project activity.
3. Consider whether `researcher` and `test-runner` (transactional, no memory) should get memory too — they may discover patterns worth keeping.

Low priority — might be working as designed. Worth a brief review, not a big project.

## Affected files

- `agents/*.md` (append persistence checklist)
- `skills/session-insights/SKILL.md` (add warning)
