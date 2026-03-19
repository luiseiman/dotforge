---
name: audit-project
description: Audita la configuración de Claude Code de un proyecto contra la plantilla claude-kit. Genera reporte con score y gaps.
---

# Auditar Proyecto

Ejecutá una auditoría completa de la configuración de Claude Code del proyecto actual.

## Paso 1: Detectar stack

Buscar indicadores de stack en el directorio actual:
- `pyproject.toml`, `requirements.txt`, `Pipfile` → **python-fastapi**
- `package.json` con react/vite/next → **react-vite-ts**
- `Package.swift`, `*.xcodeproj`, `*.xcworkspace` → **swift-swiftui**
- `supabase/`, `supabase.ts`, `@supabase/supabase-js` en package.json → **supabase**
- `*.db`, `*.sqlite`, `*.ipynb`, `*.csv`, `*.xlsx` prominentes → **data-analysis**
- `docker-compose*`, `Dockerfile*` → **docker-deploy**

Un proyecto puede tener múltiples stacks.

## Paso 2: Cargar checklist

Leer `~/Documents/GitHub/claude-kit/audit/checklist.md` para los criterios de evaluación.
Leer `~/Documents/GitHub/claude-kit/audit/scoring.md` para los pesos.

## Paso 3: Evaluar

Para cada item del checklist, verificar si existe y su calidad:

### Obligatorio (0-10 puntos)
1. **CLAUDE.md** — ¿Existe? ¿Tiene >20 líneas útiles? ¿Incluye stack, arquitectura, comandos?
2. **settings.json** — ¿Existe en `.claude/`? ¿Tiene permisos explícitos? ¿Tiene deny list?
3. **Rules** — ¿Hay al menos 1 rule contextual en `.claude/rules/`? ¿Tiene frontmatter globs?
4. **Hook block-destructive** — ¿Existe y es ejecutable? ¿Está configurado en settings.json?
5. **Comandos build/test** — ¿Están documentados en CLAUDE.md? ¿Funcionan?

### Recomendado (0-5 puntos bonus)
6. **CLAUDE_ERRORS.md** — ¿Existe para registro de errores?
7. **Rules con globs** — ¿Las rules tienen glob patterns específicos?
8. **Hook lint** — ¿Hay lint automático post-write?
9. **Comandos custom** — ¿Hay comandos en `.claude/commands/`?
10. **Memory** — ¿Hay archivos de memoria del proyecto?

## Paso 4: Calcular score

Usar los pesos de `scoring.md`. Score = obligatorio (0-10) + bonus (0-5), normalizado a 10.

## Paso 5: Generar reporte

Formato:
```
═══ AUDITORÍA claude-kit: {{proyecto}} ═══
Fecha: {{YYYY-MM-DD}}
Stack detectado: {{stacks}}
Score: {{X.X}}/10

── OBLIGATORIO ──
{{✅|❌}} CLAUDE.md — {{detalle}}
{{✅|❌}} .claude/settings.json — {{detalle}}
{{✅|❌}} .claude/rules/ — {{detalle}}
{{✅|❌}} Hook block-destructive — {{detalle}}
{{✅|❌}} Comandos build/test — {{detalle}}

── RECOMENDADO ──
{{✅|⚠️}} CLAUDE_ERRORS.md — {{detalle}}
{{✅|⚠️}} Rules con globs — {{detalle}}
{{✅|⚠️}} Hook lint — {{detalle}}
{{✅|⚠️}} Comandos custom — {{detalle}}
{{✅|⚠️}} Memory — {{detalle}}

── GAPS CRÍTICOS ──
1. {{qué falta}} → {{acción recomendada}}
2. ...

── SIGUIENTE PASO ──
Ejecutar `/forge sync` para aplicar la plantilla claude-kit y cerrar los gaps.
```

## Paso 6: Actualizar registry

Si el archivo `~/Documents/GitHub/claude-kit/registry/projects.yml` existe, actualizar el entry del proyecto con el score y fecha de auditoría.
