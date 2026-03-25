# Roadmap claude-kit

Estado actual: **v2.6.1** (2026-03-24)

---

## v2.5.0 — Completado

- `/forge capture` sin args: auto-detección de contexto de sesión, propone insight pre-formateado, pide confirmación Y/n/edit antes de guardar
- `/cap`: alias shorthand para `/forge capture` — 4 chars vs 14
- Regla proactiva de captura en `template/rules/_common.md`: Claude sugiere `/cap` al detectar workaround, bug multi-intento, decisión con trade-offs, o comportamiento no-obvio
- MCP server templates en `mcp/`: github, postgres, supabase, redis, slack — cada uno con config.json, permissions.json, rules.md
- `template/rules/model-routing.md`: criterios explícitos para haiku/sonnet/opus por tipo de tarea
- 7 agents actualizados con modelo explícito (researcher/test-runner=haiku, implementer/code-reviewer/session-reviewer=sonnet, architect/security-auditor=opus)

---

## v2.4.0 — Completado

- `/forge init`: quick-start con 3 preguntas, detección de idioma automática
- `/forge global sync`: auto-pull de claude-kit + resync `~/.claude/` en un paso
- `/forge unregister`: remover proyectos del registry
- Plugin marketplace structure (`.claude-plugin/`)
- OpenClaw integration completa (`/forge export openclaw`)
- 16 stacks tecnológicos (hookify, trading, devcontainer incluidos)
- 15 skills, 7 agents, 17 subcomandos `/forge`
- Hook profiles: `FORGE_HOOK_PROFILE` minimal/standard/strict en `block-destructive.sh`
- TDD warning hook (`warn-missing-test.sh`, solo perfil strict)
- Session report hook (`session-report.sh`) con métricas JSON en `~/.claude/metrics/`
- Project tier en audit: simple / standard / complex
- Bootstrap profiles: minimal / standard / full
- Prompt injection scan como item 12 del checklist de auditoría
- Error Type column en CLAUDE_ERRORS.md (syntax/logic/integration/config/security)
- Git worktree isolation para Agent Teams (isolation: "worktree" en agents.md)
- CI: validación automática de hooks, YAML, frontmatter, stacks y skills en PRs

---

## v2.6.0 — CI/CD + MCP UX + Quality fixes (próximo)

Foco: integración con flujos de trabajo de PR, UX de MCP, y correcciones de calidad.

### CI: `/forge audit` score en PRs

- Script shell standalone `audit/score.sh` que computa los 12 checks mecánicos sin depender de Claude
- GitHub Action que corre `audit/score.sh` en PRs y comenta el score como review comment
- Configurable: threshold mínimo (default 7.0), bloquea merge si score < threshold
- Badge dinámico para README
- Prerequisito bloqueante: `audit/score.sh` como nuevo artefacto
- Nota: checks semánticos (calidad de CLAUDE.md) se aproximan con heurísticas — score es indicativo, no idéntico al skill

### Stack auto-update detection

- PostToolUse hook `detect-stack-drift.sh` sobre eventos `Write`
- Monitorea: `package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`
- Si se detecta dependencia nueva con stack disponible en claude-kit no instalado → warning + sugerencia de `/forge sync`
- Warning only (exit 0) — nunca bloquea
- Sinergia con MCP templates: si la dependencia implica un MCP server, sugiere el template también

### `/forge mcp add <server>`

- Nuevo comando que toma un nombre de server (`github`, `postgres`, `supabase`, `redis`, `slack`)
- Lee `mcp/<server>/config.json` + `permissions.json` y mergea automáticamente en `.claude/settings.json` del proyecto
- Confirma antes de escribir, muestra diff de lo que se va a agregar
- Output: `✓ GitHub MCP configurado. Seteá GITHUB_TOKEN y reiniciá Claude Code.`
- Reduce el flujo de 4 pasos manuales a 1 comando

### MCP version pinning + update script

- Pinear todas las versiones de MCP templates a exactas (eliminado el uso de rangos semver)
- Nuevo script `mcp/update-versions.sh` que consulta `npm view <package> version` y actualiza `config.json`
- Instrucción en CONTRIBUTING.md de correr el script antes de cada release

### Quality fixes (incluidos en este release)

