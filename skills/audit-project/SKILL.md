---
name: audit-project
description: Audita la configuración de Claude Code de un proyecto contra la plantilla claude-kit. Genera reporte con score y gaps.
---

# Auditar Proyecto

Ejecutá una auditoría completa de la configuración de Claude Code del proyecto actual.

## Paso 1: Detectar stack

Use detection rules from `$CLAUDE_KIT_DIR/stacks/detect.md`.

## Paso 1b: Detect project tier

Auto-detect project tier based on signals:
- **simple** (<5K LOC, 1 stack, no CI config): recommended items are relaxed (items 8-10 don't penalize)
- **standard** (5K-50K LOC, 1-2 stacks): default behavior
- **complex** (>50K LOC, 3+ stacks, monorepo indicators like `packages/` or `apps/`): recommended items 8-10 become semi-obligatory (each worth 0-2 instead of 0-1)

Detection signals:
1. LOC: count non-empty lines in source files (`find . -name '*.py' -o -name '*.ts' -o -name '*.js' -o -name '*.go' -o -name '*.java' -o -name '*.swift' | xargs wc -l`)
2. Stack count: number of stacks detected in step 1
3. CI: presence of `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/`
4. Monorepo: presence of `packages/`, `apps/`, `lerna.json`, `pnpm-workspace.yaml`, `turbo.json`

Save tier in registry entry.

## Paso 1c: Config coherence check

Before scoring, validate internal coherence. Run `$CLAUDE_KIT_DIR/tests/test-config.sh <project-dir>` or perform equivalent checks inline:

1. Hooks referenced in settings.json exist and are executable
2. Rules have valid `globs:` frontmatter
3. Rule globs match at least 1 real file in the project
4. settings.json is valid JSON with deny list covering .env, *.key, *.pem
5. CLAUDE.md has minimum required sections (stack, build/test, architecture)
6. No contradictory allow+deny patterns in settings.json
7. No prompt injection patterns in rules or CLAUDE.md

If coherence check finds critical failures (missing hooks, invalid JSON), report them in a `── COHERENCE ──` section BEFORE the score. These are configuration bugs, not gaps.

## Paso 2: Cargar checklist

Leer `$CLAUDE_KIT_DIR/audit/checklist.md` para los criterios de evaluación.
Leer `$CLAUDE_KIT_DIR/audit/scoring.md` para los pesos y caps.

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

### Recomendado (0-7 puntos bonus)
6. **CLAUDE_ERRORS.md** — ¿Existe con formato de tabla con columna Type?
7. **Hook lint** — ¿Existe? ¿Es ejecutable? (verificar `chmod +x`)
8. **Comandos custom** — ¿Hay archivos en `.claude/commands/`?
9. **Memory** — ¿Hay archivos de memoria del proyecto?
10. **Agentes** — ¿Hay `.claude/agents/` + regla `agents.md` en rules?
11. **.gitignore** — ¿Protege .env, *.key, *.pem, credentials?
12. **Prompt injection scan** — ¿Rules/CLAUDE.md libres de patrones sospechosos?

**Tier adjustments:**
- `simple`: items 8-10 score 0 don't penalize (treated as N/A)
- `complex`: items 8-10 become semi-obligatory (each 0-2 instead of 0-1)

## Paso 4: Calcular score

Usar los pesos de `$CLAUDE_KIT_DIR/audit/scoring.md`:
1. `score_obligatorio = sum(items 1-5)` — máximo 10
2. `score_recomendado = sum(items 6-12)` — máximo 7
3. `score_total = score_obligatorio * 0.7 + score_recomendado * (3.0 / 7)` — max 7.0 + 3.0 = 10.0
4. Apply tier adjustments before calculating (see Paso 1b)
4. `score_normalizado = min(score_total, 10)`

**Cap de seguridad:** Si item 2 (settings.json) o item 4 (block-destructive) es 0, score máximo = 6.0.

## Paso 5: Generar reporte

Formato:
```
═══ AUDITORÍA claude-kit: {{proyecto}} ═══
Fecha: {{YYYY-MM-DD}}
Stack detectado: {{stacks}}
Tier: {{simple|standard|complex}}
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
{{✅|⚠️}} Prompt injection scan — {{detalle}}

── GAPS CRÍTICOS ──
1. {{qué falta}} → {{acción recomendada}}
2. ...

── SIGUIENTE PASO ──
Ejecutar `/forge sync` para aplicar la plantilla claude-kit y cerrar los gaps.
```

## Paso 6: Cross-project error promotion

If the project has `CLAUDE_ERRORS.md`, scan it for recurring patterns:
1. Read `CLAUDE_ERRORS.md` and group errors by Area column
2. If any Area has 3+ entries with similar root causes, it's a candidate for promotion
3. Check `$CLAUDE_KIT_DIR/practices/inbox/` and `active/` for existing practices covering that pattern
4. If no existing practice covers it, create a new practice in `practices/inbox/` using the capture format:
   - `source_type: cross-project`
   - `tags: [error-promotion, <area>]`
   - Description: the recurring pattern and derived rule
5. Report promotions in the audit output under `── ERROR PATTERNS ──`

This closes the Memoria → Aprendizaje synergy: recurring project errors feed the practices pipeline.

## Paso 7: Audit gaps as practices

For each obligatory item scored 0 or 1, and each recommended item scored 0:
1. Check if a practice already exists in `practices/inbox/` or `active/` for that gap
2. If not, create a practice in `practices/inbox/`:
   - `source_type: audit-gap`
   - `tags: [audit-gap, <item-name>]`
   - Description: what's missing and recommended fix
3. Only create practices for gaps that reflect a template/stack issue (not project-specific misconfigurations)
4. Report in audit output under `── GAPS CAPTURADOS ──`

This closes the Auditoría → Aprendizaje synergy: detected gaps feed back into the practices pipeline.

## Paso 8: Actualizar registry

Si `$CLAUDE_KIT_DIR/registry/projects.yml` existe, actualizar el entry del proyecto:
- `score:` con el score calculado
- `last_audit:` con la fecha actual
- `claude_kit_version:` con la versión de VERSION si el proyecto fue bootstrapped
- `last_sync:` preservar el valor existente (no modificar aquí)
- `notes:` resumen breve de la auditoría
- `history:` append a new entry `{date: YYYY-MM-DD, score: X.X, version: <claude_kit_version>}`. Never overwrite previous entries — this enables score trending over time.
