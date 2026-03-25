---
globs: "template/**/*.md,docs/memory-strategy.md,**/CLAUDE.md,**/rules/memory.md,**/MEMORY.md"
description: "Context window management and token optimization patterns"
domain: claude-code-engineering
last_verified: 2026-03-25
---

# Context Window Optimization

- MEMORY.md index: only first 200 lines injected at session start — anything beyond is invisible
- If MEMORY.md approaches 150 lines, archive low-relevance entries or consolidate
- Memory files themselves have no line limit — only the index is capped
- CLAUDE.md must be <100 lines; if larger, modularize into .claude/rules/
- Every line in CLAUDE.md must change Claude's behavior — if removed, Claude should fail
- Use globs in rules to prevent loading unnecessary context into the window
- Delegate research-heavy work to subagents to protect main thread context
- Subagent summaries must not exceed 30% of main context — prefer structured summaries
- Compact format: imperative mood, one instruction per line, no hedging, no filler
- Rules auto-load by glob matching — only relevant context enters the window
