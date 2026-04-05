# Roadmap dotforge — Historical (v1.0.0 → v2.5.0)

> **This document is the historical development roadmap used during v1.x and v2.x development.**
> For the current roadmap and upcoming features, see [ROADMAP.md](../ROADMAP.md).
> For completed version history, see [changelog.md](changelog.md).
>
> **Este documento es el roadmap histórico de desarrollo usado durante v1.x y v2.x.**
> Para el roadmap actual y features próximas, ver [ROADMAP.md](../ROADMAP.md).
> Para el historial de versiones completadas, ver [changelog.md](changelog.md).

## Vision / Visión

dotforge is the only end-to-end configuration management system for Claude Code. While other tools offer one-shot bootstraps, skills collections, or CLAUDE.md generators, dotforge uniquely combines **additive stack layering**, **intelligent template sync**, **normalized audit scoring**, **a practices pipeline for continuous improvement**, and **cross-project registry tracking** — all in markdown + shell scripts. The roadmap deepens each of these differentiators.

dotforge es el único sistema de gestión de configuración end-to-end para Claude Code. Mientras otras herramientas ofrecen bootstraps one-shot, colecciones de skills o generadores de CLAUDE.md, dotforge combina de forma única **stack layering aditivo**, **sync inteligente de plantillas**, **audit scoring normalizado**, **un pipeline de prácticas para mejora continua** y **registry cross-proyecto con tracking** — todo en markdown + shell scripts. El roadmap profundiza cada uno de estos diferenciadores.

## v1.0.1 — Higiene interna
Corregir inconsistencias sin agregar features.

1. Agregar frontmatter `globs:` a `template/rules/_common.md`
2. Actualizar `audit.md` command a 8 stacks (faltan gcp-cloud-run, redis)
3. Correct inflated registry scores (recalculate with updated formula)
4. Resolver ambigüedad lint hooks en bootstrap: siempre copiar `lint-on-save.sh` genérico
5. Relajar constraint researcher de "max 5 file reads" a "max 15"
6. Eliminar `docs/x-references.md` (contenido efímero)

## v1.1.0 — Gestión global (~/.claude/)
dotforge pasa a gestionar la capa global.

1. Crear `global/CLAUDE.md.tmpl` con secciones `<!-- forge:custom -->`
2. Crear `global/settings.json.tmpl` con deny list base
3. Nuevo comando `/forge global sync`
4. Auto-instalar symlinks de skills
5. Eliminar duplicación global vs `_common.md`
6. Bootstrap/sync detectan qué ya está en global y no duplican

## v1.2.0 — Tooling defensivo ✅

1. ~~`/forge diff` — qué cambió desde último sync~~
2. ~~`/forge reset` — restaurar `.claude/` a plantilla~~
3. ~~Validación JSON en bootstrap y sync~~
4. ~~Hook testing framework (`tests/test-hooks.sh`)~~
5. ~~Manifest de archivos deployados (`.claude/.forge-manifest.json`)~~

## v1.3.0 — Stack composition

1. Stack `websocket` (ws patterns, reconnect, heartbeat)
2. Presets de composición: `fullstack-web`, `api-backend`, `ios-app`
3. Rules de interacción cross-stack por preset
4. Bootstrap acepta preset
5. Audit evalúa coherencia multi-stack (item 12)

## v1.4.0 — Consolidación commands/skills

1. Commands locales delegan a skills (audit, health, debug, review)
2. Nuevo command `/test` — stack-aware
3. Nuevo command `/deploy` — detecta target

## v1.5.0 — Practices madurez

### Intake externo (manual, sin auto-ingesta)
1. `/forge watch` — fetch docs Anthropic, compara contra template, reporta deltas
2. `/forge scout` — revisa repos curados, compara sus `.claude/` contra template
3. `practices/sources.yml` — lista curada de URLs/repos a monitorear

### Fuentes jerarquizadas
- Tier 1: Anthropic oficial → se adapta al formato, humano decide
- Tier 2: Experiencia propia → `/forge capture` (ya existe)
- Tier 3: Community validado → `/forge scout` con repos curados
- Tier 4: Blog posts/opiniones → ignorar, capture manual si vale

### Criterios de aceptación
- ¿Resuelve un problema que tuve? (evidencia en CLAUDE_ERRORS.md)
- ¿Testeable en proyecto real en <10 min?
- ¿Contradice algo existente? → cuál tiene mejor evidencia
- ¿Específica y accionable?

### Budget anti-entropía
- Máximo 15 prácticas activas
- Máximo 5 en inbox simultáneo
- Para agregar la 16ª, deprecar una
- Review trimestral: sin uso en 90 días → deprecated
- Toda práctica referencia ≥1 proyecto donde se aplica

### Métricas y migración
1. `practices/metrics.yml` con contadores
2. Review schedule en cada práctica activa
3. Migration guide automática al bumpar VERSION
4. `/forge migrate` — aplica migration notes

## v1.6.0 — Config Validation ✅

1. ~~Config self-validation (`tests/test-config.sh`)~~
2. ~~Session metrics JSON + hook counters~~
3. ~~Rule effectiveness detection (`/forge rule-check`)~~
4. ~~Practice effectiveness tracking (binary recurrence)~~
5. ~~Comparative benchmark (`/forge benchmark`)~~
6. ~~Retroactive analysis in `/forge insights`~~
7. ~~Documentation (`docs/config-validation.md`)~~

## v2.0.0 — Estabilización

1. Arquitectura interna documentada
2. Sync real de todos los proyectos registrados con v2.0.0
3. Scores auditados y reales
4. Changelog completo
5. Tag git v2.0.0

## Dependencias

```
v1.0.1 ──→ v1.1.0 ──→ v1.2.0 ──┐
                                 ├──→ v1.6.0 ──→ v2.0.0
v1.3.0 (paralelo) ──────────────┤
v1.4.0 (paralelo) ──────────────┤
v1.5.0 (paralelo) ──────────────┘
```

v1.3, v1.4, v1.5 son independientes entre sí, todos dependen de v1.2.
