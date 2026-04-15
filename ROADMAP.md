# Roadmap dotforge

Estado actual: **v3.1.1** (2026-04-15) — Domain knowledge sync con Claude Code v2.1.108 + `ask:` permission template + corrección `showThinkingSummaries`. v3 behaviors operativos en 4 proyectos piloto (dotforge, cotiza-api-cloud, TRADINGBOT, jira-nbch).

---

## Completado

### v3.1.1 — Doc fix `showThinkingSummaries` (2026-04-15)

Hotfix de domain rule: `showThinkingSummaries` se documentaba como si su toggle tuviera impacto operativo. Por spec oficial es puramente cosmético — no reduce gasto de thinking. Agregado `alwaysThinkingEnabled` como knob real de costo. Sin impacto en runtime.

### v3.1.0 — Domain knowledge sync (2026-04-15)

Watch-upstream pass contra `code.claude.com/docs` cubriendo Claude Code v2.1.70 → v2.1.109. Ocho practices aceptadas, tres rechazadas (auto-stubs).

#### Domain rules actualizadas
- `hook-architecture.md`: events count corregido **27 → 31** sobre tres ciclos (session-level, turn-level, tool-loop, async/side). `InstructionsLoaded`, `Elicitation`/`ElicitationResult`, `PreCompact` blockable desde v2.1.105.
- `permission-model.md`: nuevas secciones **Enterprise managed settings** (`managed-settings.d/`, `allowManagedHooksOnly`, `allowedChannelPlugins`, `forceRemoteSettingsRefresh`) y **Dynamic permissions from hooks** (`addRules`/`replaceRules`/`removeRules`/`setMode`/`addDirectories`/`removeDirectories`).
- `hook-events.md`: PreCompact blockability + payload de `InstructionsLoaded` + sección de elicitation events.
- `model-ids.md`: default `effort` cambió `medium → high` en v2.1.94.

#### Template
- `settings.json.tmpl`: nueva `ask:` list de 18 entries cubriendo `rm`/`chmod`/`npm-pip install`/`docker run`/`kubectl apply-delete`/`gcloud`/`aws`/`terraform apply-destroy`/`git push-rebase-cherry-pick`. Cierra el gap entre `allow:` total y `deny:` total.
- `block-destructive.sh`: verificado vs compound bash bypass class fixed en v2.1.98 — el hook usa `grep -qiE` sobre el comando completo, **no es vulnerable**. Test `ls && rm -rf /` → blocked. Limitaciones documentadas (eval, payloads codificados) con cross-ref a `sandbox.enabled`.

#### Behaviors rollout
- 4 proyectos piloto con v3 behaviors compilados y wired: dotforge (worktree), cotiza-api-cloud, TRADINGBOT, jira-nbch.
- Hallazgo: jira-nbch tenía hooks wired desde el setup inicial pero le faltaba `scripts/runtime/lib.sh` — fallaba silenciosamente. Restored.

### v3.0.0-alpha.1 — Behavior Governance Phase 1 (2026-04-13)

Primer aterrizaje del layer v3: runtime + compilador + search-first end-to-end + detección de override + CLI `/forge behavior`. Cinco piezas del SCOPE de Fase 1 cumplidas. No reemplaza v2.9: coexiste como capa adicional opt-in.

#### Spec closure (2 commits de docs)
- `docs/v3/SCOPE.md` alineado con `docs/v3/RUNTIME.md` — mkdir-based locking como decisión única (eliminación de `flock`)
- `docs/v3/RUNTIME.md` §4 + `SCHEMA.md` §3.5 + `SPEC.md` §2.3: modelo de flags formalizado (session-scoped, shape cerrado, `set_flag`/`check_flag` con `on_present`/`on_absent` obligatorios)

#### Runtime (`scripts/runtime/`, 454+154 líneas lib.sh + 8 tests)
- `.forge/runtime/state.json` con schema versionado, mkdir-based lock 2s + PID stale detection, atomic tmp+mv write, corruption recovery
- TTL 24h inline purge en cada mutación (jq pipeline)
- Counter increment, flag set/check/consume atómicos, `_forge_run_mutation` choke point
- Pure functions: `forge_resolve_level`, `forge_level_max`
- Tests: concurrencia paralela (10 increments), flag lifecycle, TTL, corruption, stale lock, pending_block
- `.gitignore` extensions: `.forge/runtime/`, `.claude/worktrees/`

