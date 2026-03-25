---
name: soma_domain_extract_pattern
description: Pattern for /forge domain extract on SOMA (luiseiman/SOMA) — sources read, files created, CLAUDE.md Role section
type: project
---

When running `/forge domain extract` on SOMA (at `/Users/luiseiman/Documents/GitHub/SOMA`):

**Sources that exist and are useful:**
- `CLAUDE.md` — covers stack, pipeline, services table, security policy, key files
- `CLAUDE_ERRORS.md` — exists but was empty on 2026-03-25
- Auto-memory at `~/.claude/projects/-Users-luiseiman-Documents-GitHub-SOMA/memory/` — rich, 9 files (arquitectura.md is the most detailed; lecciones.md has 36 lessons; errores_produccion.md has top 10 prod errors)
- `.claude/rules/` — 9 existing rule files (backend, planner, deploy, frontend, ios, api-parity, agents, tests, _common)
- `.claude/agent-memory/implementer.md` — minimal (only scaffold placeholder)

**Files created** in `.claude/rules/domain/`:
- `llm-routing.md` — provider chain priority, task→provider classification, OpenClaw JSON format, SYSTEM_CONTEXT injection
- `redis-streams.md` — soma.* stream names, soma: key schema, TTLs, asyncio constraint, network mode impact
- `pipeline-classification.md` — 4 routes, intent resolver states, special sub-categories, deep_research branch, agent routing, memory_ctx propagation
- `security-policy.md` — L0-L4 risk levels, allowlist enforcement, danger patterns, planner_gate, web access policy, auth modes
- `vps-deployment.md` — Oracle ARM64, Tailscale setup, soma update command, depends_on cascade issue, verification checklist
- `agent-skill-system.md` — 5 built-in agents, hot-reload, inter-agent delegation, skill evolution (Sprint 5), feedback loops
- `channel-adapters.md` — canonical input format, adapter table (Telegram/Slack/GitHub/Web), SSE reconnection pattern, deep_research SSE events

**CLAUDE.md Role section:** Added after first heading. Covers: multi-LLM orchestration, Redis Streams, Python async, security policy (L0-L4), and pointer to `.claude/rules/domain/`.
