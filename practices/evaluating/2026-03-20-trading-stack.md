---
id: practice-2026-03-20-trading-stack
title: "trading stack — domain-specific stack for trading projects"
source_type: project-observation
source: claude-kit (stacks/trading/)
status: evaluating
evaluated_date: 2026-03-20
evaluation_notes: "Clean structure, convention-compliant. Add category:domain to plugin.json. Test in InviSight or trading project before promoting to active."
tags: [stacks, trading, domain-specific, skills]
date: 2026-03-20
tested_in: [claude-kit]
incorporated_in: []
---

## Observation

A `trading` stack was created during a real project session. It follows claude-kit stack conventions correctly (rules/, settings.json.partial, plugin.json, skills/) with no application code — only Claude Code configuration.

## Current Contents

- `stacks/trading/rules/trading.md` — contextual rules for trading projects
- `stacks/trading/settings.json.partial` — permissions config
- `stacks/trading/plugin.json` — stack metadata
- `stacks/trading/skills/` — 4 skills: catalyst-calendar, earnings-watch, screen, thesis-tracker

## Evaluation Needed

1. **Audience**: Trading is a niche domain. Other stacks (python-fastapi, react-vite-ts, docker-deploy) are broadly applicable. Is a trading stack useful beyond Luis's own projects?
2. **Precedent**: If accepted, this opens the door for other domain-specific stacks (healthcare, e-commerce, etc.). Is that the direction claude-kit should go?
3. **Convention compliance**: Structure looks correct — no application code, only config/rules/skills. This is a clean stack.
4. **Skills quality**: 4 skills is a lot for one stack. Are they well-scoped? Do they overlap?
5. **Alternative**: Could this be a "community stack" or "personal stack" category rather than an official stack?

## Recommendation

This stack is clean and well-structured but domain-specific. Consider creating a `stacks/community/` or `stacks/personal/` tier to distinguish broadly-useful stacks from domain-specific ones. Accept as-is for personal use, but don't promote to the official stack list without broader demand.
