# Roadmap claude-kit

Estado actual: **v2.8.0** (2026-04-05)

---

## v2.8.0 — Completado

### Claude Code Internals Analysis + P0 Fixes

Reverse engineering de 5 repositorios (source tree, analysis, reimplementaciones Python) para verificar y alinear claude-kit con los internals reales de Claude Code.

- 8 bugs P0 corregidos: session-report.sh JSON corruption, block-destructive.sh regex, deny patterns faltantes, agent frontmatter (`allowed-tools:` vs `tools:`, campo `memory:` inválido), redis glob, _common.md excedido, `Bash(cat *)` removido
- 6 domain rules actualizadas con hallazgos verificados: hook-architecture (25 eventos), permission-model (5-step cascade), context-window-optimization (5-tier compaction), rule-effectiveness (frontmatter completo), agent-orchestration (task types, cache sharing), prompting-patterns (system prompt conflicts)
- Nuevo: `docs/internal/claude-code-internals-analysis.md` — análisis completo de internals
- Nuevo: `docs/internal/improvement-plan-internals.md` — 36 items priorizados P0-P3
- Nuevo: `docs/internal/feature-flags-reference.md` — referencia completa de feature flags (env vars, settings keys, flags internos, GrowthBook gates)
- Nuevo: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` documentado en agent-orchestration
- Nuevo: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` y `CLAUDE_CODE_DISABLE_AUTOCOMPACT` documentados en context-window-optimization
- Análisis de reimplementaciones Python (nanocode 250 líneas, nano-claude-code 6.2K líneas) con 5 insights incorporables

---

## v2.7.1 — Completado

### Hook Architecture — Correcciones y expansión

- Corrección: `PreCompact` es non-blocking — exit code se ignora
- Verificado: `PostCompact` recibe `compact_summary` y `trigger`
- Nuevos hook types: `http`, `prompt`, `agent` documentados
- 4 eventos nuevos: PermissionRequest, SubagentStart, CwdChanged, StopFailure
- Corrección: eager loading (`globs:`) vs lazy loading (`paths:` CSV + `alwaysApply: false`)

---

## v2.7.0 — Completado

### Domain Knowledge Layer + Context Continuity

- Domain Knowledge Layer: `domain-learning.md`, `/forge domain extract|sync-vault|list`, frontmatter extendido
- Context Continuity: `post-compact.sh` (PostCompact hook), `session-restore.sh` (SessionStart hook)
- `/forge init` pregunta 4 sobre dominio/rol
- `/forge sync` skippea `.claude/rules/domain/`

---

## v2.6.1 — Completado

### Practices pipeline — Python debugging rules

- 2 prácticas promovidas desde cotiza-api-cloud (root cause first, package naming)
- 7 prácticas deprecadas

---

## v2.6.0 — Completado

### Audit CI + Stack Drift + MCP Versioning + Orchestration

- `audit/score.sh` — script standalone, 12 checks mecánicos, score 0-10
- GitHub Action `audit.yml` — CI con score en PRs
- `detect-stack-drift.sh` — PostToolUse hook para dependencias nuevas
- `/forge mcp add <server>` — instalación de MCP templates
- MCP version pinning + `mcp/update-versions.sh`
- Model IDs explícitos en model-routing.md
- Stop hook para session-report.sh

---

## v2.5.0 — Completado

### Learning Loop + MCP Templates + Model Routing

- `/forge capture` auto-detección + `/cap` alias
- MCP templates: github, postgres, supabase, redis, slack
- `model-routing.md` con criterios haiku/sonnet/opus
- 7 agents con modelo explícito

---

## v2.9.0 — Internals Alignment (próximo)

Foco: alinear claude-kit con los internals verificados de Claude Code. Items P1 del improvement plan.

### System prompt conflict resolution

- Override patterns para hardcoded "no comments" y "4-line limit" en stacks de documentación
- Template con instrucciones de override fuertes donde se necesite

### Auto-mode permission fix

- Reemplazar 9 patrones que se borran silenciosamente en auto-mode (`Bash(python3 *)`, `Bash(node *)`, etc.) por paths específicos de scripts
- Documentar workaround en best-practices.md

### Glob overlap resolution

- node-express: acotar `**/*.{js,ts}` para no cargar en proyectos React
- data-analysis: diferenciar `**/*.py` de python-fastapi

### Skills post-compaction budget

- bootstrap-project (8K), domain-extract (6K), audit-project (6K) exceden presupuesto de 5K
- Adelgazar skills para caber en restoration budget

### Agent frontmatter enrichment

- `allowed-tools` y `effort` para los 7 agentes
- Deferred tools con ToolSearch en skills que usan WebFetch/WebSearch

### detect.md completeness

- Agregar hookify y trading stacks
- Refinar detección de pyproject.toml
- Priority resolution para stacks que se solapan

---

## v3.0.0 — New Features (planificado)

### Nuevo stack: prompt-engineering

- Para proyectos que configuran Claude Code (meta-configuración)
- Rules para context window optimization, rule design, prompt patterns

### Nuevo skill: `/forge context-budget`

- Estima costo en tokens de la configuración actual
- Desglose por: CLAUDE.md, rules, agent prompts, skills, hooks

### Hooks para eventos no usados

- PostToolUseFailure → error tracking automático
- FileChanged → auto-reload patterns
- TaskCreated/TaskCompleted → métricas de orquestación
- PermissionDenied → audit trail

### Cleanup

- Redis section redundancy entre python-fastapi y redis
- go-api permisos redundantes (`Bash(go test *)` etc. con `Bash(go *)`)
- forge.md: corregir "zero questions" (init hace 4)

---

## Backlog (válido, sin fecha)

| Item | Por qué no ahora |
|------|-----------------|
| Coordinator Mode integration | Gated a `false` en external build. Preparar stack cuando ship |
| autoDream memory consolidation | Investigar si post-compact output puede alimentar dream |
| Stacks como plugins independientes | Marketplace sin spec estable |
| Team mode (`.claude/team.json`) | Fuera de scope para uso personal |
| CI GitLab template | Sin demanda concreta |
| `@include` directive evaluation | Investigar si reemplaza modularización manual |
| Custom compact instructions por stack | Investigar `/compact` con instrucciones específicas |

---

## Descartado

| Idea | Razón |
|------|-------|
| npm/npx distribution | Requiere app code, rompe filosofía md+shell |
| Web UI / dashboard | Fuera de scope, terminal-native |
| Real-time analytics | Requiere daemon, contradice "no app code" |
| Stop hook B1 (grep-based) | Genera ruido sin semántica |
| 500+ skills at scale | Calidad > cantidad |
| Model routing automático en runtime | Over-engineering |
| Auto-escalation por token count | Routing por tipo de tarea, no por tamaño |
| MCP server self-hosting | claude-kit configura clientes, no servers |
| `/forge export cursor\|windsurf` | Specs de terceros inestables |