#### Compilador (`scripts/compiler/`, ~320 líneas + 1 test)
- YAML → bash hook por trigger via `python3 + pyyaml` (no `yq` dependency)
- Hook template self-contained: fuentea `lib.sh` via `FORGE_LIB_PATH` env var o relative anchor fallback
- Set_flag hooks minimales (30 líneas), check_flag/evaluate hooks con helpers completos solo cuando `on_absent: violate` los necesita
- Settings.json snippet con `{type, command}` object format (requerido por Claude Code, NO strings planos)
- Template variables sustituidas via sed: `{behavior_name}`, `{counter}`, `{tool_name}`, `{level}`, `{threshold}`

#### search-first end-to-end (`behaviors/search-first/`, 5 scenarios)
- `behavior.yaml` canónico: Grep|Glob|Read → set_flag, Write|Edit → check_flag con consume/violate
- `behaviors/index.yaml` catalogue file
- Scenarios: happy path (Grep→Write consume), idempotent set, alternating, escalation silent→nudge→warning→soft_block, override reinvocation

#### Override detection via reinvocation (RUNTIME.md §12 + 1 test unit + 1 scenario e2e)
- `pending_block` shape: `{tool_input_hash, blocked_at}` en behavior state
- `forge_tool_input_hash` — sha256 truncado a 40 hex chars de canonical JSON
- `forge_pending_block_try_override` — match + window check + audit trail triple-write
- Ventana default 60s via `FORGE_OVERRIDE_WINDOW_SECONDS` env var
- Corrige `SPEC.md §6.2` que originalmente asumía `PermissionDenied` event hook (solo dispara para auto-mode, no para PreToolUse blocks — verificado empíricamente)

#### `/forge behavior` CLI (`scripts/forge-behavior/`, ~290 líneas + 4 tests)
- `status [--session SID]` — tabla project + runtime con counters, levels, overrides, pending
- `on|off <id> [--project | --session SID]` — project muta `index.yaml` via pyyaml, session escribe a `state.json`
- `strict|relaxed <id>` — project-scope, muta escalation thresholds (halve / double)
- Hook preamble short-circuita cuando `behavior_overrides[bid].enabled == false`
- `skills/forge-behavior/SKILL.md` como wrapper para Claude Code

#### Prueba viva end-to-end en sesión Claude Code real (`~/tmp-v3-live`)
- 7 prompts secuenciales → escalation silent→nudge→nudge→warning→warning→soft_block observable en pantalla real
- `permissionDecision: "deny"` del hook interpretado por Claude Code como permission denial (respeto SPEC §5.5 al pie de la letra)
- Emergent behavior: Claude Code leyó `state.json` post-block por iniciativa propia y explicó el pending_block mechanism al usuario sin que se le pidiera
- **Hallazgo empírico #1**: `/clear` resetea `session_id` en hook payloads → behaviors session-scoped evadibles vía `/clear` con zero audit trail. Documentado en `RUNTIME.md §3` y capturado en `practices/inbox/2026-04-13-v3-clear-creates-session-boundary.md` con 3 fixes propuestos para Fase 2.
- **Hallazgo empírico #2**: flag masking override — si hay un flag presente cuando viene retry post-soft_block, el path `forge_flag_consume` short-circuita antes del `try_override`, el retry pasa pero sin audit trail. No verificable en vivo por el `/clear`, verificable por code inspection, regression test en Fase 2.

#### Métricas Fase 1
- 9 commits en branch `v3-fase1` (1 spec alignment + 1 spec extension + 5 feature + 1 live findings + 2 doc updates)
- 18 tests verdes (8 runtime + 1 compiler + 5 e2e + 4 CLI)
- ~3000 líneas netas entre código, tests y spec updates
- 0 regresiones sobre v2.9.1 existente
- Zero breaking changes — v3 es aditivo, v2.9 sigue funcionando sin tocar

### v2.9.0 — Hardening + Portability + Upstream Alignment (2026-04-05)

Consolidación de confiabilidad basada en Codex review + alineación con Claude Code v2.1.84–v2.1.92.

