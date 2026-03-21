# Changelog — claude-kit

> Version history. Entries use mixed Spanish/English as the project evolved. Technical terms are universal.
>
> Historial de versiones. Las entradas usan español/inglés mixto según la evolución del proyecto. Los términos técnicos son universales.

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
- Fix: `{{CLAUDE_KIT_PATH}}` placeholder resuelto en instrucciones de global sync

---

## v1.2.0 (2026-03-19)

### Tooling defensivo
- Nuevo: `/forge diff` — muestra qué cambió en claude-kit desde el último sync del proyecto
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
- Actualiza registry con last_sync y claude_kit_version post-sync
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
- Skill audit-project: verifica ejecutabilidad de hooks, reporta claude_kit_version
- Registry: nuevos campos `claude_kit_version` y `last_sync` por proyecto
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
