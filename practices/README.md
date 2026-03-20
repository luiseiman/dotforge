> **[English](#practices-lifecycle)** | **[Español](#ciclo-de-vida-de-prácticas)**

# Practices Lifecycle

```
INBOX → EVALUATING → ACTIVE → (DEPRECATED)
```

## Directories

### inbox/
Discovered but unevaluated practices. They arrive here from:
- `/forge capture` (manual user insight)
- `/forge update` (web search with specific queries)
- `/forge watch` (deltas in official Anthropic docs)
- `/forge scout` (patterns from curated repos in `sources.yml`)
- Post-session hook (changes detected in .claude/ of projects)
- Audit gap capture (gaps detected by `/forge audit`)

### evaluating/
Practices under evaluation. Tested in 1 project before generalizing.
They have a `tested_in:` field with the project where they were tested.

### active/
Validated and active practices. Incorporated into template/, stacks/, or docs/.
They have an `incorporated_in:` field with the files they modified.

### deprecated/
Practices that were replaced or no longer apply.
They have a `replaced_by:` or `reason:` field.

## File Format

```yaml
---
id: practice-YYYY-MM-DD-slug
title: Short title
source: url or "own experience"
source_type: web | changelog | community | experience
discovered: YYYY-MM-DD
status: inbox | evaluating | active | deprecated
tags: [hooks, security, prompting, ...]
tested_in: null | project-name
incorporated_in: [] | [template/rules/_common.md, ...]
replaced_by: null | practice-id
---

## Description
What the practice states.

## Evidence
Why it works / source.

## Impact on claude-kit
Which files would need to be modified.

## Decision
Accept / Reject / Pending + reason.
```

---

# Ciclo de vida de prácticas

```
INBOX → EVALUATING → ACTIVE → (DEPRECATED)
```

## Directorios

### inbox/
Prácticas descubiertas pero no evaluadas. Llegan acá desde:
- `/forge capture` (insight manual del usuario)
- `/forge update` (búsqueda en web con queries específicos)
- `/forge watch` (deltas en docs oficiales Anthropic)
- `/forge scout` (patterns de repos curados en `sources.yml`)
- Hook post-sesión (cambios detectados en .claude/ de proyectos)
- Audit gap capture (gaps detectados por `/forge audit`)

### evaluating/
Prácticas en evaluación. Se prueban en 1 proyecto antes de generalizar.
Tienen campo `tested_in:` con el proyecto donde se probaron.

### active/
Prácticas validadas y activas. Se incorporan a template/, stacks/, o docs/.
Tienen campo `incorporated_in:` con los archivos que modificaron.

### deprecated/
Prácticas que fueron reemplazadas o ya no aplican.
Tienen campo `replaced_by:` o `reason:`.

## Formato de archivo

```yaml
---
id: practice-YYYY-MM-DD-slug
title: Título corto
source: url o "experiencia propia"
source_type: web | changelog | community | experience
discovered: YYYY-MM-DD
status: inbox | evaluating | active | deprecated
tags: [hooks, security, prompting, ...]
tested_in: null | nombre-proyecto
incorporated_in: [] | [template/rules/_common.md, ...]
replaced_by: null | practice-id
---

## Descripción
Qué dice la práctica.

## Evidencia
Por qué funciona / fuente.

## Impacto en claude-kit
Qué archivos habría que modificar.

## Decisión
Aceptar / Rechazar / Pendiente + razón.
```
