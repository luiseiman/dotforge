# Roadmap claude-kit

Estado actual: **v2.8.0** (2026-04-03)

---

## Completado

### v2.8.0 — P1 Internals Alignment (2026-04-03)

Ver sección v2.8.0 abajo para el detalle completo.

### v2.7.1 — Hook Architecture Corrections + Expansion (2026-03-30)

- Corrección: PreCompact es non-blocking (exit code ignorado)
- Verificado: PostCompact recibe `compact_summary` + `trigger` (docs oficiales incompletas)
- 4 eventos de hook de alto valor documentados: PermissionRequest, SubagentStart, CwdChanged, StopFailure
- Hook types `http`, `prompt`, `agent` documentados en hookify
- Corrección rule-effectiveness.md: eager loading (`globs:`) vs lazy loading (`paths:` CSV + `alwaysApply: false`)
- 5 prácticas de investigación incorporadas al pipeline activo
- Comentario en issue #17204 con workaround de `globs:`

### v2.7.0 — Domain Knowledge Layer + Context Continuity (2026-03-30)

- `template/rules/domain-learning.md`: regla `globs:**/*` para persistir descubrimientos de dominio
- `/forge domain extract|sync-vault|list`: skill de gestión de conocimiento de dominio
- Frontmatter extendido: `domain:`, `last_verified:`, `domain_source:`
- `template/hooks/post-compact.sh`: PostCompact → escribe compact_summary + git state a `last-compact.md`
- `template/hooks/session-restore.sh`: SessionStart → re-inyecta last-compact.md tras compactación
- `/forge init` pregunta dominio/rol; `/forge bootstrap` crea seeds en `domain/`
- `/forge audit` muestra sección de domain knowledge (informacional, sin impacto en score)
- `/forge sync` skipea `.claude/rules/domain/` (preserva conocimiento acumulado)
- Demo GIFs: forge-init, forge-audit, forge-bootstrap, forge-status

### v2.6.1 — Docs Update + Rule Loading (2026-03-25)

- Documentación actualizada con eager vs lazy rule loading
- `guia-uso.md` sincronizada con v2.7.1
- Audit CI: `audit/score.sh` standalone para GitHub Actions

### v2.6.0 — CI/CD + MCP UX + Quality fixes (2026-03-21)

- `audit/score.sh`: script standalone para PRs sin depender de Claude
- `detect-stack-drift.sh`: PostToolUse hook que detecta dependencias nuevas con stack disponible
- `/forge mcp add <server>`: instala MCP server template en 1 comando
- MCP version pinning + `mcp/update-versions.sh`
- Model IDs explícitos en model-routing.md (haiku-4-5, sonnet-4-6, opus-4-6)
- `session-report.sh` wired en perfil standard y full

### v2.5.0 — Capture + MCP + Model Routing (2026-03-19)

- `/forge capture` sin args: auto-detección de contexto, propone insight pre-formateado
- `/cap`: alias shorthand (4 chars)
- MCP server templates: github, postgres, supabase, redis, slack
- `template/rules/model-routing.md`: criterios haiku/sonnet/opus por tipo de tarea
- 7 agents con modelo explícito

### v2.4.0 — Init + Global Sync + Integrations (2026-03-15)

- `/forge init`: quick-start con 3 preguntas, detección de idioma
- `/forge global sync`: auto-pull + resync `~/.claude/`
- `/forge unregister`: remover proyectos del registry
- OpenClaw integration (`/forge export openclaw`)
- 15 stacks, hook profiles (minimal/standard/strict)
- Session report hook, project tier en audit, bootstrap profiles
- Prompt injection scan (item 12), error Type column, git worktree isolation

---

### v2.8.0 — P1 Internals Alignment (2026-04-03)

#### Completado en v2.8.0

