---
name: soma2_domain_extract_pattern
description: Pattern for /forge domain extract on SOMA2 — sources to read, files created, CLAUDE.md Role section
type: project
---

When running `/forge domain extract` on SOMA2:

**Sources that exist and are useful:**
- `CLAUDE.md` — comprehensive, covers stack, architecture, layer boundaries, LLM providers, Redis keys, conventions
- `CLAUDE_ERRORS.md` — exists but was empty on 2026-03-25
- `.claude/agent-memory/implementer/` — has 3 feedback memories (claude_cli_system_prompt, property_vs_method, ruff_import_order)
- `.claude/rules/` — 14 existing rule files (backend, security, redis, agents, memory, model-routing, tui, infrastructure, etc.)
- No auto-memory existed at `/Users/luiseiman/.claude/projects/-Users-luiseiman-Documents-GitHub-SOMA2/memory/`

**Files created** in `.claude/rules/domain/`:
- `llm-providers.md` — provider chain priority, Claude CLI --system-prompt gotcha, circuit breaker
- `redis-streams.md` — soma.* stream names, soma: key schema, IDs format, XACK rules
- `otar-loop.md` — Observe-Think-Act-Reflect, tool call parsing regex, security gate, agent registry
- `security-policy.md` — L0-L4 risk levels, danger patterns, allowlist source
- `classifier.md` — 4 routes (CHAT/INTERNAL_OPS/HYBRID/EXTERNAL_TASK), deterministic, no LLM
- `channels.md` — TUI (Textual+SSE), Telegram polling, Web React+Vite, SSE event flow
- `error-journal.md` — ErrorJournal top-10 auto-injected, ThreadMemory 40 msgs 7d TTL
- `vps-deploy.md` — Oracle ARM64, Tailscale, Docker Compose, env vars

**Why:** `## Role` section was missing in CLAUDE.md — added 6-line summary covering what SOMA2 is and its key properties.
