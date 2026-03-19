# Ciclo de vida de prácticas

```
INBOX → EVALUATING → ACTIVE → (DEPRECATED)
```

## Directorios

### inbox/
Prácticas descubiertas pero no evaluadas. Llegan acá desde:
- `/forge update` (búsqueda automática en web)
- `/forge capture` (insight manual del usuario)
- Hook post-sesión (cambios detectados en .claude/ de proyectos)

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
