---
name: glob-specificity-fix
description: Domain rule globs must never use broad wildcards like **/*.md — always verify real paths and use specific patterns
type: feedback
---

Using `**/*.md` as a glob in domain rules defeats the purpose: the rule loads on every markdown edit regardless of relevance, inflating context.

**Why:** Domain rules exist to inject focused context only when editing the relevant subsystem. A broad wildcard makes them always-on, no better than putting content in CLAUDE.md.

**How to apply:** When writing or fixing globs in `.claude/rules/domain/` files:
- Always run `ls` on relevant directories first to confirm real paths exist
- Use the narrowest match possible: specific filenames > directory globs > extension globs
- If a glob includes `**/*.md` alongside more specific patterns, the specific patterns are redundant — remove the broad one
- Prefer listing specific files (`core/pipeline.py,core/data_bus.py`) over directory wildcards (`core/**`) when only a subset of files is relevant

## 2026-03-25 — claude-kit + TRADINGBOT glob audit
- **Learned:** `**/*.md` appeared in two claude-kit domain rules, making them load on every markdown file. The TRADINGBOT data-flow rule covered `strategies/**` even though strategies don't participate in the data pipeline.
- **Avoid:** Mixing broad extension globs with specific path globs — the broad one makes the specific ones meaningless.
