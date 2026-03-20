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

Leer todos los archivos en `$CLAUDE_KIT_DIR/practices/inbox/`.

Para cada práctica:

### Criterios de aceptación
1. **¿Es actionable?** — Se puede traducir a un cambio concreto en claude-kit
2. **¿Es nueva?** — No duplica algo que ya está en `practices/active/`
3. **¿Es generalizable?** — Aplica a >1 proyecto (no es project-specific)
4. **¿Previene un error específico?** — Si sí, anotar `error_type` y descripción del error para tracking en metrics.yml

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
3. **If the practice warrants a new rule**: generate a `.md` file in `template/rules/` or `stacks/*/rules/` with proper `globs:` frontmatter. Only create a rule if the practice is a repeatable constraint (not a one-time fix). Use existing rules as format reference.
4. Mover práctica de `evaluating/` a `active/` con `incorporated_in:` actualizado
5. Set frontmatter fields: `effectiveness: monitoring` (or `not-applicable` if no error targeted), `error_type` matching CLAUDE_ERRORS.md types
6. Register in `$CLAUDE_KIT_DIR/practices/metrics.yml`:
   - `error_targeted`: description of the error this practice prevents (null if not error-targeted)
   - `error_type`: syntax | logic | integration | config | security | null
   - `activated`: today's date
   - `status`: monitoring (or not-applicable)
   - `recurrence_checks`: 0
   - `recurrence_target`: 5
7. Actualizar `docs/changelog.md`
8. Bump `VERSION` según tipo

---

## Fase 3: PROPAGAR — Sugerir actualización de proyectos

1. Leer `$CLAUDE_KIT_DIR/registry/projects.yml`
2. Para cada proyecto, mostrar qué cambió desde su última sincronización:

```
═══ PROPAGACIÓN SUGERIDA ═══

project-a (último sync: {{fecha o "nunca"}})
  → {{N}} rules actualizadas

project-b (último sync: {{fecha o "nunca"}})
  → {{N}} rules actualizadas

Para propagar: ejecutar /forge sync en cada proyecto.
```

NO propagar automáticamente. Solo informar.

---

## Fase 4: VERIFICAR — Recurrence check de prácticas activas

For each entry in `$CLAUDE_KIT_DIR/practices/metrics.yml` where `status: monitoring`:

1. Read `CLAUDE_ERRORS.md` from each project in registry where the practice is applied
2. Check if any error matching `error_type` + `error_targeted` description was logged AFTER the `activated` date
3. Increment `recurrence_checks` by 1, update `last_checked` to today
4. If error recurred: set `recurred: true`, `status: failed`
5. If `recurrence_checks >= recurrence_target` and `recurred: false`: set `status: validated`
6. Update `effectiveness` field in the practice's frontmatter file to match

Report:
```
═══ EFFECTIVENESS CHECK ═══
{{practice title}} — {{status}} ({{recurrence_checks}}/{{recurrence_target}} checks)
  {{if failed: "⚠ Error recurred — practice needs revision"}}
  {{if validated: "✅ No recurrence after {{N}} checks"}}
  {{if monitoring: "🔍 {{remaining}} checks remaining"}}
```

Skip practices with `status: not-applicable` or `status: validated`.

---

## Reporte final

```
═══ REPORTE DE ACTUALIZACIÓN ═══
Fecha: {{YYYY-MM-DD}}

Evaluadas: {{N}} ({{aceptadas}} aceptadas, {{rechazadas}} rechazadas, {{pospuestas}} pospuestas)
Incorporadas: {{N}} a claude-kit
Propagación sugerida: {{N}} proyectos

── EFFECTIVENESS ──
Monitoreando: {{N}} prácticas
Validadas: {{N}} (sin recurrencia tras {{target}} checks)
Fallidas: {{N}} (necesitan revisión)

VERSION: {{old}} → {{new}}
```
