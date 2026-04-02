# Plan de Mejoras claude-kit — Refinado Post-Audit

**Fecha**: 2026-04-02
**Base**: Análisis cruzado de 3 repos de reverse engineering + audit profundo de claude-kit
**Versión actual**: v2.7.1

---

## Principio rector

Cada mejora explota conocimiento verificado del código fuente de Claude Code para que claude-kit produzca configuraciones que trabajen **con** los mecanismos internos en vez de contra ellos. Priorización por: bugs confirmados > gaps de seguridad > eficiencia de tokens > features nuevos.

---

## P0 — Bugs y gaps de seguridad (fix inmediato)

### 1. BUG: `session-report.sh` produce JSON inválido

**Problema**: `$DOMAIN_CHANGES` se usa en la línea 124 (dentro del heredoc JSON) pero se define en la línea 129 (después del heredoc). Resultado: campo vacío → JSON inválido → métricas corruptas.

**Fix**: Mover el bloque de cálculo de `DOMAIN_CHANGES` (líneas 129-131) antes del heredoc JSON.

**Archivo**: `hooks/session-report.sh`

---

### 2. BUG: `block-destructive.sh` regex incorrectos

**Problema**: Pattern `'rm -rf \*'` en ERE mode (`grep -qiE`) interpreta `\*` como "cero o más del caracter anterior (espacio)", no como literal `*`. El pattern matcha `rm -rf` sin argumentos pero NO matcha `rm -rf *` que es lo peligroso.

**Fix**: Cambiar a `'rm -rf .*'` o usar `grep -qiF` (fixed strings) para los patterns que son literales.

**Archivo**: `hooks/block-destructive.sh`

---

### 3. SECURITY: Missing deny patterns en template

**Problema**: `template/settings.json.tmpl` no incluye `DROP TABLE` ni `DROP DATABASE` en deny list, a pesar de estar documentados como mandatory en `permission-model.md`.

**Fix**: Agregar `"Bash(DROP TABLE*)"` y `"Bash(DROP DATABASE*)"` a la deny list. También agregar `"Bash(git checkout -- *)"` y `"Bash(git checkout .)"` (operaciones destructivas no cubiertas).

**Archivo**: `template/settings.json.tmpl`

---

### 4. BUG: Agent frontmatter usa `tools:` (campo inválido)

**Problema**: Los 7 agentes usan `tools:` en frontmatter. El campo correcto es `allowed-tools:`. Como resultado, la restricción de herramientas se **ignora silenciosamente** — todos los agentes tienen acceso completo a todas las tools.

**Impacto**: El `researcher` (diseñado como read-only) tiene acceso a Write, Edit, Bash destructivo. El `code-reviewer` puede modificar código.

**Fix**: Renombrar `tools:` → `allowed-tools:` en los 7 archivos. Agregar `Write` explícitamente a los agentes que escriben agent-memory (architect, implementer, code-reviewer, security-auditor, session-reviewer).

**Archivos**: `agents/*.md` (7 archivos)

---

### 5. BUG: Agent frontmatter usa `memory: project` (campo inválido)

**Problema**: 5 agentes tienen `memory: project` en frontmatter. No es un campo reconocido — se ignora silenciosamente. La memoria funciona solo porque el prompt lo instruye textualmente.

**Fix**: Eliminar `memory: project` del frontmatter. La instrucción de memoria en el prompt es suficiente y es la que realmente funciona. Elimina confusión sin perder funcionalidad.

**Archivos**: `agents/architect.md`, `agents/implementer.md`, `agents/code-reviewer.md`, `agents/security-auditor.md`, `agents/session-reviewer.md`

---

### 6. SECURITY: `redis/rules/redis.md` glob `**/*stream*` demasiado amplio

**Problema**: Matchea `livestream.ts`, `filestream.py`, `audiostream.swift`, archivos de Java Streams — carga reglas de Redis en archivos no relacionados.

**Fix**: Cambiar a `globs: "**/*redis*"` solamente. Si se necesita stream coverage, usar `paths:` lazy con `alwaysApply: false`.

**Archivo**: `stacks/redis/rules/redis.md`

---

### 7. `_common.md` excede 50 líneas (67 líneas)

**Problema**: Viola la constraint de max 50 líneas por archivo de reglas. Las 17 líneas extra consumen tokens en CADA API call (sección dinámica, no cacheada).

**Fix**: Extraer las secciones "Practice Capture" (14 líneas) y "Context Continuity" (6 líneas) a archivos separados con frontmatter propio.

**Archivos**: `template/rules/_common.md` → split en `template/rules/practice-capture.md` + `template/rules/context-continuity.md`

