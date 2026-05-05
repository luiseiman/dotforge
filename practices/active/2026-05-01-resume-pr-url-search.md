---
id: practice-2026-05-01-resume-pr-url-search
title: "/resume acepta URL de PR como búsqueda — encuentra la sesión que la creó"
source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
source_type: changelog
discovered: 2026-05-04
status: active
tags: [productivity, resume, low-priority]
tested_in: null
incorporated_in: ['3.5.0']
replaced_by: null
---

## Descripción
En v2.1.126, pegar una URL de PR de GitHub en el buscador de `/resume` encuentra automáticamente la sesión de Claude Code que creó ese PR. Antes había que recordar fecha o título.

## Evidencia
- Changelog v2.1.126 (2026-05-01).

## Impacto en dotforge
BAJO — productividad pura, no requiere cambios. Solo vale mencionarlo en `docs/usage-guide.md` o `docs/best-practices.md` como tip de flujo "PR review".

## Archivos potencialmente afectados
- `docs/usage-guide.md` (sección flujos PR)
- `docs/best-practices.md`

## Decisión
Pendiente — incluir como nota breve en próxima actualización de docs si hay tema relacionado, sin promover a práctica activa.
