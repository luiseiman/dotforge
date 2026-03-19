---
name: update-practices
description: Pipeline completo de actualización de prácticas — busca en web, procesa inbox, evalúa, incorpora, y propaga cambios a claude-kit y proyectos.
---

# Actualizar Prácticas — Pipeline Completo

Pipeline de 5 fases que mantiene claude-kit actualizado.

---

## Fase 1: DESCUBRIR — Buscar nuevas prácticas

### 1a. Web search (últimos 3 meses)
Usar subagentes en paralelo para buscar:

**Agente 1 — Documentación oficial:**
- "Claude Code changelog" + año actual
- "Claude Code new features" + año actual
- "Anthropic Claude Code documentation updates"
- site:docs.anthropic.com Claude Code

**Agente 2 — Comunidad y patrones:**
- "Claude Code best practices" + año actual
- "CLAUDE.md examples github"
- "Claude Code hooks examples"
- "Claude Code skills patterns"

**Agente 3 — Perfiles X clave:**
- Revisar posts recientes de: @claudeai, @bcherny, @ErikSchluntz, @alexalbert__, @ClaudeCodeLog
- Buscar: "Claude Code" from:claudeai OR from:bcherny

Para cada hallazgo relevante, crear archivo en `practices/inbox/` con source_type: web|changelog|community.

### 1b. Procesar inbox existente
Leer todos los archivos en `~/Documents/GitHub/claude-kit/practices/inbox/`.
Incluye capturas manuales (`/forge capture`) y detecciones del hook post-sesión.

---

## Fase 2: EVALUAR — Filtrar y priorizar

Para cada práctica en inbox:

### Criterios de aceptación
1. **¿Es verificable?** — Tiene fuente confiable o evidencia real
2. **¿Es actionable?** — Se puede traducir a un cambio concreto en claude-kit
3. **¿Es nueva?** — No duplica algo que ya tenemos en active/
4. **¿Es generalizable?** — Aplica a >1 proyecto (no es project-specific)

### Clasificar
- **Aceptar** → mover a `practices/evaluating/`, proponer cambio concreto
- **Rechazar** → eliminar de inbox con nota de por qué
- **Posponer** → dejar en inbox con tag `needs-more-info`

### Prioridad de evaluación
1. Changelog oficial (breaking changes, deprecaciones)
2. Seguridad (vulnerabilidades, permisos)
3. Nuevas features que simplifican algo existente
4. Patrones de comunidad validados
5. Optimizaciones menores

---

## Fase 3: INCORPORAR — Aplicar cambios a claude-kit

Para cada práctica en `evaluating/`:

### Determinar impacto
| Tipo de cambio | Archivos afectados | Versión bump |
|---------------|-------------------|-------------|
| Regla nueva | template/rules/, stacks/*/rules/ | minor |
| Hook nuevo/modificado | template/hooks/, stacks/*/hooks/ | minor |
| Práctica documentada | docs/*.md | patch |
| Template modificado | template/*.tmpl | minor |
| Feature deprecada | + deprecated/, - active/ | minor |
| Security fix | cualquiera | patch |

### Aplicar
1. Modificar los archivos de claude-kit correspondientes
2. Mover práctica de `evaluating/` a `active/` con campo `incorporated_in:` actualizado
3. Actualizar `docs/changelog.md` con el cambio
4. Bump `VERSION` según tipo

### Mostrar diff al usuario
```
═══ CAMBIOS PROPUESTOS ═══

📝 template/rules/_common.md
   + Agregar regla: "No usar deprecated EventEmitter pattern"
   Fuente: Claude Code changelog v4.2

📝 docs/best-practices.md
   ~ Actualizar sección hooks con nuevo evento SubagentStop
   Fuente: @bcherny tweet 2026-03-15

📝 stacks/python-fastapi/rules/backend.md
   + Agregar: "Usar Pydantic v2 model_config, no class Config"
   Fuente: practices/inbox/2026-03-19-pydantic-v2.md

¿Aplicar? (sí / no / seleccionar)
```

Esperar confirmación antes de escribir.

---

## Fase 4: PROPAGAR — Actualizar proyectos

Después de incorporar cambios a claude-kit:

1. Leer `~/Documents/GitHub/claude-kit/registry/projects.yml`
2. Para cada proyecto registrado, calcular qué cambió desde su última sincronización
3. Mostrar resumen:

```
═══ PROPAGACIÓN A PROYECTOS ═══

SOMA (score: —, último sync: nunca)
  → 2 rules actualizadas, 1 hook nuevo

gestion-de-mora (score: —, último sync: nunca)
  → Necesita bootstrap completo primero

derup (score: —, último sync: nunca)
  → 1 rule actualizada

¿Propagar ahora? Esto ejecutará /forge sync en cada proyecto.
(sí / no / seleccionar proyectos)
```

NO propagar automáticamente. Siempre pedir confirmación y ejecutar `/forge sync` proyecto por proyecto.

---

## Fase 5: DEPRECAR — Limpiar prácticas obsoletas

Revisar `practices/active/`:
1. ¿Alguna práctica fue reemplazada por una nueva?
2. ¿Alguna práctica ya no aplica (feature removida, API changed)?
3. Si sí → mover a `practices/deprecated/` con `replaced_by:` o `reason:`
4. Revertir cambios en los archivos que la práctica había modificado

---

## Reporte final

```
═══ REPORTE DE ACTUALIZACIÓN ═══
Fecha: {{YYYY-MM-DD}}

Descubiertas: {{N}} nuevas prácticas
Evaluadas: {{N}} ({{aceptadas}} aceptadas, {{rechazadas}} rechazadas, {{pospuestas}} pospuestas)
Incorporadas: {{N}} a claude-kit
Propagadas: {{N}} proyectos actualizados
Deprecadas: {{N}} prácticas retiradas

VERSION: {{old}} → {{new}}

Próxima actualización sugerida: {{fecha + 7 días}}
```

Sugerir `git commit` con mensaje descriptivo.
