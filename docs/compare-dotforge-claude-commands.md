# Dotforge vs Claude Code: Comparación de Comandos

Análisis comparativo entre los comandos de `/forge` (dotforge v2.9.0) y los comandos nativos de Claude Code (v2.1.92+).

## Resumen Ejecutivo

| Dimensión | Claude Code | dotforge `/forge` |
|-----------|-------------|-------------------|
| Comandos nativos | ~60 slash commands | 28 subcomandos |
| Enfoque | IDE/CLI general, gestión de sesión y modelo | Gobernanza de configuración Claude Code |
| Implementación | Lógica compilada + skills bundled | Skills basadas en prompts (markdown) |
| Alcance | Sesión individual | Multi-proyecto (registry) |
| Extensibilidad | Plugins, MCP, skills personalizadas | Stacks, skills, prácticas, plugins |

## Categorías Comparativas

### 1. Inicialización y Bootstrap

| Función | Claude Code | dotforge |
|---------|-------------|----------|
| Iniciar proyecto | `/init` — crea `CLAUDE.md` básico | `/forge init` — auto-detecta stacks, 4 preguntas, genera config completa |
| Bootstrap completo | — | `/forge bootstrap [--profile minimal\|standard\|full]` — scaffold `.claude/` desde template + stacks detectados |
| Setup global | — | `/forge global sync` — sincroniza `~/.claude/` (CLAUDE.md, settings, symlinks de skills/agents/commands) |

**Análisis**: Claude Code ofrece `/init` como punto de partida mínimo. Dotforge lo extiende drásticamente: detecta tecnologías, aplica stacks, configura hooks, permisos, y reglas específicas al stack. Es la diferencia entre "crear un README" y "generar una suite de configuración completa".

### 2. Auditoría y Calidad

| Función | Claude Code | dotforge |
|---------|-------------|----------|
| Auditar configuración | — | `/forge audit` — checklist de 12 items, scoring 0-10, ítems de seguridad bloquean score |
| Revisar seguridad | `/security-review` — analiza cambios pendientes por vulnerabilidades | — (seguridad cubierta como parte del audit score) |
| Efectividad de reglas | — | `/forge rule-check` — cruza globs vs git history, clasifica reglas como active/occasional/inert |
| Benchmark | — | `/forge benchmark` — compara config completa vs mínima ejecutando misma tarea en worktrees aislados |
| Insights de sesión | `/insights` — report de sesiones (áreas, fricciones) | `/forge insights` — analiza errores, archivos editados, tendencias de score, alimenta pipeline de prácticas |

**Análisis**: Claude Code tiene `/security-review` e `/insights` como comandos de análisis puntual. Dotforge construye un sistema de auditoría con scoring cuantitativo, tracking histórico, y alertas de degradación — gobernanza continua vs inspección ad-hoc.

### 3. Sincronización y Mantenimiento

| Función | Claude Code | dotforge |
|---------|-------------|----------|
| Sincronizar config | — | `/forge sync` — actualiza config del proyecto contra template + stacks |
| Ver diferencias | `/diff` — diff de git uncommitted | `/forge diff` — compara config actual vs última sincronización dotforge |
| Resetear config | `/clear` — limpia conversación | `/forge reset` — restaura `.claude/` desde template con backup obligatorio |
| Estado global | `/status` — versión, modelo, cuenta | `/forge global status` — estado de `~/.claude/` vs template (CLAUDE.md, settings, skills, agents) |
| Estado de proyectos | — | `/forge status` — registry con scores, tendencias (sparklines), alertas de degradación |

**Análisis**: Comparten la palabra "diff" y "status" pero con significados completamente diferentes. Claude Code opera a nivel de sesión/git; dotforge opera a nivel de configuración multi-proyecto.

### 4. Gestión de Conocimiento

| Función | Claude Code | dotforge |
|---------|-------------|----------|
| Memoria | `/memory` — edita CLAUDE.md, auto-memory | — (gestiona reglas en `.claude/rules/domain/`) |
| Extraer dominio | — | `/forge domain extract` — analiza fuentes existentes, propone domain rules |
| Aprender del código | — | `/forge learn` — escanea código fuente, detecta patrones (ORM, auth, testing), propone reglas |
| Listar dominio | — | `/forge domain list` — estado de reglas de dominio (globs, staleness) |
| Sync con vault | — | `/forge domain sync-vault` — sincroniza reglas con notas de vault externo |
| Capturar práctica | — | `/forge capture "<desc>"` — registra insight en `practices/inbox/` |
| Compactar contexto | `/compact [instructions]` — comprime conversación | — (usa hooks PostCompact del template) |

