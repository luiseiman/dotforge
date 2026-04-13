---
globs: "**/CLAUDE.md,**/rules/*.md"
description: "User-facing context management — /btw, skill budget, manual pruning"
domain: claude-code-engineering
last_verified: 2026-04-13
---

# Context Control Patterns

User-side interventions to keep the context window healthy. For runtime limits and compaction internals, see `context-window-optimization.md`.

## Side queries with `/btw`

- `/btw <question>`: ephemeral side question. Full conversation visibility, NO tool access, single-turn, reuses parent prompt cache → near-zero marginal cost
- Dismissible overlay (Space/Enter/Esc) — never enters conversation history
- Available while Claude is working — does not interrupt the main turn
- Use to ask about code Claude already read, revisit earlier decisions, or clarify intent without polluting context
- "Inverse of a subagent": subagent has tools but empty context; `/btw` has context but no tools

## Skill budget after compaction

- Re-attachment budget: 25K tokens shared across ALL re-attached skills
- Per-skill cap: first 5K tokens of the most recent invocation
- Order: most recent first — older skills drop when budget is exhausted
- Re-invoke an older skill after compaction to restore its full content
- Skill descriptions have a separate char budget: `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var (default 1% of context window, fallback 8K). Each entry capped at 250 chars — front-load key use case

## Manual pruning

- `Esc+Esc`: rewind conversation or summarize from a selected message
- `Ctrl+O`: toggle transcript viewer — focus view = last prompt + tool summary + response only
- `/compact <instructions>`: manual compaction with custom preservation hints
- `Ctrl+X Ctrl+K`: kill all background agents (double-tap to confirm) — frees their context

## Avoid context pollution

- Globs in rules prevent loading unnecessary context
- Subagents get independent context windows — use for research-heavy work
- Deferred tools: hidden from prompt, discovered via ToolSearch — saves tokens
- `hasReadFile` does NOT survive compaction — re-reads may be needed
