# Roadmap dotforge

Estado actual: **v2.8.1** (2026-04-05)

---

## Completado

### v2.8.0 — Internals Analysis + P0 Fixes + P1 Alignment (2026-04-05)

Reverse engineering de 5 repositorios + alineación de dotforge con internals verificados de Claude Code.

#### P0 — Bugs y Seguridad
- Fix: session-report.sh JSON corruption, block-destructive.sh regex, deny patterns faltantes
- Fix: agent frontmatter (`allowed-tools:` vs `tools:`, campo `memory:` inválido) en 7 agentes
- Fix: redis glob `**/*stream*` → `**/*redis*`, `_common.md` excedido, `Bash(cat *)` removido
- Nuevo: `Bash(make *)` en template base

#### P1 — Internals Alignment
- Fix: node-express glob narrowed a backend paths — elimina overlap con react-vite-ts
- Fix: data-analysis glob removido `.py` — elimina overlap con python-fastapi
- Fix: auto-mode safe permissions — reemplazados python3/node/npm/aws/gcloud con tool commands específicos en 6 stacks
- Nuevo: ToolSearch Step 0 en watch-upstream + scout-repos (deferred tools discovery)
- Nuevo: `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000` en template settings
- Nuevo: async hooks documentados en hookify (async flag, asyncRewake, streaming)
- Mejora: detect.md — hookify + trading stacks, pyproject.toml refinado, priority rules
- Cambio: test-runner model haiku → sonnet (escribe tests, requiere razonamiento)
- Nuevo: 5K token output budget en 6 agents + SendMessage continuation
- Nuevo: system prompt override patterns en python-fastapi, java-spring, go-api
- Nuevo: `context: fork` en 5 skills pesadas

#### Domain Rules — Source-Verified
- 6 domain rules actualizadas: hook-architecture (25 eventos), permission-model (5-step cascade), context-window-optimization (5-tier compaction), rule-effectiveness (frontmatter completo), agent-orchestration (task types, AGENT_TEAMS env var), prompting-patterns (system prompt conflicts)

#### Documentation
- `docs/internal/claude-code-internals-analysis.md` — cross-repo reverse engineering (5 repos)
- `docs/internal/improvement-plan-internals.md` — 36 items priorizados P0-P3
- `docs/internal/feature-flags-reference.md` — env vars, settings keys, flags internos, GrowthBook gates
- Análisis de reimplementaciones Python (nanocode 250 líneas, nano-claude-code 6.2K líneas)

### v2.7.1 — Hook Architecture Corrections + Expansion (2026-03-30)

- Corrección: PreCompact es non-blocking (exit code ignorado)
- Verificado: PostCompact recibe `compact_summary` + `trigger`
- 4 eventos de hook documentados: PermissionRequest, SubagentStart, CwdChanged, StopFailure
- Hook types `http`, `prompt`, `agent` documentados en hookify
- Corrección rule-effectiveness.md: eager loading (`globs:`) vs lazy loading (`paths:`)

### v2.7.0 — Domain Knowledge Layer + Context Continuity (2026-03-30)

- `template/rules/domain-learning.md`: regla `globs:**/*` para persistir descubrimientos de dominio
- `/forge domain extract|sync-vault|list`: skill de gestión de conocimiento de dominio
- `template/hooks/post-compact.sh` + `session-restore.sh`: context continuity post-compaction
- `/forge init` pregunta dominio/rol; `/forge sync` skipea `.claude/rules/domain/`

### v2.6.1 — Practices Pipeline + Python Debugging (2026-03-24)

- 2 prácticas promovidas desde cotiza-api-cloud (root cause first, package naming)
- 7 prácticas deprecadas

### v2.6.0 — Audit CI + Stack Drift + MCP (2026-03-21)

- `audit/score.sh`: script standalone para PRs, 12 checks, score 0-10
- `detect-stack-drift.sh`: PostToolUse hook para dependencias nuevas
- `/forge mcp add <server>`: instala MCP server template en 1 comando
- MCP version pinning + `mcp/update-versions.sh`
- Model IDs explícitos en model-routing.md

### v2.5.0 — Capture + MCP + Model Routing (2026-03-21)

- `/forge capture` auto-detección + `/cap` alias
- MCP server templates: github, postgres, supabase, redis, slack
- `template/rules/model-routing.md`: criterios haiku/sonnet/opus
- 7 agents con modelo explícito

### v2.4.0 — Init + Global Sync + Integrations (2026-03-21)

- `/forge init`: quick-start con 3 preguntas, detección de idioma
- `/forge global sync`: auto-pull + resync `~/.claude/`
- OpenClaw integration, plugin marketplace, hook profiles, session report

---

## v2.9.0 — LLM Stack + Effectiveness (próximo)

### Pendiente de v2.8.0 (movido)
- **PermissionRequest hook**: auto-allow para operaciones known-safe
- **SubagentStart hook**: inyectar contexto de dominio a subagentes
- **CwdChanged hook**: recargar reglas de dominio al cambiar directorio
- **StopFailure hook**: capturar errores de API, sugerir retry strategy
- **`/forge doctor`**: diagnóstico de entorno con semáforo
- **trading stack**: reglas domain-specific — test en proyecto real

### Stack `llm-python`
- Para proyectos Python con LLM APIs (anthropic, openai, langchain, litellm)
- Rules: API keys, retry con backoff, no loggear `content`, costeo antes de batch ops

### Practice effectiveness validation
- Completar recurrence checks de prácticas en monitoring
- Promover prácticas validadas a reglas permanentes

### MCP templates nuevos
- `mcp/filesystem/`: config con paths permitidos, deny `~/.ssh`, `~/.aws`
- `mcp/brave-search/`: config read-only con `BRAVE_API_KEY`

### Audit v2
- Domain knowledge como item scored (actualmente informacional)
- Hook coverage score: % de eventos utilizados vs disponibles

---

## v3.0.0 — New Features (planificado)

### Nuevo stack: prompt-engineering
- Para proyectos que configuran Claude Code (meta-configuración)

### Nuevo skill: `/forge context-budget`
- Estima costo en tokens de la configuración actual

### Hooks para eventos no usados
- PostToolUseFailure → error tracking automático
- FileChanged → auto-reload patterns
- TaskCreated/TaskCompleted → métricas de orquestación
- PermissionDenied → audit trail

### Cleanup
- Redis section redundancy entre python-fastapi y redis
- go-api permisos redundantes
- forge.md: corregir "zero questions"

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
| Badge dinámico de audit score | Requiere CI pipeline estable primero |
| `/forge migrate` | Migración entre versiones mayores. Esperar breaking change real |
| Hook `prompt` type en block-destructive | Dejar que Claude decida vs regex. Alto costo — evaluar ROI |

---

## Descartado

| Idea | Razón |
|------|-------|
| npm/npx distribution | Requiere app code, rompe filosofía md+shell |
| Web UI / dashboard | Fuera de scope, terminal-native |
| Real-time analytics | Requiere daemon, contradice "no app code" |
| Stop hook B1 (grep-based) | Genera ruido sin semántica |
| 500+ skills at scale | Calidad > cantidad |
| Model routing automático en runtime | Over-engineering — reglas explícitas son más predecibles |
| Auto-escalation por token count | Over-engineering — routing por tipo de tarea, no por tamaño |
| MCP server self-hosting | dotforge configura clientes, no servers |
| `/forge export cursor\|windsurf` | Specs de terceros inestables |