- Fix: node-express glob narrowed a backend paths — elimina overlap con react-vite-ts
- Fix: data-analysis glob removido `.py` — elimina overlap con python-fastapi
- Fix: auto-mode safe permissions — reemplazados python3/node/npm/aws/gcloud con tool commands específicos en 6 stacks
- Nuevo: ToolSearch Step 0 en watch-upstream + scout-repos skills (deferred tools discovery)
- Nuevo: `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000` en template settings
- Nuevo: async hooks documentados en hookify (async flag, asyncRewake, streaming)
- Mejora: detect.md — hookify + trading stacks añadidos, pyproject.toml refinado, priority rules
- Cambio: test-runner model haiku → sonnet (escribe tests, requiere razonamiento)
- Nuevo: 5K token output budget en 6 agents
- Nuevo: SendMessage continuation instruction en todos los agents
- Nuevo: system prompt override patterns en python-fastapi, java-spring, go-api
- Nuevo: `context: fork` en 5 skills pesadas (plugin-generator, bootstrap-project, init-project, domain-extract, audit-project)
- Nuevo: `docs/internal/claude-code-internals-analysis.md` — reverse engineering de 5 repos
- Nuevo: `docs/internal/improvement-plan-internals.md` — plan 36 items (P0+P1 done, P2-P3 pendientes)
- Nuevo: `docs/internal/feature-flags-reference.md` — env vars + feature gates usables hoy

#### Pendiente (movido a v2.9.0+)

- **PermissionRequest hook**: auto-allow para operaciones known-safe, log para auditoría
- **SubagentStart hook**: inyectar contexto de dominio automáticamente a subagentes spawneados
- **CwdChanged hook**: recargar reglas de dominio al cambiar de directorio mid-session
- **StopFailure hook**: capturar errores de API (rate_limit, billing_error) y sugerir retry strategy
- **`/forge doctor`**: diagnóstico del entorno con semáforo verde/amarillo/rojo
- **`/forge export openclaw`**: generar los 6 archivos de workspace desde config del proyecto
- **trading stack**: reglas domain-specific para bots y market data — necesita test en proyecto real
- **cloud-function stack**: evaluar si stack separado vs subconjunto de gcp-cloud-run

---

## v2.9.0 — LLM Stack + Effectiveness (planificado)

### Stack `llm-python`

- Para proyectos Python con LLM APIs (anthropic, openai, langchain, litellm)
- Rules: manejo de API keys, retry con backoff, no loggear `content`, costeo antes de batch ops, prompt versioning
- Auto-detección: si `pyproject.toml`/`requirements.txt` contiene `anthropic`, `openai`, `litellm`

### Practice effectiveness validation

- Completar los 5 recurrence checks de las prácticas en monitoring (fix-loop-root-cause, websocket-shadow-import, precompact-nonblocking)
- Promover prácticas validadas a reglas permanentes
- Dashboard de effectiveness en `/forge insights`

### MCP templates nuevos

- `mcp/filesystem/`: config con paths permitidos, deny `~/.ssh`, `~/.aws`
- `mcp/brave-search/`: config read-only con `BRAVE_API_KEY`

### Audit v2

- Puntaje de domain knowledge (actualmente informacional → opcional scored)
- Hook coverage score: % de eventos utilizados vs disponibles
- Config coherence como item obligatorio (actualmente solo warning)

---

## Backlog (válido, sin fecha)

| Item | Por qué no ahora |
|------|-----------------|
| Stacks como plugins independientes | Marketplace de Claude Code sin spec estable. Re-evaluar cuando `/forge watch` detecte release oficial. |
| Team mode (`.claude/team.json`) | Fuera de scope para uso personal. Desbloquear si hay 3+ usuarios en mismo proyecto. |
| CI GitLab template | El usuario usa GitHub. Añadir si hay demanda concreta. |
| Badge dinámico de audit score | Requiere CI pipeline estable primero. Evaluar post v2.8.0. |
| `/forge migrate` | Migración entre versiones mayores de Claude Code. Esperar breaking change real. |
| Hook `prompt` type en block-destructive | Dejar que Claude decida si un comando es destructivo en vez de regex. Alto costo por llamada — evaluar ROI. |

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
| MCP server self-hosting | claude-kit configura clientes, no servers |
