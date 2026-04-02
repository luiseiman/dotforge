# Plan de Mejoras claude-kit — Post-Análisis de Internals

**Fecha**: 2026-04-02
**Base**: Análisis cruzado de 3 repos de reverse engineering (ComeOnOliver, ThreeFish-AI, Kuberwastaken)
**Versión actual**: v2.7.1

---

## Principio rector

Cada mejora explota conocimiento verificado del código fuente de Claude Code para que claude-kit produzca configuraciones que trabajen **con** los mecanismos internos en vez de contra ellos.

---

## P0 — Correcciones inmediatas (bajo esfuerzo, alto impacto)

### 1. System Prompt Override Patterns en template

**Problema**: El system prompt de Claude Code tiene instrucciones hardcodeadas que anulan silenciosamente nuestras reglas:
- `"DO NOT ADD ANY COMMENTS"` — stacks que quieren docstrings pierden
- `"fewer than 4 lines"` — reglas que piden respuestas detalladas se ignoran
- `"minimize output tokens"` — análisis largos se truncan

**Acción**: Agregar sección `## System Prompt Overrides` en `template/rules/_common.md` con las contramedidas verificadas. Las reglas de stacks que necesitan output largo (data-analysis, security-auditor) deben incluir override explícito.

**Archivos**: `template/rules/_common.md`, `stacks/data-analysis/rules/data.md`

---

### 2. SessionEnd hook timeout guard

**Problema**: `session-report.sh` tiene **1.5 segundos** de timeout default. Si el script tarda más (cálculos de métricas, escritura de JSON), se mata silenciosamente y se pierden los datos de sesión.

**Acción**:
- Agregar `timeout: 5000` en la entrada del hook en `template/settings.json.tmpl`
- Documentar `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` como variable de entorno de override
- Optimizar `hooks/session-report.sh` para que el path crítico complete en <1s

**Archivos**: `template/settings.json.tmpl`, `hooks/session-report.sh`, `docs/best-practices.md`

---

### 3. Auto-mode permission stripping warning

**Problema**: Cuando un usuario activa auto/YOLO mode, los allow rules de interpreters (`python`, `node`), network (`curl`, `wget`, `ssh`) y shells se eliminan silenciosamente. Los usuarios no saben por qué sus permisos dejan de funcionar.

**Acción**:
- Documentar en `docs/security-checklist.md` la lista exacta de patrones que se eliminan
- Agregar nota en `template/settings.json.tmpl` como comentario-guía
- En el skill `bootstrap-project`, generar allow rules con paths específicos de scripts en vez de patterns de intérpretes

**Archivos**: `docs/security-checklist.md`, `skills/bootstrap-project/SKILL.md`

---

### 4. Bash prefix extraction awareness en permissions

**Problema**: `npm run lint` se extrae como `none` (sin prefix), lo que significa que siempre pide permiso aunque esté en allow list. `npm test` → `npm test` sí matchea. La extracción la hace una LLM call separada.

**Acción**: Crear tabla de referencia de prefixes reales en `docs/security-checklist.md`. Ajustar `template/settings.json.tmpl` para usar patterns que realmente matcheen el prefix extraction.

**Archivos**: `docs/security-checklist.md`, `template/settings.json.tmpl`

---

## P1 — Mejoras de arquitectura (esfuerzo medio, impacto alto)

### 5. Frontmatter enriquecido en agents y skills

**Descubrimiento**: Las reglas soportan `model`, `effort`, `context: fork`, `agent`, `allowed-tools` en frontmatter. Nuestros 7 agents y 15 skills no los usan.

**Acción**:
- Agregar `model: haiku` a `agents/researcher.md` y `agents/test-runner.md`
- Agregar `model: opus` a `agents/architect.md` y `agents/security-auditor.md`
- Agregar `model: sonnet` a los demás agents
- Agregar `effort: high` a `agents/security-auditor.md` y `agents/architect.md`
- Agregar `allowed-tools` restrictivo a agents read-only (researcher, code-reviewer)
- Documentar todos los campos en `docs/creating-stacks.md`

**Archivos**: `agents/*.md`, `docs/creating-stacks.md`

---

### 6. Post-compact budget-aware session restore

**Descubrimiento**: Después de compactación, Claude Code restaura máximo **5 archivos, 50K tokens total, 5K por archivo**. Nuestro `last-compact.md` compite con archivos de código por ese budget.

**Acción**:
- Limitar `post-compact.sh` output a máximo 3K tokens (deja margen para archivos de código)
- Agregar header `<!-- budget: 3000 tokens max -->` como guía para el hook
- Reestructurar `session-restore.sh` para inyectar un resumen ultra-compacto si `last-compact.md` excede 3K
- Documentar el budget en `docs/memory-strategy.md`

