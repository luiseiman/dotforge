---
id: practice-2026-10-06-plugin-root-unquoted-hook-command
title: Quote ${CLAUDE_PLUGIN_ROOT} in shell-form hook commands or use exec form (v2.1.281, v2.1.290)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [plugins, hooks, plugin-generator, breaking-change]
tested_in: []
incorporated_in: ["skills/plugin-generator/SKILL.md", ".claude/rules/domain/hook-architecture.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
v2.1.281: `claude plugin validate` warns when a shell-form hook leaves `${CLAUDE_PLUGIN_ROOT}` unquoted — breaks on plugin paths containing spaces. v2.1.290: an async `Stop` hook with an unquoted path under `~/Library/Application Support` made Claude reply in an endless loop. Fix: `"command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/x.sh\""` or exec form `{"command": "${CLAUDE_PLUGIN_ROOT}/hooks/x.sh", "args": [...]}` (exec form never needs quoting).

## Evidence
`skills/plugin-generator/SKILL.md:117` emits `"command": "${CLAUDE_PLUGIN_ROOT}/hooks/{script-name}.sh"` unquoted; `:126` and `:257` mandate that form. macOS Desktop installs plugins under "Application Support" — the exact failing path.

## Impact on dotforge
- `skills/plugin-generator/SKILL.md`: switch generated hooks to exec form
- `.claude/rules/domain/hook-architecture.md` § Command hook forms: add the quoting rule
- `.claude/rules/domain/plugin-distribution.md`: note `claude plugin validate --json` + `gatingHooks` report
- Audit any shipped `hooks/hooks.json` in `integrations/` and marketplace plugin

## Decision
Accepted 2026-10-06 — incorporated in dotforge v4.4.0 (/forge update, breaking batch).
