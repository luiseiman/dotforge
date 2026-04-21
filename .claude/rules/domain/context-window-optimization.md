---
globs: "template/**/*.md,docs/memory-strategy.md,**/CLAUDE.md,**/rules/memory.md,**/MEMORY.md"
description: "Context window runtime — compaction tiers, size budgets, tool result limits"
domain: claude-code-engineering
last_verified: 2026-04-20
---

# Context Window Runtime

## Compaction hierarchy (5 tiers)

1. API-Native Microcompact: server-side `cache_edits`, zero client mutation
2. Time-Based Microcompact: 60min idle gap, replaces tool results with placeholders
3. Cached Microcompact: queues CacheEditsBlock without mutation
4. Auto Compaction: effectiveContextWindow - buffer. 9-section summarization (20K budget)
5. Context Collapse: ~97% emergency, 500-word summary + last turn only

## Context window sizes

| Model | Context | Max output | Auto-compact buffer |
|-------|---------|------------|-------------------|
| Opus 4.6 | 1M (GA) | 128K tokens | ~33K (~96.7%) |
| Sonnet 4.6 | 1M (GA) | 64K tokens | ~33K (~96.7%) |
| Haiku 4.5 | 200K | 8K tokens | ~13K (~93.5%) |

- Compaction output max: 20K tokens. Circuit breaker: 3 failures → disable for session
- Post-compact restoration: 5 files (50K total, 5K each) + 5 skills (25K total, 5K each)
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80`: lower = earlier compaction
- `CLAUDE_CODE_DISABLE_AUTOCOMPACT=1`: disable entirely
- `/compact <instructions>`: manual trigger with custom preservation hints

## CLAUDE.md and memory limits

- MEMORY.md: 200 lines AND 25KB — whichever triggers first
- CLAUDE.md: <100 lines; modularize into .claude/rules/ if larger
- `claudeMdExcludes` setting: disable specific CLAUDE.md files
- `@include` directive: `@path`, `@./relative`, `@~/home` — max depth 5

## Tool result limits

- Per-tool: 50K chars. MCP override: 500K via `_meta["anthropic/maxResultSizeChars"]`
- Per-turn aggregate: 200K chars. Bash truncation: 30K chars
- Oversized results: persisted to disk, preview sent to Claude
- See `context-control-patterns.md` for user-facing context management (/btw, skill budget, Esc+Esc)

## Prompt cache TTL (v2.1.108+)

- Default: 5 minutes — sleeping past 300s = cache miss
- Opt-in 1 hour: set `ENABLE_PROMPT_CACHING_1H=1` env var; `FORCE_PROMPT_CACHING_5M=1` forces 5m
- With 1h TTL: idle polling cadence heuristics loosen — sleeps up to 3600s stay in cache
- Cost tradeoff: 1h TTL bills for cache storage; 5m is "free". Consider enabling for long-running `/loop` or `/schedule` work
- Subscribers with `DISABLE_TELEMETRY` fell back to 5m before v2.1.108 fix
