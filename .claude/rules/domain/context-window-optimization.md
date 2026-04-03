---
globs: "template/**/*.md,docs/memory-strategy.md,**/CLAUDE.md,**/rules/memory.md,**/MEMORY.md"
description: "Context window management and token optimization patterns"
domain: claude-code-engineering
last_verified: 2026-04-03
---

# Context Window Optimization

## 5-tier compaction hierarchy (source-verified)

1. API-Native Microcompact: server-side `cache_edits`, zero client mutation
2. Time-Based Microcompact: 60min idle gap, replaces tool results with placeholders
3. Cached Microcompact: queues CacheEditsBlock without mutation
4. Auto Compaction: ~90% window, full 9-section summarization (20K token budget)
5. Context Collapse: ~97% emergency, 500-word summary + last turn only

## Key constants

- Auto-compact buffer: 13,000 tokens
- Warning threshold: 20,000 tokens remaining
- Compaction output max: 20,000 tokens
- Circuit breaker: 3 consecutive failures disables auto-compact for session
- Post-compact file restoration: 5 files, 50K total, 5K per file
- Skill restoration: 25K total, ~5 skills, 5K each

## Env vars for compaction control

- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75`: override auto-compact threshold (default ~90%). Lower = earlier compaction, more room for hooks
- `CLAUDE_CODE_DISABLE_AUTOCOMPACT=1`: disable auto-compaction entirely
- `/compact <instructions>`: manual trigger with custom instructions to guide what the compressor preserves

## CLAUDE.md and memory

- MEMORY.md index: only first 200 lines injected — anything beyond invisible
- CLAUDE.md must be <100 lines; if larger, modularize into .claude/rules/
- Every line in CLAUDE.md must change behavior — if removed, Claude should fail
- Context injection prepends `<system-reminder>` block with claudeMd + directoryStructure + gitStatus
- `claudeMdExcludes` setting: disable specific CLAUDE.md files without deleting
- `CLAUDE_CODE_DISABLE_CLAUDE_MDS` env var: disable all CLAUDE.md loading (debug)
- `@include` directive: `@path`, `@./relative`, `@~/home` — max depth 5

## Optimization patterns

- Use globs in rules to prevent loading unnecessary context
- Delegate research-heavy work to subagents (independent context windows)
- Subagent summaries must not exceed 30% of main context
- Search/read deduplication: system auto-collapses repeated reads of same file
- Deferred tools: hidden from prompt, discovered via ToolSearch — saves tokens
- Thinking disabled during compaction summarization to save tokens
- `hasReadFile` state does NOT survive compaction — re-reads may be needed
- Compact format: imperative mood, one instruction per line, no filler
