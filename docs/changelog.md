# Changelog — dotforge

> Version history. Entries use mixed Spanish/English as the project evolved. Technical terms are universal.
>
> Historial de versiones. Las entradas usan español/inglés mixto según la evolución del proyecto. Los términos técnicos son universales.

## v2.9.0 (2026-04-05) — RELEASED

### Hardening + Portability + Upstream Alignment + E2E Validated

#### Reliability Fixes (Codex Review)
- Fix: `audit/score.sh --json` — triple-quote Python heredoc + true/false → sanitized strings + True/False
- Fix: `check-updates.sh` — manifest path `.forge-manifest.json` → `.claude/.forge-manifest.json`
- Fix: `detect-stack-drift.sh` — reads stacks from manifest file sources (was reading nonexistent `stacks` field)
- Fix: `detect-stack-drift.sh` — react/vite message `/forge mcp add` → `/forge sync`
- Fix: `test-config.sh` — injection scan false positive on `<instructions>` (now requires closing tag)
- Fix: `hookify` — settings.json.partial paths from `$DOTFORGE_DIR/stacks/hookify/` → `.claude/hooks/hookify/`
- Schema: manifest now includes `stacks` array (bootstrap + sync skills updated)

#### Portability
- Fix: `check-updates.sh` — portable timeout: `timeout` → `gtimeout` → skip (macOS + Git Bash)
- Fix: 3 hooks — `_hash()` POSIX function: `md5sum` → `md5` → `cksum` (Git Bash compatible)
- Fix: 11 scripts — shebangs normalized `#!/bin/bash` → `#!/usr/bin/env bash`
- New: `install.sh` — one-liner installer with platform detection (macOS/Linux/WSL/Git Bash)

#### Upstream Alignment (Claude Code v2.1.84–v2.1.92)
- Update: 26 hook events (Setup removed), `if` conditional field, `defer` decision documented
- Update: 6 permission modes (added auto, dontAsk) with classifier details
- Update: 1M context window GA for Opus 4.6 / Sonnet 4.6, auto-compact buffers recalculated
- Update: MCP tools can override result cap to 500K via `_meta` annotation
- Update: `paths:` frontmatter now accepts YAML list syntax
- Update: Claude 3 Haiku deprecated (retiring April 19, 2026)
- New domain rules: `auto-mode.md`, `hook-events.md`
- Split: `hook-architecture.md` → `hook-architecture.md` + `hook-events.md` (50-line constraint)
- Split: `permission-model.md` → `permission-model.md` + `auto-mode.md`

#### Project Health
- Audit: all 12 projects scored (8 perfect 10.0, avg 9.8/10)
- Migration: claude-kit → dotforge completed across all 12 projects (symlinks, hooks, settings, commands)
- Global sync: deny list aligned (global template +5 entries, `**/` recursive globs)
- Security: Jira PAT removed from global settings.json, stale entries cleaned
- Hygiene: `__pycache__/`, `*.pyc` added to .gitignore

#### README
- Tagline: "Configuration factory" → "Configuration governance"
- New: lifecycle hero diagram, "Works with" table, multi-platform export section
- New: Requirements with WSL/Windows guidance
- Updated: Spanish section aligned

#### Documentation
- New: `docs/plan-v2.9.md` — execution plan with competitive analysis
- Updated: `docs/best-practices.md` — 26 hook events
- Updated: `docs/security-checklist.md` — auto mode safety section
- Updated: `docs/creating-stacks.md` — paths YAML format + stack hook copying

#### E2E Validation (2026-04-05)
- Bootstrap on clean project: 20 files created, react-vite-ts detected, manifest with stacks
- Audit: 8.87/10 (text + JSON valid)
- Status: 12 projects, avg 9.8/10
- Sync: all in sync, no destruction
- Checklist: 28/28 passed. Verdict: SHIP

---

## v2.8.1 (2026-04-05)

### Source-Verified Corrections + Cleanup

