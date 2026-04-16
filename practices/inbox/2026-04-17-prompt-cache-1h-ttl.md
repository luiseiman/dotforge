---
id: prompt-cache-1h-ttl
source: watch:code.claude.com/docs/en/changelog
status: inbox
captured: 2026-04-17
tags: [cache, context-window, cost, high-priority, v2.1.108]
tested_in: []
incorporated_in: []
---

# 1-hour prompt cache TTL — opt-in via `ENABLE_PROMPT_CACHING_1H`

## Observation

v2.1.108 introduced a 1-hour prompt cache TTL opt-in via the `ENABLE_PROMPT_CACHING_1H` env var. Default remains 5 minutes. This is a significant expansion for long-running sessions that previously paid cache-miss costs on the 5-min boundary.

## Why it matters for dotforge

`domain/context-window-optimization.md` documents the 5-minute TTL as foundational:

> The Anthropic prompt cache has a 5-minute TTL. Sleeping past 300 seconds means the next wake-up reads your full conversation context uncached...

This is no longer the only option. The 1h TTL changes the cache economics:
- Long-running `/loop` or `/schedule` work can now amortize cache across 60 min instead of 5
- ScheduleWakeup cadence heuristics (in the `workflow-automation.md` rule) assume 5-min boundary — become less relevant with 1h TTL
- Cost analysis of idle polls changes significantly

## Required update

Add to `domain/context-window-optimization.md`:

```
## Prompt cache TTL

- Default: 5 minutes (sleeping past 300s = cache miss)
- Opt-in 1 hour: set `ENABLE_PROMPT_CACHING_1H=1` env var (v2.1.108+)
- With 1h TTL: idle polling cadence heuristics become much less strict — 
  sleeps up to 3600s stay in cache
- Cost tradeoff: 1h TTL bills for cache storage; 5m is "free"
- Consider enabling for long-running /loop or /schedule work
```

Cross-ref from `domain/workflow-automation.md` cadence section.

## Affected files

- `.claude/rules/domain/context-window-optimization.md`
- `.claude/rules/domain/workflow-automation.md` (cross-ref)
