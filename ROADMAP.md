# Roadmap claude-kit

Estado actual: **v1.2.2** (2026-03-19)

---

## v1.2.3 — Hardening & Quick Wins

Foco: seguridad, flexibilidad de hooks, mejor error tracking. Todo low-effort, high-value.

### Prompt injection detection en audit
- Nuevo item 12 en `audit/checklist.md` (recomendado, 0-1)
- Scan rules y CLAUDE.md buscando patrones sospechosos: `ignore previous`, `system:`, `<system>`, encoded payloads, base64 inline
- Si detecta → score 0, warning explícito
- Source: inspirado en tw93/claude-health

### Hook profiles
- Variable `FORGE_HOOK_PROFILE` con 3 niveles: `minimal`, `standard` (default), `strict`
- `minimal`: solo rm -rf y force push
- `standard`: current behavior (8 patrones)
- `strict`: standard + bloqueo de `curl | sh`, `eval`, `chmod 777`, write a `/etc/`
- Implementar en `block-destructive.sh` leyendo la variable
- Bootstrap pregunta qué profile usar, guarda en `.claude/settings.local.json` como env
- Source: inspirado en everything-claude-code

### Error classification en CLAUDE_ERRORS.md
- Agregar columna `Type` al formato: `syntax | logic | integration | config | security`
- Actualizar template de CLAUDE_ERRORS.md
- Actualizar rule `memory.md` con el nuevo formato
- Actualizar `audit/checklist.md` item 6 para validar presencia de Type
- Source: inspirado en alinaqi/claude-bootstrap

### Git worktree en Agent Teams
- Agregar instrucción a `agents.md` y al agent `implementer.md`
- Cuando Agent Teams se activa (≥3 components), cada teammate usa `isolation: "worktree"`
- Lead agent coordina merges al branch principal
- Source: inspirado en obra/superpowers

### TDD warning hook
- Nuevo hook opcional `warn-missing-test.sh` (PostToolUse, Write matcher)
- Detecta creación de archivo nuevo en `src/` o `app/` sin contrapartida en `tests/` o `__tests__/`
- Warning (exit 0), no bloqueo (exit 2) — es educativo, no enforcement
- Solo se activa en profile `strict`
- Source: inspirado en alinaqi/claude-bootstrap

---

## v1.3.0 — Stack Expansion & Cross-Tool

Foco: más stacks, exportación a otros harnesses, profiles de bootstrap.

### Nuevos stacks (4)
- `node-express` — Node.js + Express/Fastify
- `java-spring` — Java + Spring Boot + Maven/Gradle
- `aws-deploy` — AWS CDK/CloudFormation/SAM
- `go-api` — Go modules + standard library HTTP

Cada uno con: `rules/*.md` (globs), `settings.json.partial`, detección en `stacks/detect.md`.
Source: gaps identificados vs giuseppe-trisciuoglio/developer-kit

### Cross-tool export: `/forge export`
- Nuevo skill `export-config`
- Subcomandos: `cursor`, `codex`, `windsurf`
- `cursor`: genera `.cursorrules` a partir de rules + CLAUDE.md
- `codex`: genera `codex.md` o `AGENTS.md` en formato compatible
- `windsurf`: genera `.windsurfrules`
- Mapeo: rules → reglas planas, hooks → instrucciones textuales, deny list → warnings
- Source: inspirado en rohitg00/awesome-claude-code-toolkit

### Bootstrap profiles
- `/forge bootstrap --profile minimal|standard|full`
- `minimal`: CLAUDE.md + settings.json + block-destructive hook. Sin agents, sin commands, sin agent-memory
- `standard` (default): current behavior
- `full`: standard + todos los agents + todos los commands + agent-memory + CLAUDE_ERRORS.md pre-poblado
- Audit ajusta expectations por profile (minimal no penaliza items 8-10)
- Source: inspirado en cloudnative-co/claude-code-starter-kit

### Project tier en audit
- Auto-detect tier por señales: LOC, cantidad de stacks, CI config, monorepo
- `simple` (<5K LOC, 1 stack): items recomendados relajados
- `standard` (5K-50K LOC, 1-2 stacks): current behavior
- `complex` (>50K LOC, 3+ stacks, monorepo): items recomendados pasan a ser obligatorios
- Tier se guarda en registry
- Source: inspirado en tw93/claude-health

### Devcontainer stack
- Nuevo stack `devcontainer`
- Template `.devcontainer/devcontainer.json` con sandbox config
- Rules para comportamiento dentro del container
- Detección: presencia de `.devcontainer/` existente
- Source: inspirado en trailofbits/claude-code-config

---

## v1.4.0 — Distribution & Plugin

Foco: distribución más allá de git clone, empaquetado formal.

### Plugin packaging
- Estructura `claude-kit` como plugin oficial de Claude Code
- `.claude-plugin/plugin.json` con metadata
- Mantener git clone + sync.sh como opción completa
- Plugin = subconjunto curado (hooks + rules + commands, sin skills que requieren el repo completo)
- Evaluar marketplace submission
- Prerequisito: plugin system de Claude Code debe estar estable (monitorear con `/forge watch`)
- Source: practice inbox `2026-03-19-claude-code-plugin-system.md` + NikiforovAll/claude-code-rules

### Stacks como plugins independientes
- Cada stack empaquetable como plugin separado
- `claude-kit-stack-python-fastapi`, `claude-kit-stack-react-vite-ts`, etc.
- Permite adopción granular sin instalar todo claude-kit
- Requiere resolver: cómo componer múltiples stack-plugins en un proyecto

---

## v1.5.0 — Intelligence & Analytics

Foco: insights de sesiones, reporte automático, mejora continua data-driven.

### Session insights: `/forge insights`
- Nuevo skill que analiza sesiones pasadas
- Métricas: tools más usados, archivos más editados, errores frecuentes, patterns de trabajo
- Output: markdown report con recomendaciones
- Alimenta practices pipeline automáticamente (top patterns → inbox)
- Source: inspirado en trailofbits `/insights`

### Session report en Stop hook
- Hook Stop genera `SESSION_REPORT.md` (o append a log)
- Contenido: archivos tocados, tests corridos, errores encontrados, duración estimada
- Formato markdown, no dashboard — respeta filosofía "no app code"
- Configurable: on/off via `FORGE_SESSION_REPORT=true`
- Source: concepto adaptado de davila7/claude-code-templates (dashboard → markdown)

### Scoring trends y alertas
- Registry ya tiene history de scores. Agregar:
- Alerta si score baja >1.5 puntos entre audits
- Trend chart en ASCII (sparkline) en `/forge status`
- Recomendación automática de `/forge sync` si score < 7.0 y hay nueva versión

---

## Backlog (sin versión asignada)

- **MCP server templates**: templates de configuración MCP para servicios comunes (GitHub, Slack, DB)
- **Team mode**: multi-user config con herencia (base → team → individual)
- **CI integration**: GitHub Action que corre `/forge audit` en PRs y comenta el score
- **Stack auto-update**: detectar cambios en dependencias (package.json, pyproject.toml) y sugerir re-sync
- **Práctica: model routing rules**: reglas para cuándo usar sonnet vs opus vs haiku (ya test-runner usa sonnet)

## Descartado

| Idea | Razón |
|------|-------|
| npm/npx distribution | Requiere app code, rompe filosofía md+shell |
| Web UI / dashboard | Fuera de scope, somos terminal-native |
| Model routing automático | Over-engineering para config factory |
| 500+ skills at scale | Calidad > cantidad. 9 skills focalizados es suficiente |
| Real-time analytics | Requiere proceso daemon, contradice "no app code" |