- Fix: score.sh --json (heredoc Python roto), check-updates.sh (path), detect-stack-drift.sh (schema + mensaje), hookify (paths), injection scan (falso positivo)
- Portabilidad: timeout/md5sum/shebangs portables a macOS + Linux + WSL + Git Bash
- Nuevo: install.sh one-liner con detección de plataforma
- Upstream: 27 hook events, 6 permission modes, 1M context GA, paths: YAML list, Claude 3 Haiku deprecated
- Nuevas domain rules: auto-mode.md, hook-events.md
- Manifest: campo `stacks` agregado al schema
- README: tagline "governance", lifecycle hero, Works with, Requirements con WSL
- Auditoría completa: 12 proyectos, 8 perfect, avg 9.8/10
- Migración claude-kit → dotforge completada en todos los proyectos
- Deny list global alineada (+5 entries, **/recursive globs)
- .gitignore: __pycache__/, *.pyc

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

## v3.0.0 — Behavior Governance (en progreso)

### Fase 2 — Catálogo + fixes de hallazgos empíricos (2-3 semanas post-alpha.1)
- **Catálogo core** de behaviors: verify-before-done, no-destructive-git, respect-todo-state, plan-before-code, objection-format. Cada uno con `behavior.yaml` + scenarios tests.
- **Reorder check_flag template** — `forge_pending_block_try_override` debe correr antes de `forge_flag_consume` para cerrar el flag-masking-override gap detectado en la prueba viva.
- **`scope: project`** para behaviors session-clear-resistant (no-destructive-git es el candidato #1). Persiste counters en project state, no en session state, inmune a `/clear`.
- **Sweep de pending_blocks huérfanos** en hook init — si detecta una sesión distinta con pending_block no expirado, append a audit log como `session_abandoned_with_pending_block`.
- **`/forge audit` dimensión "behaviors coverage"** — item scored que cuenta qué fracción de eventos relevantes tienen behaviors registrados.
- **Tests por behavior** — cada behavior en `behaviors/<id>/tests/` con al menos 1 happy path + 1 violation + 1 escalation scenario.
- **Wiring del comando** — `/forge behavior` como sub-comando nativo en `global/commands/forge.md` (hoy se invoca directo al CLI).

### Fase 3 — Release (1-2 semanas)
- **README rewrite** — diferencial de v3 visible en las primeras 40 líneas. Hoy README habla solo de config governance, no de behavior governance.
- **CHANGELOG v3.0.0** formal
- **Migration guide** v2.9 → v3 (opt-in, no rompe 2.9)
- **Benchmark real** corrido en SOMA o InviSight — medir impacto del behavior layer en comportamiento observable de Claude
- **GIF demo** de search-first escalando en un proyecto real
- **Tag `v3.0.0`** release
- **Marketplace submission update** con features v3

### Pendiente legacy (movido de v2.8.0, sin urgencia)
- **PermissionRequest hook**: auto-allow para operaciones known-safe
- **SubagentStart hook**: inyectar contexto de dominio a subagentes
- **CwdChanged hook**: recargar reglas de dominio al cambiar directorio
- **StopFailure hook**: capturar errores de API, sugerir retry strategy
- **`/forge doctor`**: diagnóstico de entorno con semáforo
- **trading stack**: reglas domain-specific — test en proyecto real

### Stack `llm-python` (diferido)
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

## v3.2.0 — Próximo (planificado)

> El número v3.1.0 quedó tomado por el sync de domain knowledge del 2026-04-15. Las features originalmente planeadas para v3.1.0 se reagrupan acá.

### Nuevo stack: prompt-engineering
- Para proyectos que configuran Claude Code (meta-configuración)

### Nuevo skill: `/forge context-budget`
- Estima costo en tokens de la configuración actual

### Hooks para eventos no usados
- PostToolUseFailure → error tracking automático
- FileChanged → auto-reload patterns
- TaskCreated/TaskCompleted → métricas de orquestación
- PermissionDenied → audit trail

### Rollout v3 behaviors a los 8 proyectos restantes
- Después del periodo de validación de los 4 pilotos (dotforge, cotiza-api-cloud, TRADINGBOT, jira-nbch)
- Targets: SOMA, SOMA2, InviSight-iOS, derup, crm, cds-dashboard, openclaw, vault-bot

### Sandbox config para proyectos con secretos
- TRADINGBOT, derup → habilitar `sandbox.enabled` con `filesystem.denyRead` sobre `.env`

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