---

### 8. `Bash(cat *)` en allow list del template

**Problema**: Incentiva uso de `cat` via Bash cuando Claude Code tiene el tool Read dedicado que es preferido, sandboxed, y tiene mejor UX.

**Fix**: Eliminar `"Bash(cat *)"` de `template/settings.json.tmpl`.

**Archivo**: `template/settings.json.tmpl`

---

## P1 — Conflictos con system prompt y eficiencia (alto impacto)

### 9. System prompt override patterns

**Problema**: El system prompt hardcodea:
- `"DO NOT ADD ANY COMMENTS"` — ningún stack lo contrarresta
- `"fewer than 4 lines"` — skills que producen reportes (audit, insights, rule-check) se truncan
- `"minimize output tokens"` — análisis detallados se abrevian

**Fix multi-archivo**:
- Stacks con docstrings: agregar override en python-fastapi (`ALWAYS add docstrings to public functions`), java-spring (`ALWAYS add Javadoc to public methods`), go-api (`ALWAYS add doc comments to exported functions`)
- `global/commands/forge.md`: agregar sección "Output rules" que override brevedad para skills que producen reportes
- Skills verbose (audit-project, session-insights, rule-effectiveness): agregar `OVERRIDE: produce complete structured output` en preamble

**Archivos**: `stacks/python-fastapi/rules/backend.md`, `stacks/java-spring/rules/backend.md`, `stacks/go-api/rules/backend.md`, `global/commands/forge.md`, skills afectados

---

### 10. Auto-mode permission stripping

**Problema**: 9 de 15 stacks tienen allow patterns que auto-mode elimina silenciosamente:
- `Bash(python3 *)` — python-fastapi, data-analysis
- `Bash(node *)`, `Bash(npm *)`, `Bash(npx *)` — node-express, react-vite-ts, aws-deploy
- `Bash(aws *)` — aws-deploy
- `Bash(gcloud *)` — gcp-cloud-run

Los usuarios activan auto-mode y sus permisos dejan de funcionar sin explicación.

**Fix**: 
- Reemplazar patterns de intérpretes con paths de herramientas específicas: `Bash(pytest *)`, `Bash(uvicorn *)`, `Bash(vitest *)`, `Bash(eslint *)` (no se eliminan en auto-mode)
- Documentar la lista completa de patterns stripped en `docs/security-checklist.md`
- Agregar comentario-guía en `template/settings.json.tmpl`

**Archivos**: `stacks/*/plugin.json` (9 stacks), `docs/security-checklist.md`, `template/settings.json.tmpl`

---

### 11. `node-express` glob overlap con `react-vite-ts`

**Problema**: `globs: "**/*.{js,ts,mjs,cjs}"` carga reglas de Express para TODOS los archivos JS/TS, incluyendo componentes React. Proyectos fullstack cargan ambos stacks simultáneamente para los mismos archivos.

**Fix**: Cambiar a `paths:` lazy con `alwaysApply: false` o narrowar a: `globs: "src/routes/**,src/services/**,src/middleware/**,src/controllers/**,**/*.{mjs,cjs}"`.

**Archivo**: `stacks/node-express/rules/backend.md`

---

### 12. `data-analysis` glob `**/*.py` overlap con `python-fastapi`

**Problema**: Proyectos con ambos stacks cargan reglas de data-analysis para todos los archivos Python.

**Fix**: Remover `.py` del glob de data-analysis: `globs: "**/*.{sql,ipynb,csv,xlsx}"`.

**Archivo**: `stacks/data-analysis/rules/data.md`

---

### 13. Deferred tools sin ToolSearch en skills

**Problema**: `watch-upstream` y `scout-repos` usan WebFetch/WebSearch pero estos son deferred tools. Si no están cargados en el prompt, el skill falla silenciosamente.

**Fix**: Agregar Step 0 "Discover tools" con ToolSearch en ambos skills.

**Archivos**: `skills/watch-upstream/SKILL.md`, `skills/scout-repos/SKILL.md`

---

### 14. Skills exceden budget de restauración post-compactación

**Problema**: Después de compactación, el sistema restaura máximo ~5 skills con 5K tokens cada uno. Skills que exceden este budget no se restauran completamente:
- `bootstrap-project/SKILL.md`: 220 líneas (~8K tokens)
- `domain-extract/SKILL.md`: 180 líneas (~6K tokens)
- `audit-project/SKILL.md`: 170 líneas (~6K tokens)

