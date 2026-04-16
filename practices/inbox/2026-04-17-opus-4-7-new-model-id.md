---
id: opus-4-7-new-model-id
source: watch:code.claude.com/docs/en/changelog
status: inbox
captured: 2026-04-17
tags: [model-routing, drift, high-priority, v2.1.111]
tested_in: []
incorporated_in: []
---

# Opus 4.7 — new model ID, replaces 4.6

## Observation

Claude Code v2.1.111 (2026-04-16) introduced Claude Opus 4.7. Our `domain/model-ids.md` still references `claude-opus-4-6`.

## Required update

| Tier | Old | New |
|------|-----|-----|
| opus | `claude-opus-4-6` | `claude-opus-4-7` (likely — verify exact ID) |

Context/output token counts unchanged presumably. Need to verify against official docs.

## Affected files

- `.claude/rules/domain/model-ids.md` — update model ID
- `agents/architect.md`, `agents/security-auditor.md` — if they pin opus-4-6 explicitly
- `docs/changelog.md` + VERSION bump

## Impact

Projects pinning `claude-opus-4-6` may soon hit deprecation warnings or auto-upgrades. Update proactively.
