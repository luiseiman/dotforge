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
- `app.yaml`, `cloudbuild.yaml`, `gcloud` en scripts → **gcp-cloud-run**
- `redis` en requirements.txt/pyproject.toml → **redis**

Un proyecto puede tener múltiples stacks.

## Paso 2: Cargar checklist

Leer `~/Documents/GitHub/claude-kit/audit/checklist.md` para los criterios de evaluación.
Leer `~/Documents/GitHub/claude-kit/audit/scoring.md` para los pesos y caps.

## Paso 3: Evaluar

Para cada item del checklist, verificar existencia **y calidad**:

### Obligatorio (0-10 puntos)
1. **CLAUDE.md** — ¿Existe? Verificar que tiene secciones clave:
   - Stack/tecnologías mencionadas explícitamente
   - Al menos 1 comando build/test exacto
   - Estructura o arquitectura del proyecto
   - NO contar solo líneas — un archivo de 50 líneas de boilerplate es score 1
2. **settings.json** — ¿Existe en `.claude/`? ¿Tiene permisos explícitos? ¿Tiene deny list?
3. **Rules** — ¿Hay al menos 1 rule en `.claude/rules/`? ¿Tiene frontmatter con globs?
4. **Hook block-destructive** — Verificar:
   - ¿Existe el archivo `.claude/hooks/block-destructive.sh`?
   - ¿Es ejecutable? (`test -x` o verificar permisos)
   - ¿Está referenciado en `.claude/settings.json` bajo hooks?
5. **Comandos build/test** — ¿Están en CLAUDE.md? ¿Corresponden al stack detectado?

### Recomendado (0-6 puntos bonus)
6. **CLAUDE_ERRORS.md** — ¿Existe con formato de tabla/estructura?
7. **Hook lint** — ¿Existe? ¿Es ejecutable? (verificar `chmod +x`)
8. **Comandos custom** — ¿Hay archivos en `.claude/commands/`?
9. **Memory** — ¿Hay archivos de memoria del proyecto?
10. **Agentes** — ¿Hay `.claude/agents/` + regla `agents.md` en rules?
11. **.gitignore** — ¿Protege .env, *.key, *.pem, credentials?

## Paso 4: Calcular score

Usar los pesos de `scoring.md`:
1. `score_obligatorio = sum(items 1-5)` — máximo 10
2. `score_recomendado = sum(items 6-11)` — máximo 6
3. `score_total = score_obligatorio + (score_recomendado * 0.5)`
4. `score_normalizado = min(score_total / 10 * 10, 10)`

**Cap de seguridad:** Si item 2 (settings.json) o item 4 (block-destructive) es 0, score máximo = 6.0.

## Paso 5: Generar reporte

Formato:
```
═══ AUDITORÍA claude-kit: {{proyecto}} ═══
Fecha: {{YYYY-MM-DD}}
Stack detectado: {{stacks}}
claude-kit version: {{version del último bootstrap/sync si detectable}}
Score: {{X.X}}/10 {{nivel}}

── OBLIGATORIO ──
{{✅|⚠️|❌}} CLAUDE.md ({{0-2}}) — {{detalle: qué secciones tiene/faltan}}
{{✅|⚠️|❌}} settings.json ({{0-2}}) — {{detalle: deny list sí/no, permisos}}
{{✅|⚠️|❌}} Rules ({{0-2}}) — {{detalle: N rules, globs sí/no}}
{{✅|⚠️|❌}} Hook block-destructive ({{0-2}}) — {{detalle: ejecutable sí/no, wired sí/no}}
{{✅|⚠️|❌}} Comandos build/test ({{0-2}}) — {{detalle: cuáles y si corresponden al stack}}

── RECOMENDADO ──
{{✅|⚠️}} CLAUDE_ERRORS.md — {{detalle}}
{{✅|⚠️}} Hook lint — {{detalle: ejecutable sí/no}}
{{✅|⚠️}} Comandos custom — {{detalle: N comandos}}
{{✅|⚠️}} Memory — {{detalle}}
{{✅|⚠️}} Agentes — {{detalle}}
{{✅|⚠️}} .gitignore — {{detalle}}

── GAPS CRÍTICOS ──
1. {{qué falta}} → {{acción recomendada}}
2. ...

── SIGUIENTE PASO ──
Ejecutar `/forge sync` para aplicar la plantilla claude-kit y cerrar los gaps.
```

## Paso 6: Actualizar registry

Si `~/Documents/GitHub/claude-kit/registry/projects.yml` existe, actualizar el entry del proyecto:
- `score:` con el score calculado
- `last_audit:` con la fecha actual
- `claude_kit_version:` con la versión de VERSION si el proyecto fue bootstrapped
- `last_sync:` preservar el valor existente (no modificar aquí)
- `notes:` resumen breve de la auditoría