**Análisis**: Claude Code tiene `/memory` para la memoria básica. Dotforge construye un **sistema de gestión de conocimiento** con extracción de dominio, aprendizaje del código fuente, pipeline de prácticas, y sincronización con vaults externos. Es una de las mayores diferencias arquitectónicas.

### 5. Pipeline de Prácticas

| Función | Claude Code | dotforge |
|---------|-------------|----------|
| Inbox de prácticas | — | `/forge inbox` — lista prácticas pendientes |
| Procesar prácticas | — | `/forge update` — pipeline: inbox → evaluating → active → deprecated |
| Ver pipeline | — | `/forge pipeline` — estado del lifecycle completo |
| Vigilar upstream | — | `/forge watch` — busca actualizaciones en docs oficiales de Anthropic |
| Explorar repos | — | `/forge scout` — revisa repos curados, compara contra template |

**Análisis**: Sin equivalente en Claude Code. Es un sistema completo de inteligencia competitiva y mejora continua: detectar prácticas → evaluar → incorporar al template → deprecar las obsoletas.

### 6. Exportación e Interoperabilidad

| Función | Claude Code | dotforge |
|---------|-------------|----------|
| Exportar conversación | `/export [filename]` — texto plano | — |
| Exportar config | — | `/forge export <cursor\|codex\|windsurf\|openclaw>` — config portable a otras herramientas |
| Generar plugin | — | `/forge plugin [dir]` — genera paquete de plugin Claude Code desde la config del proyecto |
| Gestionar MCP | `/mcp` — conexiones MCP y OAuth | `/forge mcp add <server> [--global]` — instala templates MCP predefinidos (github, postgres, supabase, redis, slack) |

**Análisis**: Claude Code exporta conversaciones; dotforge exporta **configuración** a herramientas competidoras. El generador de plugins convierte config en paquetes distribuibles. Para MCP, Claude Code gestiona conexiones existentes; dotforge pre-empaqueta configuraciones de servidores comunes.

### 7. Gestión de Sesión y Modelo (Solo Claude Code)

| Comando | Función |
|---------|---------|
| `/model [model]` | Cambiar modelo (Opus, Sonnet, Haiku) |
| `/effort [level]` | Nivel de esfuerzo del modelo |
| `/fast [on\|off]` | Modo rápido |
| `/resume [session]` | Reanudar sesión anterior |
| `/rewind` | Retroceder a checkpoint anterior |
| `/branch [name]` | Fork de conversación |
| `/compact [instructions]` | Compactar contexto |
| `/cost` | Estadísticas de tokens |
| `/usage` | Límites del plan y rate limits |
| `/context` | Visualizar uso de contexto |
| `/stats` | Uso diario, streaks, historial |
| `/voice` | Dictado por voz |

**Análisis**: Dotforge no replica estos comandos — son funcionalidad core del runtime de Claude Code. Dotforge **configura** cómo se comporta el runtime, pero no lo controla directamente durante la sesión.

### 8. Infraestructura y Permisos (Solo Claude Code)

| Comando | Función |
|---------|---------|
| `/permissions` | Gestionar reglas allow/deny/ask |
| `/hooks` | Ver configuración de hooks |
| `/config` | Configuración general (tema, modelo, editor) |
| `/doctor` | Diagnóstico de instalación |
| `/login` / `/logout` | Autenticación |
| `/sandbox` | Modo sandbox |
| `/plan [desc]` | Modo read-only |
| `/plugin` | Gestionar plugins |
| `/skills` | Listar skills disponibles |

**Análisis**: Claude Code expone la gestión de su propia infraestructura. Dotforge **genera** la configuración que estos comandos luego leen (settings.json, hooks, reglas de permisos).

### 9. Automatización y CI (Solo Claude Code)

| Comando | Función |
|---------|---------|
| `/batch <instruction>` | Cambios masivos en paralelo con worktrees aislados |
| `/autofix-pr [prompt]` | Watch + autofix de PR (CI + reviews) |
| `/schedule [desc]` | Tareas programadas en la nube |
| `/loop [interval] <prompt>` | Ejecutar prompt recurrente |
| `/tasks` | Gestionar tareas en background |

**Análisis**: Estos son comandos de ejecución activa que dotforge no replica. Dotforge podría **configurar** los hooks y reglas que afectan cómo se comportan, pero la ejecución es del runtime.

