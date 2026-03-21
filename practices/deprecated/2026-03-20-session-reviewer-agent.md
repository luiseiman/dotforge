---
id: practice-2026-03-20-session-reviewer
title: "session-reviewer agent as 7th standard agent in claude-kit"
source_type: project-observation
source: claude-kit (agents/session-reviewer.md)
status: deprecated
evaluated_date: 2026-03-20
deprecated_date: 2026-03-21
deprecated_reason: "Incorporated. Agent promoted to template in v2.5.0: template/rules/agents.md item #8, agents/session-reviewer.md, model-routing.md. Evaluation questions resolved."
tags: [agents, orchestration, session-analysis, pattern-detection]
date: 2026-03-20
tested_in: [claude-kit]
incorporated_in: [template/rules/agents.md, agents/session-reviewer.md, template/rules/model-routing.md]
replaced_by: null
---

## Observation

A `session-reviewer` agent was created during a real project session and committed to claude-kit. It handles session analysis, pattern detection, and feeds `/forge insights`.

## Resolution

All evaluation questions resolved in v2.5.0:

1. **Generalizability**: Useful in any project with `/forge insights` or session analysis needs — not claude-kit-specific.
2. **Template inclusion**: Added to `template/rules/agents.md` as item #8. Standard agent in all bootstrapped projects.
3. **Agent count**: Decision tree expanded to 8 items cleanly.
4. **Memory policy**: Confirmed transactional (no `memory:` key in agent definition — corrects the evaluating note which incorrectly stated `memory: project`).