**Fix**: Condensar o modularizar. Los skills más largos deberían tener un core ≤5K tokens con pasos opcionales en archivos separados referenciados via `@include`.

**Archivos**: Skills con >150 líneas

---

### 15. Agent frontmatter enriquecido (`effort`, `allowed-tools`)

**Fix combinado para los 7 agentes**:

| Agent | `allowed-tools` | `effort` | `model` | Cambios adicionales |
|-------|-----------------|----------|---------|---------------------|
| researcher | Read, Grep, Glob, LS, WebFetch, WebSearch | (default) | haiku | Quitar Bash; usar Grep tool en vez de `grep -rn` |
| architect | Read, Grep, Glob, Bash, LS, Write | high | opus | Agregar Write para agent-memory |
| implementer | Read, Grep, Glob, Bash, Write, Edit, LS | (default) | sonnet | Agregar instrucción hasReadFile |
| code-reviewer | Read, Grep, Glob, Bash, Write | (default) | sonnet | Agregar Write para agent-memory |
| security-auditor | Read, Grep, Glob, Bash, LS, Write | max | opus | Usar Grep tool en vez de bash grep |
| test-runner | Read, Grep, Glob, Bash, Write, Edit | (default) | haiku | Evaluar subir a sonnet (escribe tests) |
| session-reviewer | Read, Grep, Glob, Bash, Write | (default) | sonnet | Agregar Write para practices/inbox/ |

**Instrucciones comunes a agregar en TODOS los agentes**:
- "Keep total output under 5K tokens — summarize, don't dump raw content"
- "If the caller needs follow-up, they will use SendMessage — do not start a new context"

**Archivos**: `agents/*.md` (7 archivos)

---

### 16. SessionEnd hook timeout y session-report.sh

**Problema dual**:
- Default timeout de SessionEnd es 1.5s, pero el template ya configura 10s — OK
- Sin embargo, `session-report.sh` tiene el bug del JSON inválido (P0.1) y es innecesariamente pesado

**Fix**: Además del bugfix (P0.1), considerar hacer el hook async (`"async": true` en settings.json.tmpl) para que no dependa del timeout.

**Archivo**: `template/settings.json.tmpl`, `hooks/session-report.sh`

---

### 17. Hookify missing matcher y async documentation

**Problemas**:
- `stacks/hookify/plugin.json` tiene hooks sin `matcher` nesting — pueden matchear ALL tools o fallar silenciosamente
- No documenta async hooks (`async: true`, `asyncRewake`, streaming `{"async":true}`)
- Stack lint scripts (`lint-ts.sh`, `lint-swift.sh`) son dead code — no están wired en ningún settings.json

**Fix**:
- Corregir structure de hooks en `plugin.json`
- Agregar sección de async hooks en `stacks/hookify/rules/hookify.md`
- Eliminar o wirear los lint scripts de stacks

**Archivos**: `stacks/hookify/plugin.json`, `stacks/hookify/rules/hookify.md`, `stacks/*/hooks/*.sh` (evaluar eliminación)

---

### 18. `detect.md` incompleto y detección imprecisa

**Problemas**:
- Faltan stacks hookify y trading en la detección
- `pyproject.toml` → `python-fastapi` es demasiado amplio (Django, Flask, CLI tools también usan pyproject.toml)
- No hay resolución de prioridad cuando Dockerfile está presente (docker-deploy vs gcp-cloud-run)

**Fix**:
- Agregar detección de hookify (`.claude/hookify.*.md`) y trading (declaración manual)
- pyproject.toml: verificar que `fastapi` esté en dependencies antes de asignar el stack
- Agregar sección de prioridad/conflicto

**Archivo**: `stacks/detect.md`

---

## P2 — Features nuevos y optimizaciones

### 19. Redundancia `python-fastapi/rules/backend.md` Redis section

**Problema**: 4 líneas de Redis duplicadas con `redis/rules/redis.md`. Proyectos con ambos stacks ven reglas duplicadas.

**Fix**: Eliminar sección Redis de python-fastapi/backend.md. Documentar en detect.md que proyectos con redis en deps deben instalar el redis stack.

**Archivo**: `stacks/python-fastapi/rules/backend.md`, `stacks/detect.md`

---

### 20. Hook events no usados con valor inmediato

5 eventos de hooks sin usar que agregan observabilidad:

| Evento | Uso propuesto |
|--------|---------------|
| `PostToolUseFailure` | Auto-append a CLAUDE_ERRORS.md — tracking automático de errores |
| `FileChanged` | Detectar cambios externos en `.claude/` — sugerir re-sync |
| `TaskCreated`/`TaskCompleted` | Métricas de delegación a subagents en session-report |
| `PermissionDenied` | Audit trail — identificar deny rules demasiado agresivos |