### 10. Registry Multi-Proyecto (Solo dotforge)

| Comando | Función |
|---------|---------|
| `/forge status` | Vista de todos los proyectos con scores, tendencias, alertas |
| `/forge unregister <name>` | Eliminar proyecto del tracking |

**Análisis**: Sin equivalente en Claude Code. Cada sesión de Claude Code opera en un proyecto aislado. Dotforge introduce un **registry centralizado** que trackea scores, versiones, y tendencias a través de múltiples proyectos.

## Mapa de Solapamientos y Complementos

```
┌─────────────────────────────────────────────────────────────────┐
│                    SOLO CLAUDE CODE                             │
│  Sesión: /clear /compact /resume /rewind /branch /export       │
│  Modelo: /model /effort /fast /voice                           │
│  Runtime: /permissions /hooks /config /doctor /sandbox          │
│  Auto: /batch /autofix-pr /schedule /loop /tasks               │
│  Social: /stickers /passes /mobile /desktop                    │
├─────────────────────────────────────────────────────────────────┤
│                    ZONA DE COMPLEMENTO                          │
│                                                                 │
│  CC: /init          ←→  DF: /forge init, /forge bootstrap      │
│  CC: /diff          ←→  DF: /forge diff                        │
│  CC: /status        ←→  DF: /forge status                      │
│  CC: /insights      ←→  DF: /forge insights                    │
│  CC: /memory        ←→  DF: /forge domain *, /forge learn      │
│  CC: /mcp           ←→  DF: /forge mcp add                    │
│  CC: /plugin        ←→  DF: /forge plugin                      │
│  CC: /security-rev  ←→  DF: /forge audit                       │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    SOLO DOTFORGE                                │
│  Config: /forge sync, /forge reset, /forge bootstrap           │
│  Calidad: /forge audit, /forge rule-check, /forge benchmark    │
│  Conocimiento: /forge domain *, /forge learn, /forge capture   │
│  Prácticas: /forge inbox, /forge update, /forge pipeline       │
│  Intel: /forge watch, /forge scout                             │
│  Export: /forge export <target>                                 │
│  Registry: /forge status (multi-proyecto), /forge unregister   │
│  Global: /forge global sync, /forge global status              │
└─────────────────────────────────────────────────────────────────┘
```

## Relación Arquitectónica

```
┌──────────────────────────────────────────┐
│           Claude Code Runtime            │
│  (sesión, modelo, permisos, ejecución)   │
│                                          │
│   Lee config de:                         │
│   ├── CLAUDE.md                          │
│   ├── .claude/settings.json       ◄──────┼──── dotforge genera
│   ├── .claude/rules/**            ◄──────┼──── dotforge genera
│   ├── .claude/hooks/**            ◄──────┼──── dotforge genera
│   └── ~/.claude/ (global)         ◄──────┼──── /forge global sync
│                                          │
│   Ejecuta:                               │
│   ├── /forge (skill instalada)    ◄──────┼──── dotforge provee
│   ├── agents/ (definiciones)      ◄──────┼──── dotforge provee
│   └── skills/ (definiciones)      ◄──────┼──── dotforge provee
└──────────────────────────────────────────┘
```

**Claude Code** es el **runtime** — ejecuta, gestiona sesiones, controla modelos, aplica permisos.

**dotforge** es la **fábrica de configuración** — genera, audita, sincroniza, y evoluciona la configuración que Claude Code consume.

No compiten: se complementan en capas distintas. dotforge necesita a Claude Code para existir; Claude Code funciona sin dotforge pero con configuración manual.

## Conteo Final

| Categoría | Claude Code | dotforge | Compartidas (complemento) |
|-----------|:-----------:|:--------:|:-------------------------:|
| Inicialización | 1 | 3 | 1 (`init`) |
| Auditoría/Calidad | 2 | 4 | 1 (`insights`) |
| Sincronización | 1 | 4 | 0 |
| Conocimiento | 1 | 5 | 1 (`memory`↔`domain`) |
| Prácticas | 0 | 5 | 0 |
| Export/Interop | 1 | 3 | 1 (`mcp`) |
| Sesión/Modelo | 12 | 0 | 0 |
| Infraestructura | 9 | 2 | 1 (`plugin`) |
| Automatización/CI | 5 | 0 | 0 |
| Registry | 0 | 2 | 0 |
| Social/UX | 10+ | 0 | 0 |
| **Total únicos** | **~42** | **~24** | **5 complementarios** |
