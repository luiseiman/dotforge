---
id: practice-2026-05-01-plugin-seed-multi-dir
title: "CLAUDE_CODE_PLUGIN_SEED_DIR ahora soporta múltiples directorios"
source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
source_type: changelog
discovered: 2026-05-04
status: active
tags: [plugins, distribution, dotforge-distribution, medium-priority]
tested_in: null
incorporated_in: ['3.5.0']
replaced_by: null
---

## Descripción
`CLAUDE_CODE_PLUGIN_SEED_DIR` ahora acepta múltiples directorios separados por delimitador de plataforma (`:` en Unix, `;` en Windows). Antes era un único directorio.

## Evidencia
- Changelog v2.1.126 (2026-05-01).

## Impacto en dotforge
MEDIO — habilita un patrón de distribución por capas:
- `seed1` = template base (oficial dotforge)
- `seed2` = overlay corporativo (reglas específicas de Chaco Digital, ADRs internos)
- `seed3` = overlay personal (preferencias luiseiman)

Hoy `install.sh` y `bootstrap-project` no aprovechan esto. Se podría documentar el patrón "base + corporate + personal" como modo recomendado para usuarios que mantienen reglas privadas además del template público.

## Archivos potencialmente afectados
- `install.sh` (mencionar la variable)
- `docs/usage-guide.md` (sección distribución)
- `skills/bootstrap-project/SKILL.md` (detectar SEED_DIR múltiple y ofrecer overlay)

## Decisión
Pendiente — bajo retorno inmediato pero alto valor para usuarios enterprise. Documentar primero, automatizar después.