**Archivos**: `hooks/session-report.sh`, nuevo `hooks/track-errors.sh`

---

### 21. `go-api` permissions redundantes

**Problema**: `Bash(go test *)`, `Bash(go build *)`, `Bash(go run *)`, `Bash(go vet *)` son redundantes cuando `Bash(go *)` ya está presente.

**Fix**: Eliminar los 4 patterns específicos; mantener solo `Bash(go *)`.

**Archivo**: `stacks/go-api/plugin.json`

---

### 22. Stack `prompt-engineering`

Stack para proyectos que configuran Claude Code (meta-configuración):
- `rules/prompt-eng.md`: system prompt override patterns, frontmatter reference, compaction awareness
- `plugin.json`: allow WebFetch docs.anthropic.com, allow Bash(claude *)
- Detección: proyecto contiene `CLAUDE.md.tmpl` o `agents/*.md` o `skills/*/SKILL.md`

**Archivos**: `stacks/prompt-engineering/`

---

### 23. `/forge context-budget`

Skill que estima costo en tokens de la configuración actual:
- Cuenta tokens de CLAUDE.md + reglas con globs matching
- Estima file security warning overhead (tokens × reads esperados)
- Calcula ratio config/ventana total
- Recomienda conversión eager→lazy, eliminación de reglas inertes

**Archivos**: `skills/context-budget/SKILL.md`

---

### 24. `forge.md` descripción incorrecta de `/forge init`

**Problema**: forge.md dice "zero questions" pero init-project hace 4 preguntas.

**Fix**: Cambiar a "auto-detects stacks, asks 4 quick questions, generates personalized config."

**Archivo**: `global/commands/forge.md`

---

### 25. `Bash(make *)` ausente del template base

**Problema**: Solo 4 stacks incluyen `Bash(make *)`. Makefile es build system universal.

**Fix**: Agregar al template base allow list.

**Archivo**: `template/settings.json.tmpl`

---

## P3 — Investigación (sin fecha)

### 26. Coordinator Mode integration
Monitorear si `COORDINATOR_MODE` se habilita en releases públicos. Si aparece, crear stack `coordinator`.

### 27. autoDream memory consolidation
Investigar si el sistema de consolidación de memoria en 4 fases es configurable externamente.

### 28. Session memory compaction format
Investigar si `post-compact.sh` puede generar output en el formato que activa `sessionMemoryCompact` (bypass de API call).

### 29. `/etc/claude-code/CLAUDE.md` managed memory
Agregar detección en `global/sync.sh` para evitar duplicar reglas con deployments enterprise.

### 30. `@include` directive como reemplazo de `forge:section`
Evaluar si `@./path` puede reemplazar el merge de CLAUDE.md en bootstrap/sync. Ventaja: no requiere merge logic. Limitación: no funciona en code blocks. Requiere prototipo en proyecto real.

### 31. Custom compact instructions por stack
Agregar sección `## Compact Instructions` en CLAUDE.md template que le diga al compressor qué preservar por dominio.

---

## Resumen cuantitativo

| Prioridad | Items | Categoría |
|-----------|-------|-----------|
| P0 | 8 | Bugs (3), security (3), eficiencia (2) |
| P1 | 10 | System prompt conflicts (1), permissions (3), overlaps (2), skills (2), agents (1), hooks (1) |
| P2 | 7 | Features (3), cleanup (3), docs (1) |
| P3 | 6 | Investigación |
| **Total** | **31** | |

## Orden de ejecución sugerido

```
P0.1-P0.8 (bugs + security)  ─── v2.8.0 (fix release)

P1.9  (system prompt overrides)  ─┐
P1.10 (auto-mode stripping)       │
P1.11 (node-express overlap)      ├── v2.9.0 (internals alignment)
P1.12 (data-analysis overlap)     │
P1.13 (deferred tools)            │
P1.15 (agent frontmatter)         ┘

P1.14 (skill compaction budget)  ─┐
P1.16 (sessionEnd async)          │
P1.17 (hookify fixes)             ├── v2.10.0 (hooks + skills)
P1.18 (detect.md)                 │
P2.20 (new hook events)           ┘

P2.19 (redis duplication)  ─┐
P2.21 (go-api cleanup)      │
P2.22 (stack prompt-eng)    ├── v3.0.0 (new features)
P2.23 (/forge ctx-budget)   │
P2.24-25 (forge.md + make)  ┘

P3.26-31 (investigación)  ─── ongoing
```
