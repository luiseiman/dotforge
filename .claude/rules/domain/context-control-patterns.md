---
globs: "**/CLAUDE.md,**/rules/*.md"
description: "User-facing context management — /btw, skill budget, manual pruning"
domain: claude-code-engineering
last_verified: 2026-04-26
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
- `Ctrl+O`: toggle **verbose** transcript viewer (v2.1.110 changed: no longer the focus-view toggle)
- `/focus`: toggle focus view — last prompt + tool summary + final response only (v2.1.110+, replaces old Ctrl+O behavior)
- `/compact <instructions>`: manual compaction with custom preservation hints
- `Ctrl+X Ctrl+K`: kill all background agents (double-tap to confirm) — frees their context

## TUI rendering modes (v2.1.110+)

- `tui` setting in `settings.json`: `"fullscreen"` or `"default"` (default). Fullscreen renders without flicker — useful in long sessions and inside tmux/zellij
- `/tui` slash command toggles between modes mid-session without losing the conversation
- `autoScrollEnabled`: disable conversation auto-scroll in fullscreen mode

## Idle-return recap (v2.1.108+)

- `/recap`: summarize session state on demand
- `awaySummaryEnabled` setting: auto-show recap when returning to an idle session
- `CLAUDE_CODE_ENABLE_AWAY_SUMMARY=1` env var: forces recap on for telemetry-disabled deployments (Bedrock, Vertex, Foundry, `DISABLE_TELEMETRY`); v2.1.110 enabled it by default for those users — opt out via `/config` or `=0`
- Coexists with dotforge's `last-compact.md` pattern: recap = idle return summary (user-driven), `last-compact.md` = surviving compaction (model-driven). They solve adjacent problems

## Avoid context pollution

- Globs in rules prevent loading unnecessary context
- Subagents get independent context windows — use for research-heavy work
- Deferred tools: hidden from prompt, discovered via ToolSearch — saves tokens
- `hasReadFile` does NOT survive compaction — re-reads may be needed
