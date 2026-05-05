---
id: practice-2026-05-01-plugin-data-variable
title: "${CLAUDE_PLUGIN_DATA} variable for plugin persistent state across updates"
source: https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
source_type: changelog
discovered: 2026-05-04
status: active
tags: [plugins, persistence, dotforge-distribution, high-priority]
tested_in: null
incorporated_in: ['3.5.0']
replaced_by: null
---

## Descripción
Claude Code v2.1.126 (2026-05-01) introduce la variable `${CLAUDE_PLUGIN_DATA}` que apunta a un directorio de estado persistente para plugins. El estado guardado ahí sobrevive a actualizaciones del plugin (instalaciones nuevas no lo borran).

Casos de uso: caches de práctica, métricas acumuladas, último ID procesado en un pipeline, manifiestos.

## Evidencia
- Changelog oficial v2.1.126 (raw GitHub).
- Documentado en https://code.claude.com/docs/en/plugins (sección persistent state).

## Impacto en dotforge
ALTO — dotforge se distribuye como plugin (`.claude-plugin/`). Casos concretos donde `${CLAUDE_PLUGIN_DATA}` reemplaza patches actuales:

1. `practices/metrics.yml` (counters acumulados) → mover a `${CLAUDE_PLUGIN_DATA}/metrics.yml` para que `/forge sync` no resetee historial.
2. `.forge/manifest.json` (registro de proyectos gestionados) → candidato natural a estado persistente.
3. `practices/inbox/` con capturas de hooks (post-session) — actualmente se escriben en el repo del plugin, lo que ensucia git status. Mover a `${CLAUDE_PLUGIN_DATA}/inbox/` y exponer un comando `/forge sync` que mueva al repo solo lo que el usuario aprueba.

## Archivos potencialmente afectados
- `hooks/*.sh` que escriben en `practices/inbox/`
- `skills/forge-status/SKILL.md` (lectura de manifest)
- `skills/forge-capture/SKILL.md`
- `docs/best-practices.md` (documentar el patrón)

## Decisión
Pendiente — evaluar en próximo /forge update. Considerar piloto con `inbox/` antes de migrar `metrics.yml` y `manifest.json`.
