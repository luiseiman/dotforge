---
name: update-practices
description: Procesa el inbox de prácticas, evalúa, incorpora a claude-kit, y sugiere propagación a proyectos.
---

# Actualizar Prácticas

Pipeline de 3 fases para mantener claude-kit actualizado con prácticas descubiertas.

**Fuentes de prácticas:**
- Hook post-sesión (`detect-claude-changes.sh`) → automático
- Captura manual (`/forge capture`) → usuario
- Para búsqueda web manual: investigar y luego usar `/forge capture` con los hallazgos

---

## Fase 1: EVALUAR — Procesar inbox

Leer todos los archivos en `~/Documents/GitHub/claude-kit/practices/inbox/`.

Para cada práctica:

### Criterios de aceptación
1. **¿Es actionable?** — Se puede traducir a un cambio concreto en claude-kit
2. **¿Es nueva?** — No duplica algo que ya está en `practices/active/`
3. **¿Es generalizable?** — Aplica a >1 proyecto (no es project-specific)

### Clasificar
- **Aceptar** → mover a `practices/evaluating/`, anotar cambio concreto propuesto
- **Rechazar** → eliminar de inbox con nota de por qué en la decisión
- **Posponer** → dejar en inbox con tag `needs-more-info`

### Prioridad
1. Seguridad (vulnerabilidades, permisos)
2. Breaking changes (APIs que cambiaron)
3. Features nuevas que simplifican algo existente
4. Patrones validados en >1 proyecto
5. Optimizaciones menores

Mostrar resumen:
```
═══ EVALUACIÓN DE INBOX ═══
{{N}} prácticas en inbox

✅ ACEPTAR: {{título}} → {{cambio propuesto}}
❌ RECHAZAR: {{título}} → {{razón}}
⏸️ POSPONER: {{título}} → {{qué falta}}

¿Proceder con las aceptadas? (sí/no/seleccionar)
```

---

## Fase 2: INCORPORAR — Aplicar cambios a claude-kit

Para cada práctica aceptada en `evaluating/`:

### Determinar impacto
| Tipo de cambio | Archivos afectados | Versión bump |
|---------------|-------------------|-------------|
| Regla nueva/modificada | template/rules/, stacks/*/rules/ | minor |
| Hook nuevo/modificado | template/hooks/, stacks/*/hooks/ | minor |
| Documentación | docs/*.md | patch |
| Template modificado | template/*.tmpl | minor |
| Security fix | cualquiera | patch |

### Aplicar
1. Mostrar diff propuesto al usuario y pedir confirmación
2. Modificar los archivos de claude-kit correspondientes
3. Mover práctica de `evaluating/` a `active/` con `incorporated_in:` actualizado
4. Actualizar `docs/changelog.md`
5. Bump `VERSION` según tipo

---

## Fase 3: PROPAGAR — Sugerir actualización de proyectos

1. Leer `~/Documents/GitHub/claude-kit/registry/projects.yml`
2. Para cada proyecto, mostrar qué cambió desde su última sincronización:

```
═══ PROPAGACIÓN SUGERIDA ═══

SOMA (último sync: {{fecha o "nunca"}})
  → {{N}} rules actualizadas

derup (último sync: {{fecha o "nunca"}})
  → {{N}} rules actualizadas

Para propagar: ejecutar /forge sync en cada proyecto.
```

NO propagar automáticamente. Solo informar.

---

## Reporte final

```
═══ REPORTE DE ACTUALIZACIÓN ═══
Fecha: {{YYYY-MM-DD}}

Evaluadas: {{N}} ({{aceptadas}} aceptadas, {{rechazadas}} rechazadas, {{pospuestas}} pospuestas)
Incorporadas: {{N}} a claude-kit
Propagación sugerida: {{N}} proyectos

VERSION: {{old}} → {{new}}
```
