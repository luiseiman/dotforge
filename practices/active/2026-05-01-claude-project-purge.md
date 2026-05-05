---
id: practice-2026-05-01-claude-project-purge
title: "claude project purge [path] — borrar todo el estado de Claude Code de un proyecto"
source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
source_type: changelog
discovered: 2026-05-04
status: active
tags: [cli, reset, forge-reset, medium-priority]
tested_in: null
incorporated_in: ['3.5.0']
replaced_by: null
---

## Descripción
Nuevo subcomando `claude project purge [path]` que elimina todo el estado de Claude Code asociado a un proyecto: sesiones, manifests, telemetría local, caches.

## Evidencia
- Changelog v2.1.126 (2026-05-01).
- Releasebot lo lista como "project purge tools" entre las mejoras del release.

## Impacto en dotforge
MEDIO — `skills/forge-reset` ya existe y restaura `.claude/` desde el template. Pero NO toca el estado de Claude Code propio (sesiones en `~/.claude/projects/`, manifests). Resultado: tras un `/forge reset` quedan sesiones huérfanas referenciando archivos viejos.

Acción sugerida: `/forge reset` debería ofrecer correr `claude project purge $PWD` después del restore (con confirmación), o documentar el paso manual.

## Archivos potencialmente afectados
- `skills/forge-reset/SKILL.md`
- `commands/reset.md`

## Decisión
Pendiente — verificar primero que el comando existe en la CLI instalada (`claude project purge --help`) antes de incorporar.