- Fix: compaction threshold corrected from "~90%" to "effectiveContextWindow - 13K tokens (≈93.5% for 200K)"
- Fix: MEMORY.md index has dual cap: 200 lines AND 25KB — whichever triggers first
- Fix: auto-mode permission stripping is reversible (restored on exit)
- Fix: complete dangerous patterns list: +tsx, +env, +xargs, +ssh, matching rules documented
- Fix: hook events count 25 → 27 (+PermissionDenied, +Setup, +WorktreeCreate, +WorktreeRemove)
- Fix: PostCompact dual interface documented (command hook vs SDK schema field names)
- Nuevo: tool result size limits documented (50K/tool, 200K/turn, 30K bash)
- Nuevo: tool concurrency & safety classification table
- Nuevo: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80` in template settings
- Cleanup: go-api redundant permissions removed (go test/build/run/vet → go *)
- Cleanup: python-fastapi Redis section removed (use redis stack)
- Cleanup: _common.md split to ≤50 lines → practice-capture.md + context-continuity.md
- Fix: forge.md init description ("zero questions" → "4 quick questions")
- Ref: hardcoded system prompt rules documented in internals (reference only)
- Ref: 6 additional settings.json keys documented, constants table expanded

---

## v2.8.0 (2026-04-05)

### Internals Analysis + P0 Fixes + P1 Alignment

Deep reverse engineering of Claude Code internals from 5 repositories, verified against source code. All P0 bugs fixed, P1 alignment completed.

#### P0 Bug Fixes
- Fix: `session-report.sh` — `$DOMAIN_CHANGES` used before defined → invalid JSON output
- Fix: `block-destructive.sh` — regex `\*` in ERE mode didn't match literal `*` → switched to `grep -qiF`
- Fix: missing deny patterns — `DROP TABLE`, `DROP DATABASE`, `git checkout --`, `git checkout .` added
- Fix: agent frontmatter — `tools:` → `allowed-tools:` in 7 agents (was silently ignored)
- Fix: agent frontmatter — removed invalid `memory: project` field from 5 agents
- Fix: redis glob — `**/*stream*` matched unrelated files → narrowed to `**/*redis*`
- Fix: `_common.md` exceeded 50-line limit (67 lines) → split into separate files
- Fix: removed `Bash(cat *)` from allow list (conflicts with Read tool)
- Fix: added `Bash(make *)` to base template allow list

#### P1 Internals Alignment
- Fix: node-express glob narrowed to backend paths — avoids overlap with react-vite-ts
- Fix: data-analysis glob removed `.py` — avoids overlap with python-fastapi
- Fix: auto-mode safe permissions — replaced python3/node/npm/aws/gcloud with specific tool commands in 6 stacks
- Nuevo: ToolSearch Step 0 in watch-upstream + scout-repos skills (deferred tools discovery)
- Nuevo: `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000` env var in template settings
- Nuevo: async hooks documentation in hookify (async flag, asyncRewake, streaming)
- Mejora: detect.md — added hookify + trading stacks, pyproject.toml refined, priority rules
- Cambio: test-runner model haiku → sonnet (writes tests, needs reasoning quality)
- Nuevo: 5K token output budget in 6 agents + SendMessage continuation in all agents
- Nuevo: system prompt override patterns in python-fastapi, java-spring, go-api
- Nuevo: `context: fork` on 5 heavy skills for post-compaction safety

#### Domain Rules — Source-Verified Updates
- `hook-architecture.md`: 25 events (was 13), async hooks, timeouts, plugin env vars, event details
- `permission-model.md`: 5-step evaluation cascade, bash prefix detection, auto-mode stripping
- `context-window-optimization.md`: 5-tier compaction hierarchy, token budgets, env vars for control
- `rule-effectiveness.md`: complete frontmatter fields (model, effort, context, agent, allowed-tools)
- `agent-orchestration.md`: task types, slash command priority, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `prompting-patterns.md`: system prompt conflicts, override patterns, language rules

#### New Documentation
- `docs/internal/claude-code-internals-analysis.md` — comprehensive cross-repo analysis (system prompt, context window, 41 tools, permissions, hooks, agents, sessions, undocumented features)
- `docs/internal/improvement-plan-internals.md` — 36 prioritized items (P0-P3) with execution plan
- `docs/internal/feature-flags-reference.md` — complete feature flags: 9 env vars, 4 settings keys, 7 internal flags (KAIROS, Coordinator, ULTRAPLAN, Voice, Vim, Undercover, Anti-Distillation), 25+ GrowthBook gates, 10 gated slash commands

#### Python Reimplementation Insights
- Analysis of nanocode (250 lines, minimal viable loop) and nano-claude-code (6.2K lines, full reimplementation)
- 5 insights: pre-compaction tool-result snipping, read_only/concurrent_safe annotations, skill context:fork, minimal system prompt sufficiency, self-documenting tool descriptions

---

## v2.7.1 (2026-03-30)

### Hook Architecture — Correcciones y expansión

- Corrección: `PreCompact` es **non-blocking** — el exit code se ignora (documentación anterior era incorrecta)
- Verificado: `PostCompact` recibe `compact_summary` y `trigger` — los docs oficiales dicen "common fields only" pero estos campos SÍ llegan
- Nuevo: hook types `http`, `prompt`, `agent` documentados en `stacks/hookify/rules/hookify.md`
- Nuevo: 4 eventos de alto valor añadidos a `hook-architecture.md`: PermissionRequest, SubagentStart, CwdChanged, StopFailure
- Corrección: `rule-effectiveness.md` — documentación de eager loading (`globs:`) vs lazy loading (`paths:` CSV + `alwaysApply: false`). Ref: [anthropics/claude-code#17204](https://github.com/anthropics/claude-code/issues/17204)
- 5 prácticas de investigación incorporadas al pipeline activo

---

## v2.7.0 (2026-03-30)

### Domain Knowledge Layer + Context Continuity

#### Domain Knowledge Layer

- Nuevo: `template/rules/domain-learning.md` — regla `globs:**/*` que instruye a Claude a persistir descubrimientos de dominio en `.claude/rules/domain/`
- Nuevo: `skills/domain-extract/SKILL.md` — skill `/forge domain extract|sync-vault|list` para extraer y gestionar conocimiento de dominio del proyecto
- Nuevo: frontmatter extendido para domain rules: campos `domain:`, `last_verified:`, `domain_source:`
- Mejora: `template/CLAUDE.md.tmpl` — secciones `## Role` y `## Domain` añadidas al template base
- Mejora: `/forge init` — pregunta 4 sobre dominio/rol del proyecto
- Mejora: `/forge bootstrap` — crea archivos seed en `domain/` durante el bootstrap
- Mejora: `/forge audit` — muestra sección de domain knowledge (informacional, sin impacto en score)
- Mejora: `/forge sync` — skippea explícitamente `.claude/rules/domain/` (nunca sobrescribe conocimiento de dominio acumulado)

#### Context Continuity

- Nuevo: `template/hooks/post-compact.sh` — hook PostCompact que escribe `compact_summary` + estado git en `.claude/session/last-compact.md`
- Nuevo: `template/hooks/session-restore.sh` — hook SessionStart con `source="compact"` que re-inyecta last-compact.md como contexto al iniciar sesión después de compactación
- Mejora: `template/settings.json.tmpl` — registra ambos hooks (PostCompact + SessionStart)
- Mejora: `template/rules/_common.md` — sección Context Continuity: Claude actualiza last-compact.md después de tareas significativas

---

## v2.6.1 (2026-03-24)

### Practices pipeline — Python debugging rules

- Incorporado: `stacks/python-fastapi/rules/backend.md` — regla "root cause first": antes de hacer un fix, verificar import errors, shadowed packages y env vars
- Incorporado: `stacks/python-fastapi/rules/backend.md` — regla "package naming": verificar con `pip3 show <dirname>` antes de nombrar un directorio local para evitar shadowing de PyPI packages
- Fuente: 2 prácticas promovidas a active/ desde cotiza-api-cloud (fix-loop-root-cause, websocket-shadow-import)
- Deprecadas: 7 prácticas de inbox (session logs sin contenido generalizable, cotiza security action item project-specific)

---

## v2.6.0 (2026-03-21)

### Audit CI + Stack Drift + MCP Versioning + Orchestration

- Nuevo: `audit/score.sh` — script bash standalone (3.2+ compatible) que evalúa 12 items mecánicos sin Claude. Flags: `--json`, `--threshold N`. Score 0-10, security cap 6.0 si faltan settings.json o block-destructive
- Nuevo: `.github/workflows/audit.yml` — CI que ejecuta score.sh en PRs y comenta el score. Bloquea si score < `AUDIT_SCORE_THRESHOLD` (default 7.0)
- Nuevo: `template/hooks/detect-stack-drift.sh` — PostToolUse hook que detecta nuevas dependencias y avisa sobre stacks no instalados. Monitorea package.json, pyproject.toml, go.mod, pom.xml, Gemfile. Nunca bloquea (exit 0 siempre)
- Nuevo: `skills/mcp-add/SKILL.md` — skill `/forge mcp add <server>` que instala templates MCP en proyectos (merge config, permisos aditivos, copia rules.md)
- Mejora: MCP version pinning — todos los config.json con versiones exactas: github@2025.4.8, postgres@0.6.2, redis@2025.4.25, slack@2025.4.25, supabase@0.7.0
- Nuevo: `mcp/update-versions.sh` — script que consulta npm y actualiza pines de versión en todos los config.json
- Mejora: `template/rules/agents.md` — sección TodoWrite con guía de cuándo/cómo usarlo (session-scoped, mark immediately, ≥3 acciones)
- Mejora: `template/rules/model-routing.md` — tabla de Model IDs explícitos (opus/sonnet/haiku con IDs de API exactos para agosto 2025)
- Mejora: `template/settings.json.tmpl` — añadido Stop hook para session-report.sh y detect-stack-drift.sh en PostToolUse

---

## v2.5.0 (2026-03-21)

### Learning Loop + MCP Templates + Model Routing

- Nuevo: `/forge capture` modo auto-detección — sin args, analiza contexto de sesión, propone insight pre-formateado, pide confirmación Y/n/edit antes de guardar
- Nuevo: `/cap` — alias shorthand para `/forge capture` (4 chars vs 14)
- Nuevo: Regla proactiva en `template/rules/_common.md` — Claude sugiere `/cap` al detectar workaround, bug multi-intento, decisión con trade-offs, o comportamiento de API no-obvio
- Nuevo: `mcp/` — templates de servidores MCP para github, postgres, supabase, redis, slack. Cada uno con config.json (mcpServers entry), permissions.json (allow/deny/prompt por tool), rules.md (reglas Claude-consumed). Auto-detectados por `/forge bootstrap`
- Nuevo: `template/rules/model-routing.md` — criterios explícitos haiku/sonnet/opus por tipo de tarea, con tabla de escalation y MCP operations
- Cambio: 7 agents con modelo explícito — researcher/test-runner=haiku, implementer/code-reviewer/session-reviewer=sonnet, architect/security-auditor=opus. Anterior: todos en `model: inherit`
- ROADMAP reescrito: documenta v2.4.0 completado, v2.5.0 completado, v2.6.0 próximo, descartados

---

## v2.4.0 (2026-03-21)

### Init, Unregister, Auto-update, Privacy
- Nuevo: `/forge init` — setup rápido con detección de stack + 3 preguntas (qué hace/no hace, con qué, cómo trabajo). Detecta idioma del usuario. Genera CLAUDE.md personalizado
- Nuevo: `/forge unregister <project>` — elimina proyecto del registry sin borrar config
- Cambio: `/forge global sync` ahora hace `git pull --ff-only` automático de dotforge antes de sincronizar
- Fix: registry ships vacío (`projects: []`). Datos locales en `projects.local.yml` (gitignored). No más paths privados en el repo público
- Fix: limpieza de datos personales en practices y evaluating
- Nuevo: `demo/README.md` con instrucciones para grabar demo GIF manualmente (vhs no funciona con CLIs interactivos)
- Nuevo: GitHub Releases para v2.1.0, v2.2.0, v2.3.0

---

## v2.3.0 (2026-03-21)

### Plugin Generator + OpenClaw Integration
- Nuevo: `/forge plugin` — genera un paquete de plugin de Claude Code desde la config del proyecto actual, listo para `claude --plugin-dir` o submission al marketplace oficial
- Nuevo: skill `plugin-generator` — convierte rules a skills, hooks a hooks.json, extrae deny list, genera README
- Nuevo: `integrations/openclaw/` — bridge skill para operar /forge desde WhatsApp, Telegram, Slack via OpenClaw
- Nuevo: `/forge export openclaw` — genera workspace skill de OpenClaw por proyecto
- Fix: OpenClaw install.sh usa `skills.load.extraDirs` en vez de symlinks (evita "Skipping skill outside root")
- Fix: Variables de entorno van en `~/.openclaw/.env`, no en `.bashrc`

---

## v2.2.0 (2026-03-20)

### CI/CD + Quality + OpenClaw Integration
- Nuevo: GitHub Actions CI workflow — validates hooks (bash -n + permissions), YAML files, rules frontmatter, stack completeness, skill completeness, benchmark tasks, version consistency
- Nuevo: `tests/lint-rules.sh` — validates all rule .md files have `globs:` frontmatter
- Nuevo: `integrations/openclaw/` — bridge skill que permite operar `/forge` desde WhatsApp, Telegram, Slack, Discord via OpenClaw
- Nuevo: `/forge export openclaw` — genera un workspace skill de OpenClaw por proyecto con contexto, reglas, deny list, y bridge CLI
- Cambio: `forge-export.md` y export-config skill actualizados con OpenClaw como cuarto target
- Fix: plugin.json version synced to VERSION file (CI catches mismatches)

---

## v2.1.0 (2026-03-20)

### Making it real
- Fix: `/forge benchmark` y `/forge rule-check` agregados al dispatch de forge.md (skills existían pero /forge no ruteaba a ellos)
- Cambio: `/forge watch` reescrito — ahora usa WebFetch en docs oficiales + WebSearch como fallback, con comparación estructurada contra template
- Cambio: `/forge scout` reescrito — usa `gh api` para fetch read-only de configs `.claude/` de repos en sources.yml, clasificación novel/variant/superior/covered
- Cambio: usage guide + guía de uso actualizados con sección Config Validation (session metrics, rule-check, benchmark, test-config.sh)
- Fix: skill counts 11 → 13 en ambas guías
- Registrados 10 proyectos reales en registry (3 auditados, 4 bootstrap standard, 3 bootstrap minimal)

---

## v2.0.0 (2026-03-20)

### Stabilization
- Nuevo: `docs/internal/architecture-components.md` — component map completo (template, stacks, skills, agents, practices, audit, global, registry)
- Nuevo: `docs/internal/scoring-algorithm.md` — fórmula, security cap, ejemplos por tier
- Nuevo: `docs/internal/config-validation-flow.md` — diagramas de data flow para las 4 fases
- Git tags retroactivos v0.1.0 → v1.6.0 (13 tags anotados)
- Practices inbox limpio (plugin-system → deprecated, duplicate removed)
- Registry re-auditado en v1.6.0, changelog completo v0.1.0 → v2.0.0

---

## v1.6.0 (2026-03-20)

### Config Validation System
- Nuevo: `tests/test-config.sh` — 30 checks de coherencia interna (hooks existen, globs válidos, deny list completa, no contradicciones)
- Nuevo: coherence check integrado en `/forge audit` (paso 1c)
- Nuevo: skill `/forge rule-check` (`rule-effectiveness`) — clasifica reglas en activas/ocasionales/inertes cruzando globs contra git log
- Cambio: `session-report.sh` reescrito — genera JSON metrics en `~/.claude/metrics/{slug}/{date}.json` (siempre activo, SESSION_REPORT.md sigue opt-in)
- Nuevo: hook counters en `block-destructive.sh` y `lint-on-save.sh` — escriben a `/tmp/` para que session-report los agregue
- Nuevo: rule coverage calculation — cruza archivos tocados contra globs de rules por sesión
- Cambio: `session-insights` skill — retroactive analysis desde git log + CLAUDE_ERRORS.md cuando no hay métricas de sesión
- Nuevo: `practices/metrics.yml` — tracking binario de efectividad (monitoring → validated/failed tras N checks sin recurrencia)
- Cambio: `update-practices` skill — nueva Fase 4 recurrence check contra CLAUDE_ERRORS.md de proyectos del registry
- Nuevo: campos `effectiveness` y `error_type` en frontmatter de prácticas
- Nuevo: skill `/forge benchmark` — compara full config vs minimal en worktrees aislados con tareas estándar por stack
- Nuevo: 6 benchmark tasks (python-fastapi, react-vite-ts, swift-swiftui, node-express, go-api, generic)
- Nuevo: `metrics_summary` schema en registry para métricas agregadas por proyecto
- Nuevo: tabla de precondiciones en `forge.md` — valida estado antes de despachar acciones
- Nuevo: `docs/config-validation.md` — documentación completa del sistema de 4 fases

---

## v1.5.0 (2026-03-20)

### Intelligence & Analytics
- Nuevo: skill `/forge insights` (`session-insights`) — analiza sesiones pasadas: error patterns, file activity, agent usage, score trends. Genera recomendaciones y alimenta practices pipeline
- Nuevo: hook `session-report.sh` (Stop) — genera `SESSION_REPORT.md` al finalizar sesión (opt-in via `FORGE_SESSION_REPORT=true`)
- Nuevo: scoring trends en `/forge status` — sparkline ASCII, flechas de tendencia, alertas cuando score baja >1.5 puntos
- Nuevo: recomendación automática de `/forge sync` cuando score < 7.0 y hay nueva versión disponible

---

## v1.4.0 (2026-03-20)

### Distribution & Plugin
- Nuevo: `.claude-plugin/plugin.json` — metadata formal para el sistema de plugins de Claude Code
- Nuevo: `.claude-plugin/INSTALL.md` — documentación de modos de instalación (plugin vs full)
- Nuevo: `plugin.json` en cada uno de los 13 stacks para distribución independiente
- Los stack plugins son composables: múltiples se pueden instalar, permisos se mergean por unión
- Plugin mode = subconjunto curado (hooks + rules + commands)
- Full mode = git clone + sync.sh (skills, agents, practices pipeline)

---

## v1.3.0 (2026-03-20)

### Stack Expansion & Cross-Tool
- Nuevo stack: **node-express** — Node.js + Express/Fastify (rules + permissions)
- Nuevo stack: **java-spring** — Java + Spring Boot + Maven/Gradle (rules + permissions)
- Nuevo stack: **aws-deploy** — AWS CDK/SAM/CloudFormation (rules + deny list para ops destructivos)
- Nuevo stack: **go-api** — Go modules + standard library HTTP (rules + permissions)
- Nuevo stack: **devcontainer** — configuración de devcontainers para Claude Code
- Nuevo: skill `/forge export` (`export-config`) — exporta config a Cursor (`.cursorrules`), Codex (`AGENTS.md`), Windsurf (`.windsurfrules`)
- Nuevo: bootstrap profiles — `--profile minimal|standard|full` controla qué se instala
- Nuevo: project tier detection en audit — `simple|standard|complex` ajusta expectations de scoring
- 13 stacks totales (era 8)
- 11 skills totales (era 9)

---

## v1.2.3 (2026-03-20)

### Hardening & Quick Wins
- Nuevo: audit item 12 — prompt injection scan (escanea rules y CLAUDE.md por patrones sospechosos)
- Nuevo: hook profiles (`FORGE_HOOK_PROFILE`: `minimal|standard|strict`) en block-destructive.sh
- Nuevo: columna Type en CLAUDE_ERRORS.md (`syntax|logic|integration|config|security`)
- Nuevo: instrucción de git worktree `isolation: "worktree"` para Agent Teams en agents.md e implementer.md
- Nuevo: hook `warn-missing-test.sh` (PostToolUse, Write) — warning educativo cuando se crea archivo sin test (solo profile strict)
- Cambio: scoring actualizado para 12 items recomendados (preserva split 70/30)

---

## v1.2.2 (2026-03-19)

### Correcciones del análisis v1.2.1
- Fix: fórmula de scoring — recomendados ahora pesan 50% real (obligatorios perfectos sin recomendados = 7.0, no 10.0)
- Fix: template lint-on-save.sh usa swiftlint (consistente con stack swift-swiftui), eliminado swiftformat
- Fix: implementer.md ya no referencia `.claude/specs/in-progress/` inexistente
- Fix: README.md corregido "51 items" → "31 items" en security checklist
- Fix: fórmula duplicada en audit-project skill actualizada a nueva fórmula
- Nuevo: `stacks/detect.md` — lógica de detección de stacks centralizada (antes duplicada en 4 skills)
- Nuevo: bootstrap crea `.claude/agent-memory/` para agentes con `memory: project`
- Nuevo: git tags v0.1.0 a v1.2.1 (habilita `/forge diff` con comparación por tags)
- Cambio: `/forge watch` y `/forge scout` marcados como stubs en forge.md
- Cambio: registry scores recalculados con nueva fórmula
- Nuevo: audit cross-project error promotion — errores recurrentes (3+) en CLAUDE_ERRORS.md se promueven a practices/inbox
- Nuevo: audit gap capture — gaps de auditoría (obligatorios 0-1, recomendados 0) se capturan como prácticas
- Nuevo: update-practices genera rules automáticamente cuando la práctica lo amerita
- Nuevo: `/forge watch` skill formal (`watch-upstream`) — busca cambios en docs Anthropic
- Nuevo: `/forge scout` skill formal (`scout-repos`) — revisa repos curados
- Nuevo: `practices/sources.yml` — repos curados para scout
- Nuevo: agent memory operativo — 4 agentes (implementer, architect, code-reviewer, security-auditor) leen/escriben `.claude/agent-memory/`
- Nuevo: score trending — audit appends `history` entries al registry (nunca sobreescribe)
- Fix: `{{DOTFORGE_PATH}}` placeholder resuelto en instrucciones de global sync

---

## v1.2.0 (2026-03-19)

### Tooling defensivo
- Nuevo: `/forge diff` — muestra qué cambió en dotforge desde el último sync del proyecto
- Nuevo: `/forge reset` — restaura `.claude/` a la plantilla con backup y rollback
- Nuevo: Validación JSON obligatoria en bootstrap y sync antes de escribir settings.json
- Nuevo: Hook testing framework (`tests/test-hooks.sh`) — 10 tests para block-destructive y lint-on-save
- Nuevo: Manifest de archivos deployados (`.claude/.forge-manifest.json`) con hashes SHA256
- Bootstrap genera manifest automáticamente al finalizar
- Sync actualiza manifest después de aplicar cambios
- Diff usa manifest para comparación rápida si existe

---

## v1.1.0 (2026-03-19)

### Gestión global (~/.claude/)
- Nuevo: `global/CLAUDE.md.tmpl` — plantilla del CLAUDE.md global con marker `<!-- forge:custom -->`
- Nuevo: `global/settings.json.tmpl` — deny list base para settings.json global
- Nuevo: `global/sync.sh` — script que instala/actualiza symlinks de skills, agents y commands
- Nuevo: `global/commands/forge.md` — forge.md versionado (reemplaza archivo suelto por symlink)
- Nuevo: `/forge global sync` y `/forge global status` en el comando forge
- Nuevo: `/forge watch` y `/forge scout` (stubs para intake de prácticas externas)
- Fix: deny list global poblada (estaba vacía, contradiciendo la filosofía de seguridad)
- Fix: marker `<!-- forge:custom -->` agregado a ~/.claude/CLAUDE.md
- Cambio: `_common.md` simplificada — elimina duplicación con global CLAUDE.md (reglas de comportamiento van en global, reglas de código van en _common.md)
- Cambio: sync-template ahora verifica global antes de sincronizar (no duplica reglas)

---

## v1.0.1 (2026-03-19)

### Higiene interna
- Fix: frontmatter `globs:` agregado a `template/rules/_common.md` (inconsistencia con versión deployada)
- Fix: command `audit.md` actualizado a 8 stacks (faltaban gcp-cloud-run y redis)
- Fix: inflated scores corrected in registry (recalculated with v1.0 formula)
- Fix: bootstrap siempre copia `lint-on-save.sh` genérico (resuelve ambigüedad hooks de stack vs genérico)
- Fix: researcher constraint relajada de 5 a 15 file reads
- Eliminado: `docs/x-references.md` (contenido efímero)
- Nuevo: `docs/roadmap.md` con plan v1.0→v2.0

---

## v1.0.0 (2026-03-19)

### Estable y completo
- 8 stacks con rules + settings.json.partial: python-fastapi, react-vite-ts, swift-swiftui, supabase, docker-deploy, data-analysis, gcp-cloud-run, redis
- 6 hooks ejecutables verificados (template + stacks + global)
- Auditoría con verificación de contenido, chmod, y cap de seguridad
- Sync inteligente con merge de arrays y protección de customizaciones
- Pipeline de prácticas funcional e2e (capture → update → incorporate)
- Documentación completa: README, troubleshooting, creating-stacks, best-practices, security-checklist, prompting-patterns
- Registry con version tracking y last_sync
- practices/inbox vacío (todo procesado)

---

## v0.9.0 (2026-03-19)

### Pipeline de prácticas funcional
- update-practices simplificado: 3 fases (evaluar → incorporar → propagar), eliminada web search automática y deprecación automática
- capture-practice: validación de duplicados contra active/ e inbox/ antes de crear
- detect-claude-changes.sh: instrucciones de instalación completas como comentario
- Flujo e2e: /forge capture → /forge update funciona en una sesión

---

## v0.8.0 (2026-03-19)

### Documentación y onboarding
- README.md con quick start (3 pasos), estructura, tabla de stacks y skills
- docs/troubleshooting.md — 4 problemas comunes con checklist de diagnóstico
- docs/creating-stacks.md — guía completa para crear stacks nuevos

---

## v0.7.0 (2026-03-19)

### Sync inteligente
- Sync reescrito con merge inteligente: unión de sets para allow/deny, preserva hooks y permisos custom
- Dry-run obligatorio antes de aplicar (muestra diff exacto)
- Nunca toca settings.local.json ni secciones `<!-- forge:custom -->`
- Actualiza registry con last_sync y dotforge_version post-sync
- Score antes/después para verificar mejora
- Template CLAUDE.md.tmpl: nuevo marker `<!-- forge:custom -->` para secciones protegidas

---

## v0.6.0 (2026-03-19)

### Stacks faltantes
- Nuevo stack: **gcp-cloud-run** — rules (Cloud Run, Secret Manager, scaling, logging) + settings.partial
- Nuevo stack: **redis** — rules (Streams, consumer groups, keys, connection pool) + settings.partial
- Bootstrap y audit detectan los 8 stacks (python-fastapi, react-vite-ts, swift-swiftui, supabase, data-analysis, docker-deploy, gcp-cloud-run, redis)
- 8/8 stacks con rules + settings.json.partial completos

---

## v0.5.0 (2026-03-19)

### Auditoría que audite de verdad
- Checklist: CLAUDE.md ahora verifica secciones clave (stack, build, arquitectura), no solo líneas
- Checklist: hooks verifican chmod +x y wiring en settings.json
- Scoring: cap de 6.0 si falta settings.json o block-destructive (seguridad crítica)
- Skill audit-project: verifica ejecutabilidad de hooks, reporta dotforge_version
- Registry: nuevos campos `dotforge_version` y `last_sync` por proyecto
- Detección de stacks nuevos: gcp-cloud-run y redis

---

## v0.4.0 (2026-03-19)

### Completar lo roto
- settings.json.partial para docker-deploy (docker, docker-compose)
- settings.json.partial para supabase (supabase CLI)
- Hook lint-swift.sh para swift-swiftui (swiftlint + swift build fallback)
- Pipeline de prácticas: directorios evaluating/, active/, deprecated/ creados
- Example practice moved to active/ with incorporated_in complete
- Domain-specific practice discarded (local config only)
- Bootstrap skill: soporte multi-stack explícito + sugerencia de hook global
- 6/6 stacks ahora tienen settings.json.partial

---

## v0.3.0 (2026-03-19)

### Multi-Agent Orchestration
- 6 agentes especializados: researcher, architect, implementer, code-reviewer, security-auditor, test-runner
- Regla de orquestación global (agents.md) con decision tree de delegación
- Agentes instalados globalmente via symlink (~/.claude/agents/)
- Cadenas de agentes: feature, bug fix, security audit, refactor
- Soporte para Agent Teams (experimental, requiere Opus)
- Template y bootstrap actualizados para incluir agentes
- Checklist de auditoría incluye verificación de agentes

---

## v0.2.0 (2026-03-19)

### Pipeline de prácticas
- practices/ con ciclo de vida: inbox → evaluating → active → deprecated
- Skill capture-practice para registrar insights manuales
- Skill update-practices reescrito con pipeline de 5 fases
- Comando /forge capture, /forge inbox, /forge pipeline
- Hook Stop global: detecta cambios en .claude/ y los registra en inbox
- Scheduled task forge-weekly-update (lunes 9:15 AM)

---

## v0.1.0 (2026-03-19)

### Inicial
- Template base: CLAUDE.md.tmpl, settings.json.tmpl, rules/_common.md
- Hooks: block-destructive.sh, lint-on-save.sh
- Stacks: python-fastapi, react-vite-ts, swift-swiftui, supabase, data-analysis, docker-deploy
- Skills: audit-project, bootstrap-project, sync-template, update-practices
- Comando global: /forge (audit, sync, bootstrap, status, update)
- Auditor: checklist.md, scoring.md
- Registry: 7 proyectos registrados
- Docs: best-practices, prompting-patterns, security-checklist, x-references, anatomy-claude-md
- Comandos template: review, debug, audit, health