**Archivos**: `template/hooks/post-compact.sh`, `template/hooks/session-restore.sh`, `docs/memory-strategy.md`

---

### 7. `@include` directive en template CLAUDE.md

**Descubrimiento**: CLAUDE.md soporta `@include` nativo (`@./path`, `@~/path`, max depth 5). Esto podría simplificar la gestión multi-stack.

**Acción**:
- Evaluar reemplazo de secciones `<!-- forge:section -->` por `@include` directives
- Ventaja: los stacks no necesitan merge de CLAUDE.md — cada stack agrega un `@.claude/rules/stack-name.md` que se incluye automáticamente
- Limitación: `@include` no funciona dentro de code blocks
- Prototipo en un proyecto real antes de cambiar el template

**Archivos**: `template/CLAUDE.md.tmpl`, `skills/bootstrap-project/SKILL.md`, `skills/sync-template/SKILL.md`

---

### 8. 5-tier compaction documentation + custom compact instructions

**Descubrimiento**: La compactación tiene 5 tiers (no 1). Solo auto-compaction (tier 4) dispara hooks. El sistema soporta **custom compression instructions** por proyecto.

**Acción**:
- Documentar los 5 tiers en `docs/memory-strategy.md` con qué dispara cada uno
- Agregar sección en `template/CLAUDE.md.tmpl` con instrucciones de compactación custom (sección `## Compact Instructions` que le dice al compressor qué preservar)
- Ejemplo: un proyecto de trading podría decir "Preserve all position sizes, tickers, and trade rationale"

**Archivos**: `docs/memory-strategy.md`, `template/CLAUDE.md.tmpl`

---

### 9. New hook events: FileChanged + TaskCompleted

**Descubrimiento**: 12 eventos de hooks no documentados. Dos son inmediatamente útiles:
- `FileChanged`: detecta modificaciones externas (linters, formatters, git hooks) — ideal para auto-reload de config
- `TaskCompleted`: saber cuándo un subagent terminó — ideal para métricas de orquestación

**Acción**:
- Crear hook `on-file-changed.sh` en hookify stack que detecte cambios en `.claude/` y sugiera re-sync
- Agregar `TaskCompleted` a `session-report.sh` para contar delegaciones a subagents por sesión
- Documentar los 12 eventos nuevos en `docs/best-practices.md` con casos de uso

**Archivos**: `stacks/hookify/hooks/on-file-changed.sh`, `hooks/session-report.sh`, `docs/best-practices.md`

---

### 10. `hasReadFile` compaction gap documentation

**Descubrimiento**: El state tracker `hasReadFile` que valida Read-before-Edit **no sobrevive compactación**. En sesiones largas, después de auto-compact, Claude necesita re-leer archivos antes de editarlos aunque ya los haya leído.

**Acción**:
- Documentar en `template/rules/_common.md` que después de compactación, Claude debe re-leer antes de editar
- Agregar a `post-compact.sh` un listado de archivos editados recientemente para que Claude sepa cuáles re-leer

**Archivos**: `template/rules/_common.md`, `template/hooks/post-compact.sh`

---

## P2 — Features nuevos (esfuerzo alto, impacto medio-alto)

### 11. Stack `prompt-engineering`

**Descubrimiento**: El análisis reveló patrones precisos de cómo las reglas compiten con el system prompt. Hay demand para un stack dedicado a proyectos donde Claude Code configura a Claude Code (meta-configuración).

**Contenido del stack**:
- `rules/prompt-eng.md`: system prompt override patterns, frontmatter reference, compaction awareness
- `settings.json.partial`: allow WebFetch para docs.anthropic.com, allow Bash(claude *)
- Auto-detección: si el proyecto contiene `CLAUDE.md.tmpl` o `agents/*.md` o `skills/*/SKILL.md`

**Archivos**: `stacks/prompt-engineering/`

---

### 12. `/forge context-budget`

**Descubrimiento**: Cada elemento de configuración consume tokens del context window. El file security warning se inyecta después de cada Read. Las reglas se cargan en la sección dinámica (no cached). Hay un budget real.

**Acción**: Nuevo skill que estima el costo en tokens de la configuración actual:
- Cuenta tokens de CLAUDE.md + todas las reglas con globs matching
- Estima costo de hooks por número de herramientas que matchean
- Calcula ratio: tokens de config / ventana total
- Recomienda: reglas a convertir de eager a lazy, reglas inertes a eliminar, CLAUDE.md sections a modularizar