- `TodoWrite` en `template/rules/agents.md`: guidance explícita de uso para tasks >3 pasos
- Model IDs explícitos en `template/rules/model-routing.md`: tabla de IDs actuales (haiku-4-5, sonnet-4-6, opus-4-6)
- Stop hook en `template/settings.json.tmpl`: wirear `session-report.sh` en perfil standard y full

---

## v2.7.0 — LLM Stack + Developer Experience (planificado)

Foco: soporte para proyectos LLM, diagnóstico de entorno, y context management mejorado.

### Stack `llm-python`

- Stack para proyectos Python que usan LLM APIs (anthropic, openai, langchain, litellm)
- `rules/llm-python.md`: manejo de API keys, retry con backoff, nunca loggear `content` de messages, costeo explícito antes de batch ops, prompt versioning
- `settings.json.partial`: deny `Read(**/.anthropic*)`, deny `Read(**/.openai*)`, allow operaciones de Python LLM
- Auto-detección: si `pyproject.toml` o `requirements.txt` contiene `anthropic`, `openai`, o `litellm`

### `/forge doctor`

- Diagnóstico completo del entorno de desarrollo:
  1. `$CLAUDE_KIT_DIR` seteada y apunta a repo claude-kit válido
  2. `~/.claude/` sincronizado (hash de skills instalados vs repo)
  3. Hooks del proyecto: ejecutables (`-rwxr-xr-x`), bash syntax válida
  4. Variables de entorno de MCPs configuradas (si el proyecto usa MCPs)
  5. `claude` CLI en PATH
- Output: semáforo verde/amarillo/rojo por item + fix sugerido para cada rojo
- Diferente de `/forge audit`: verifica el entorno, no la config del proyecto

### MCP templates: `filesystem` + `brave-search`

- `mcp/filesystem/`: config con paths permitidos, permissions.json con deny para `~/.ssh`, `~/.aws`, `~/.config`
- `mcp/brave-search/`: config con `BRAVE_API_KEY`, permissions.json read-only

### `includedFiles` en settings template

- Agregar sección `includedFiles` a `template/settings.json.tmpl` con `CLAUDE_ERRORS.md` pre-configurado
- Documentar jerarquía en `docs/memory-strategy.md`: auto-memory → agent-memory → CLAUDE_ERRORS → includedFiles → CLAUDE.md

### Capture skill: manejo de context compaction

- En Step 0 de `skills/capture-practice/SKILL.md`, detectar si el contexto fue compactado
- Advertencia: "⚠ Context was compacted. Signals from early session may be incomplete."
- Sugerencia de fallback: "If you remember a specific insight from before compaction, run `/cap 'description'`."

---

## Backlog (válido, sin fecha)

| Item | Por qué no ahora |
|------|-----------------|
| Stacks como plugins independientes | Marketplace de Claude Code sin spec estable. Re-evaluar cuando `/forge watch` detecte release oficial. |
| Team mode (`.claude/team.json`) | Fuera de scope para uso personal. Desbloquear si hay 3+ usuarios en el mismo proyecto con configs distintas. |
| CI GitLab template | El usuario usa GitHub. Añadir si hay demanda concreta. |
| Stop hook B2 (análisis via Claude API) | Evaluar en v2.7.0 después de medir cobertura de session-report. Solo implementar si inbox sigue subpoblado. |

---

## Descartado

| Idea | Razón |
|------|-------|
| npm/npx distribution | Requiere app code, rompe filosofía md+shell |
| Web UI / dashboard | Fuera de scope, terminal-native |
| Real-time analytics | Requiere daemon, contradice "no app code" |
| Stop hook B1 (grep-based) | Genera ruido sin semántica — no vale el esfuerzo |
| 500+ skills at scale | Calidad > cantidad. Skills focalizados son suficientes. |
| Model routing automático en runtime | Over-engineering — las reglas explícitas son más predecibles |
| Auto-escalation de modelo por token count | Over-engineering — routing por tipo de tarea, no por tamaño |
| MCP server self-hosting templates | Fuera de scope — claude-kit configura clientes, no servers |
| `/forge export cursor\|windsurf` | Dependencia de specs de terceros inestables. Re-evaluar si alguno estabiliza su formato de config |
