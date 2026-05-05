---
id: practice-2026-05-01-skip-permissions-claude-paths
title: "--dangerously-skip-permissions ya no prompea por escrituras en .claude/{skills,agents,commands}"
source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
source_type: changelog
discovered: 2026-05-04
status: active
tags: [permissions, automation, agent-flows, medium-priority]
tested_in: null
incorporated_in: ['3.5.0']
replaced_by: null
---

## Descripción
En v2.1.126, `--dangerously-skip-permissions` ahora bypasea los prompts de permiso para escrituras en `.claude/skills/`, `.claude/agents/` y `.claude/commands/`. Antes esos paths estaban en una lista protegida que pedía confirmación incluso con la flag activa.

## Evidencia
- Changelog v2.1.126 (2026-05-01).

## Impacto en dotforge
MEDIO — relevante para flujos automatizados de:
- `skills/forge-sync` (instala/actualiza skills, commands, agents desde el template)
- `skills/bootstrap-project`
- CI/CD que corra Claude Code con la flag activa

Antes había que pre-aprobar paths o usar `acceptEdits`. Ahora `--dangerously-skip-permissions` cubre el caso completo. Documentar en `docs/security-checklist.md` como trade-off explícito (eficiencia automatización vs. exposición a prompt injection que toque template files).

## Archivos potencialmente afectados
- `docs/security-checklist.md` (advertencia)
- `docs/usage-guide.md` (mencionar para CI)

## Decisión
Pendiente — incorporación es informativa (no requiere cambios funcionales en dotforge). Decidir si vale la nota documental.
