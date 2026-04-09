---
id: practice-2026-04-06-defer-permission-hook-event
title: "Hooks can defer permission decisions (new event type)"
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-04-06
status: active
tags: [hooks, permissions, security]
tested_in: null
incorporated_in: [".claude/rules/domain/hook-events.md", ".claude/rules/domain/hook-architecture.md"]
replaced_by: null
effectiveness: not-applicable
---

## Descripción
v2.1.89 introduced "defer" as a new permission decision mode for hooks. Instead of allow (0), warn (1), or block (2), a hook can now defer the decision — allowing an async external system (e.g., a Slack approval flow or mobile notification) to grant or deny the operation. Combined with `asyncRewake: true`, this enables human-in-the-loop approval for sensitive operations without blocking the terminal.

## Evidencia
Official changelog v2.1.89 (April 1, 2026): "Faster resume flows, new hook events (including 'defer' permission decisions)."

## Impacto en claude-kit
- `docs/best-practices.md` — update Hooks section: add "defer" as fourth exit behavior (alongside 0/1/2)
- `template/hooks/block-destructive.sh` — could evolve into a defer pattern for production ops
- `hooks/` — add example defer hook for mobile-approval workflow

## Decisión
Incorporado en hook-events.md (defer detail) y hook-architecture.md. v2.9.0 + update 2026-04-08.
