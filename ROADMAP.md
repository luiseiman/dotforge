# Roadmap claude-kit

Estado actual: **v2.5.0** (2026-03-21)

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

## v2.6.0 — CI/CD + Ecosystem automation (próximo)

Foco: integración con flujos de trabajo de PR y detección automática de cambios de stack.

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

---

## Backlog (válido, sin fecha)

| Item | Por qué no ahora |
|------|-----------------|
| Stacks como plugins independientes | Marketplace de Claude Code sin spec estable. Re-evaluar cuando `/forge watch` detecte release oficial. |
| Team mode (`.claude/team.json`) | Fuera de scope para uso personal. Desbloquear si hay 3+ usuarios en el mismo proyecto con configs distintas. |
| CI GitLab template | El usuario usa GitHub. Añadir si hay demanda concreta. |
| Stop hook B2 (análisis via Claude API) | Evaluar después de medir cobertura de A1+A2+A3. Solo implementar si el inbox sigue subpoblado. |

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
