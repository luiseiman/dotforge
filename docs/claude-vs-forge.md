> **[English](#claude-code-vs-forge--command-comparison)** | **[Español](#claude-code-vs-forge--comparativa-de-comandos)**

# Claude Code vs /forge — Command Comparison

Understanding the relationship between Claude Code's built-in commands and dotforge's `/forge` commands is key to using both effectively. They operate at different layers: Claude Code manages your **active session**, dotforge manages your **configuration as a product**.

```
┌─────────────────────────────────────────────────────┐
│                    Your Project                      │
│                                                      │
│  ┌──────────────────────┐  ┌──────────────────────┐ │
│  │   Claude Code CLI    │  │      dotforge         │ │
│  │   (runtime layer)    │  │  (governance layer)   │ │
│  │                      │  │                       │ │
│  │  /init   /compact    │  │  /forge init          │ │
│  │  /diff   /context    │  │  /forge audit         │ │
│  │  /model  /permissions│  │  /forge sync          │ │
│  │  /plan   /hooks      │  │  /forge export        │ │
│  │  ...                 │  │  ...                  │ │
│  └──────────┬───────────┘  └──────────┬───────────┘ │
│             │    reads/uses            │ generates   │
│             └──────────┐  ┌───────────┘             │
│                        ▼  ▼                          │
│                   .claude/                           │
│              settings.json, rules/,                  │
│              hooks/, commands/, agents/               │
└─────────────────────────────────────────────────────┘
```

## The Two Layers

| Aspect | Claude Code (built-in) | dotforge (/forge) |
|--------|----------------------|-------------------|
| **Purpose** | Operate the current session | Govern configuration across projects |
| **Scope** | One session at a time | All managed projects |
| **Persistence** | Session state, user preferences | Templates, registry, practices |
| **Output** | Actions, responses, tool calls | Configuration files (.claude/) |
| **Updates** | Anthropic releases | `/forge sync`, `/forge update` |

## Direct Overlaps

These commands exist in both systems but serve different purposes:

### `/init` vs `/forge init`

| | Claude Code `/init` | dotforge `/forge init` |
|---|---|---|
| **What it creates** | Minimal `.claude/` scaffold: empty `CLAUDE.md` and basic `settings.json` | Complete configuration: `CLAUDE.md` with build/test commands, `settings.json` with permissions, contextual rules, hooks, commands, agents, error log |
| **Detection** | None — generic scaffold | Auto-detects technology stack (Python, React, Swift, Docker, etc.) and layers matching stack configs |
| **Interactivity** | Minimal prompts | 4 targeted questions about the project |
| **Rules** | None generated | Contextual rules with glob patterns for auto-loading |
| **Hooks** | None | Block-destructive hook, lint-on-save, session management |
| **Agents** | None | 7 specialized subagents with orchestration protocol |
| **Registry** | Not tracked | Registers project in cross-project registry with audit score |
| **When to use** | First time with Claude Code, one-off project | Managing multiple projects, want audit/sync/governance |

### `/diff` vs `/forge diff`

| | Claude Code `/diff` | dotforge `/forge diff` |
|---|---|---|
| **What it shows** | Interactive viewer of uncommitted git changes, per-turn diffs | What changed in the dotforge **template** since your project was last synced |
| **Purpose** | Review code you or Claude wrote | Decide whether running `/forge sync` is worthwhile |
| **Scope** | Current repo, current session | dotforge template vs project config |

### `/insights` vs `/forge insights`

| | Claude Code `/insights` | dotforge `/forge insights` |
|---|---|---|
| **Analyzes** | Interaction patterns, friction points, project areas | Session logs: error patterns, file activity, recurring issues |
| **Output** | Report with interaction metrics | Actionable recommendations + practice suggestions |
| **Action** | Informational | Can feed into practices pipeline via `/forge capture` |

### `/plugin` vs `/forge plugin`

| | Claude Code `/plugin` | dotforge `/forge plugin` |
|---|---|---|
| **Direction** | **Consumes** — manage installed plugins | **Produces** — generate a plugin package from your project's dotforge config |
| **Purpose** | List, enable, disable plugins | Create marketplace-ready plugin with manifest, hooks, rules |

### `/mcp` vs `/forge mcp add`

| | Claude Code `/mcp` | dotforge `/forge mcp add` |
|---|---|---|
| **What** | Manage live MCP server connections, OAuth | Install a pre-configured MCP template (github, postgres, supabase, redis, slack) |
| **Scope** | Session-level connection management | Configuration-level: adds to settings.json with permissions and usage rules |

### `/security-review` vs `/forge audit`

| | Claude Code `/security-review` | dotforge `/forge audit` |
|---|---|---|
| **Reviews** | Code changes for vulnerabilities (injection, auth, data exposure) | Configuration quality: 13-item checklist, 10-point score |
| **Focus** | Application security | Configuration security + completeness |
| **Scoring** | Findings by severity | Numeric score (0-10) with security cap at 6.0 |

## Complementary Commands

Commands that work together across both systems:

| Claude Code provides | dotforge enhances |
|---------------------|-------------------|
| `/hooks` — view hook configurations | `/forge bootstrap` — **generates** those hooks |
| `/permissions` — manage allow/deny rules | Stacks generate **stack-specific** permission rules |
| `/compact` — compress conversation | PostCompact hook preserves state in `last-compact.md` |
| `/context` — show context usage | Rules use `globs:` (eager) vs `paths:` (lazy) to optimize loading |
| `/plan` — enter planning mode | `/forge learn` discovers patterns to inform planning |
| `/agents` — manage agent configs | `agents/` provides 7 pre-built agent definitions with orchestration |
| `/schedule` — create cron jobs | `/forge watch` + `/forge update` automate upstream monitoring |

## Exclusive to Claude Code

These have no dotforge equivalent — they manage the runtime session:

| Command | Category |
|---------|----------|
| `/compact`, `/context`, `/rewind` | Context management |
| `/plan`, `/ultraplan` | Planning mode |
| `/schedule`, `/loop`, `/autofix-pr` | Automation |
| `/resume`, `/branch`, `/teleport` | Session lifecycle |
| `/model`, `/effort`, `/fast` | Model selection |
| `/cost`, `/usage`, `/stats` | Usage metrics |
| `/remote-control`, `/remote-env` | Remote execution |
| `/voice`, `/copy`, `/btw` | Productivity |
| `/doctor`, `/login`, `/logout` | System management |

## Exclusive to dotforge

These have no Claude Code equivalent — they manage configuration governance:

| Command | Category |
|---------|----------|
| `/forge bootstrap` | Full scaffold with profiles and stack detection |
| `/forge sync` | Template sync preserving customizations |
| `/forge reset` | Restore config from template with backup |
| `/forge audit` | 13-item scored configuration audit |
| `/forge rule-check` | Detect and prune inert rules |
| `/forge benchmark` | Compare full vs minimal config performance |
| `/forge capture` / `/cap` | Register practices in improvement pipeline |
| `/forge update` | Process practices: inbox → evaluate → incorporate |
| `/forge learn` | Auto-detect code patterns → domain rules |
| `/forge domain extract/list/sync-vault` | Domain knowledge lifecycle |
| `/forge export cursor/codex/windsurf/openclaw` | Multi-editor config export |
| `/forge scout` | Scan curated repos for config patterns |
| `/forge watch` | Monitor Anthropic upstream changes |
| `/forge status` | Cross-project registry dashboard |
| `/forge global sync/status` | Global `~/.claude/` governance |

## Decision Guide

**Use Claude Code commands when you need to:**
- Manage your current session (context, model, plan)
- Review code changes you just made
- Check usage, costs, and rate limits
- Connect to MCP servers or manage plugins
- Run automated tasks (schedule, loop)

**Use /forge commands when you need to:**
- Set up a new project with complete, stack-aware configuration
- Ensure consistency across multiple projects
- Audit and score configuration quality
- Propagate improvements discovered in one project to others
- Export configuration to other AI editors
- Track configuration health over time

**Use both together for the full workflow:**

```
/forge init          → Generate complete .claude/ config
                       (Claude Code reads it automatically)
... work on project ...
/compact             → Claude Code compresses context
                       (PostCompact hook saves state)
/forge capture       → Register a discovery
/forge audit         → Check configuration health
/forge sync          → Pull latest template improvements
/forge export codex  → Share config with Codex users
```

---

# Claude Code vs /forge — Comparativa de Comandos

Entender la relaci&oacute;n entre los comandos integrados de Claude Code y los comandos `/forge` de dotforge es clave para usar ambos efectivamente. Operan en capas diferentes: Claude Code gestiona tu **sesi&oacute;n activa**, dotforge gestiona tu **configuraci&oacute;n como producto**.

```
┌─────────────────────────────────────────────────────┐
│                    Tu Proyecto                        │
│                                                      │
│  ┌──────────────────────┐  ┌──────────────────────┐ │
│  │   Claude Code CLI    │  │      dotforge         │ │
│  │   (capa runtime)     │  │  (capa gobernanza)    │ │
│  │                      │  │                       │ │
│  │  /init   /compact    │  │  /forge init          │ │
│  │  /diff   /context    │  │  /forge audit         │ │
│  │  /model  /permissions│  │  /forge sync          │ │
│  │  /plan   /hooks      │  │  /forge export        │ │
│  │  ...                 │  │  ...                  │ │
│  └──────────┬───────────┘  └──────────┬───────────┘ │
│             │    lee/usa               │ genera      │
│             └──────────┐  ┌───────────┘             │
│                        ▼  ▼                          │
│                   .claude/                           │
│              settings.json, rules/,                  │
│              hooks/, commands/, agents/               │
└─────────────────────────────────────────────────────┘
```

## Las Dos Capas

| Aspecto | Claude Code (integrado) | dotforge (/forge) |
|---------|------------------------|-------------------|
| **Prop&oacute;sito** | Operar la sesi&oacute;n actual | Gobernar configuraci&oacute;n entre proyectos |
| **Alcance** | Una sesi&oacute;n a la vez | Todos los proyectos gestionados |
| **Persistencia** | Estado de sesi&oacute;n, preferencias | Templates, registry, pr&aacute;cticas |
| **Output** | Acciones, respuestas, tool calls | Archivos de configuraci&oacute;n (.claude/) |
| **Actualizaciones** | Releases de Anthropic | `/forge sync`, `/forge update` |

## Solapamientos Directos

Estos comandos existen en ambos sistemas pero sirven prop&oacute;sitos diferentes:

### `/init` vs `/forge init`

| | Claude Code `/init` | dotforge `/forge init` |
|---|---|---|
| **Qu&eacute; crea** | Scaffold m&iacute;nimo de `.claude/`: `CLAUDE.md` vac&iacute;o y `settings.json` b&aacute;sico | Configuraci&oacute;n completa: `CLAUDE.md` con comandos de build/test, `settings.json` con permisos, reglas contextuales, hooks, commands, agentes, log de errores |
| **Detecci&oacute;n** | Ninguna — scaffold gen&eacute;rico | Auto-detecta stack tecnol&oacute;gico (Python, React, Swift, Docker, etc.) y aplica configs de stacks |
| **Interactividad** | Prompts m&iacute;nimos | 4 preguntas dirigidas sobre el proyecto |
| **Reglas** | Ninguna generada | Reglas contextuales con patrones glob para carga autom&aacute;tica |
| **Hooks** | Ninguno | Hook de bloqueo destructivo, lint al guardar, gesti&oacute;n de sesi&oacute;n |
| **Agentes** | Ninguno | 7 subagentes especializados con protocolo de orquestaci&oacute;n |
| **Registry** | No se trackea | Registra el proyecto en el registry cross-proyecto con score de auditor&iacute;a |
| **Cu&aacute;ndo usarlo** | Primera vez con Claude Code, proyecto &uacute;nico | Gestionando m&uacute;ltiples proyectos, quer&eacute;s audit/sync/gobernanza |

### `/diff` vs `/forge diff`

| | Claude Code `/diff` | dotforge `/forge diff` |
|---|---|---|
| **Qu&eacute; muestra** | Viewer interactivo de cambios git no commiteados, diffs por turno | Qu&eacute; cambi&oacute; en el **template** de dotforge desde la &uacute;ltima sincronizaci&oacute;n |
| **Prop&oacute;sito** | Revisar c&oacute;digo que vos o Claude escribieron | Decidir si vale la pena correr `/forge sync` |
| **Alcance** | Repo actual, sesi&oacute;n actual | Template dotforge vs config del proyecto |

### `/insights` vs `/forge insights`

| | Claude Code `/insights` | dotforge `/forge insights` |
|---|---|---|
| **Analiza** | Patrones de interacci&oacute;n, puntos de fricci&oacute;n, &aacute;reas del proyecto | Logs de sesiones: patrones de error, actividad de archivos, issues recurrentes |
| **Output** | Reporte con m&eacute;tricas de interacci&oacute;n | Recomendaciones accionables + sugerencias de pr&aacute;cticas |
| **Acci&oacute;n** | Informativo | Puede alimentar el pipeline de pr&aacute;cticas v&iacute;a `/forge capture` |

### `/plugin` vs `/forge plugin`

| | Claude Code `/plugin` | dotforge `/forge plugin` |
|---|---|---|
| **Direcci&oacute;n** | **Consume** — gestionar plugins instalados | **Produce** — generar un paquete plugin desde la config dotforge del proyecto |
| **Prop&oacute;sito** | Listar, habilitar, deshabilitar plugins | Crear plugin listo para marketplace con manifiesto, hooks, reglas |

### `/mcp` vs `/forge mcp add`

| | Claude Code `/mcp` | dotforge `/forge mcp add` |
|---|---|---|
| **Qu&eacute;** | Gestionar conexiones MCP activas, OAuth | Instalar un template MCP pre-configurado (github, postgres, supabase, redis, slack) |
| **Alcance** | Gesti&oacute;n de conexiones a nivel sesi&oacute;n | A nivel configuraci&oacute;n: agrega a settings.json con permisos y reglas de uso |

### `/security-review` vs `/forge audit`

| | Claude Code `/security-review` | dotforge `/forge audit` |
|---|---|---|
| **Revisa** | Cambios de c&oacute;digo buscando vulnerabilidades (inyecci&oacute;n, auth, exposici&oacute;n de datos) | Calidad de configuraci&oacute;n: checklist de 13 &iacute;tems, score de 10 puntos |
| **Foco** | Seguridad de la aplicaci&oacute;n | Seguridad de configuraci&oacute;n + completitud |
| **Scoring** | Hallazgos por severidad | Score num&eacute;rico (0-10) con tope de seguridad en 6.0 |

## Comandos Complementarios

Comandos que trabajan juntos entre ambos sistemas:

| Claude Code provee | dotforge complementa |
|--------------------|----------------------|
| `/hooks` — ver configuraci&oacute;n de hooks | `/forge bootstrap` — **genera** esos hooks |
| `/permissions` — gestionar reglas allow/deny | Los stacks generan reglas de permisos **espec&iacute;ficas por stack** |
| `/compact` — comprimir conversaci&oacute;n | Hook PostCompact preserva estado en `last-compact.md` |
| `/context` — ver uso de contexto | Las reglas usan `globs:` (eager) vs `paths:` (lazy) para optimizar carga |
| `/plan` — modo planificaci&oacute;n | `/forge learn` descubre patrones para informar la planificaci&oacute;n |
| `/agents` — gestionar configs de agentes | `agents/` provee 7 definiciones pre-construidas con orquestaci&oacute;n |
| `/schedule` — crear cron jobs | `/forge watch` + `/forge update` automatizan monitoreo upstream |

## Exclusivos de Claude Code

Sin equivalente en dotforge — gestionan la sesi&oacute;n de runtime:

| Comando | Categor&iacute;a |
|---------|-----------|
| `/compact`, `/context`, `/rewind` | Gesti&oacute;n de contexto |
| `/plan`, `/ultraplan` | Modo planificaci&oacute;n |
| `/schedule`, `/loop`, `/autofix-pr` | Automatizaci&oacute;n |
| `/resume`, `/branch`, `/teleport` | Ciclo de vida de sesiones |
| `/model`, `/effort`, `/fast` | Selecci&oacute;n de modelo |
| `/cost`, `/usage`, `/stats` | M&eacute;tricas de uso |
| `/remote-control`, `/remote-env` | Ejecuci&oacute;n remota |
| `/voice`, `/copy`, `/btw` | Productividad |
| `/doctor`, `/login`, `/logout` | Gesti&oacute;n del sistema |

## Exclusivos de dotforge

Sin equivalente en Claude Code — gestionan gobernanza de configuraci&oacute;n:

| Comando | Categor&iacute;a |
|---------|-----------|
| `/forge bootstrap` | Scaffold completo con perfiles y detecci&oacute;n de stack |
| `/forge sync` | Sync de template preservando customizaciones |
| `/forge reset` | Restaurar config desde template con backup |
| `/forge audit` | Auditor&iacute;a de configuraci&oacute;n con score de 13 &iacute;tems |
| `/forge rule-check` | Detectar y podar reglas inertes |
| `/forge benchmark` | Comparar rendimiento config completa vs m&iacute;nima |
| `/forge capture` / `/cap` | Registrar pr&aacute;cticas en pipeline de mejora |
| `/forge update` | Procesar pr&aacute;cticas: inbox → evaluar → incorporar |
| `/forge learn` | Auto-detectar patrones de c&oacute;digo → reglas de dominio |
| `/forge domain extract/list/sync-vault` | Ciclo de vida de conocimiento de dominio |
| `/forge export cursor/codex/windsurf/openclaw` | Export de config multi-editor |
| `/forge scout` | Escanear repos curados buscando patrones de config |
| `/forge watch` | Monitorear cambios upstream de Anthropic |
| `/forge status` | Dashboard de registry cross-proyecto |
| `/forge global sync/status` | Gobernanza global de `~/.claude/` |

## Gu&iacute;a de Decisi&oacute;n

**Us&aacute; comandos de Claude Code cuando necesit&eacute;s:**
- Gestionar tu sesi&oacute;n actual (contexto, modelo, plan)
- Revisar cambios de c&oacute;digo que acabas de hacer
- Consultar uso, costos y rate limits
- Conectarte a servidores MCP o gestionar plugins
- Correr tareas automatizadas (schedule, loop)

**Us&aacute; comandos /forge cuando necesit&eacute;s:**
- Configurar un proyecto nuevo con config completa y stack-aware
- Asegurar consistencia entre m&uacute;ltiples proyectos
- Auditar y puntuar la calidad de configuraci&oacute;n
- Propagar mejoras descubiertas en un proyecto hacia otros
- Exportar configuraci&oacute;n a otros editores AI
- Trackear la salud de configuraci&oacute;n en el tiempo

**Us&aacute; ambos juntos para el workflow completo:**

```
/forge init          → Generar config .claude/ completa
                       (Claude Code la lee autom&aacute;ticamente)
... trabajar en el proyecto ...
/compact             → Claude Code comprime contexto
                       (Hook PostCompact guarda estado)
/forge capture       → Registrar un descubrimiento
/forge audit         → Verificar salud de configuraci&oacute;n
/forge sync          → Traer &uacute;ltimas mejoras del template
/forge export codex  → Compartir config con usuarios de Codex
```