**Archivos**: `skills/context-budget/SKILL.md`, `global/commands/forge-context-budget.md`

---

### 13. Async hooks en hookify stack

**Descubrimiento**: Hooks pueden declarar `async: true` para ejecución en background sin bloquear el main loop. También `asyncRewake` para hooks que quieren re-despertar al agente.

**Acción**:
- Documentar el patrón async en `stacks/hookify/rules/hookify.md`
- Crear ejemplo: `async-test-runner.sh` — PostToolUse async hook que corre tests en background después de cada Write, reporta resultados cuando termina sin bloquear al usuario
- Agregar a hookify la configuración `"async": true` en settings.json.partial

**Archivos**: `stacks/hookify/rules/hookify.md`, `stacks/hookify/hooks/async-test-runner.sh`

---

### 14. `claudeMdExcludes` en `/forge` workflow

**Descubrimiento**: El setting `claudeMdExcludes` puede desactivar CLAUDE.md files específicos sin borrarlos. Es un mecanismo de toggle más limpio que borrar/restaurar.

**Acción**:
- Agregar a `/forge audit` un check de archivos excluidos (warning si un rule file está excluido)
- Agregar a `/forge status` el listado de exclusiones activas
- Documentar como mecanismo de debugging en `docs/troubleshooting.md`

**Archivos**: `skills/audit-project/SKILL.md`, `docs/troubleshooting.md`

---

### 15. Tool deferral awareness en skills

**Descubrimiento**: Tools con `shouldDefer: true` no se cargan en el prompt inicial — se descubren via ToolSearch. Esto ahorra tokens pero significa que Claude no sabe que existen hasta buscarlos.

**Acción**:
- En skills que necesiten tools deferred (ej. NotebookEdit, MCPTool), incluir un step 0 que haga `ToolSearch` para cargar las definiciones
- Documentar en `docs/best-practices.md` el patrón de "descubrir antes de usar" para tools avanzados

**Archivos**: `docs/best-practices.md`, skills que usen tools deferred

---

## P3 — Investigación (sin fecha, requiere validación)

### 16. Coordinator Mode integration

El source revela un `COORDINATOR_MODE` feature-gated para multi-agent orchestration con parallel workers. Si se habilita, nuestra regla de Agent Teams debería adaptarse.

**Acción**: Monitorear con `/forge watch`. Si aparece en docs oficiales, crear un stack `coordinator` con rules de orquestación optimizadas.

---

### 17. autoDream memory consolidation

Claude Code tiene un sistema `autoDream` que consolida memoria en background (4 fases: orient, gather, consolidate, prune). Si esto es accesible, podríamos crear un hook que alimente el dream con conocimiento de dominio.

**Acción**: Investigar si `autoDream` es configurable o solo interno.

---

### 18. Session memory compaction experimental

Existe un `sessionMemoryCompact` que usa memorias pre-extraídas como resumen (sin API call). Si nuestro `post-compact.sh` genera resúmenes en el formato correcto, podría activar este path más eficiente.

**Acción**: Investigar el formato esperado y adaptar el hook.

---

### 19. `/etc/claude-code/CLAUDE.md` managed memory

Enterprise/managed deployments pueden inyectar política global en `/etc/claude-code/CLAUDE.md`. Si un usuario opera en ese contexto, `global/sync.sh` debería detectarlo y no duplicar reglas.

**Acción**: Agregar detección en `global/sync.sh`.

---

## Resumen de impacto esperado

| Prioridad | Items | Efecto principal |
|-----------|-------|-----------------|
| P0 | 4 | Eliminar conflictos silenciosos con system prompt, permisos, y timeouts |
| P1 | 6 | Configuraciones que explotan mecanismos internos (compaction, frontmatter, hooks) |
| P2 | 5 | Features nuevos habilitados por conocimiento de internals |
| P3 | 4 | Investigación para features futuros feature-gated |

## Orden de ejecución sugerido

```
P0.1 (system prompt overrides) ─┐
P0.2 (SessionEnd timeout)       ├── v2.8.0
P0.3 (auto-mode stripping)      │
P0.4 (bash prefix table)        ┘

P1.5 (frontmatter agents)  ─┐
P1.6 (compact budget)       ├── v2.9.0
P1.8 (5-tier docs)          │
P1.10 (hasReadFile gap)     ┘

P1.7 (@include eval)     ─┐
P1.9 (new hook events)    ├── v3.0.0
P2.11 (stack prompt-eng)  │
P2.12 (/forge ctx-budget) ┘

P2.13 (async hooks)       ─┐
P2.14 (claudeMdExcludes)   ├── v3.1.0
P2.15 (tool deferral)     ┘
```
