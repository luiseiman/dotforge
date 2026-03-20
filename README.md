> **[English](#claude-kit)** | **[Español](#claude-kit-español)**

# claude-kit

[![GitHub stars](https://img.shields.io/github/stars/luiseiman/claude-kit)](https://github.com/luiseiman/claude-kit/stargazers)
[![License: MIT](https://img.shields.io/github/license/luiseiman/claude-kit)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue)](VERSION)
[![Last commit](https://img.shields.io/github/last-commit/luiseiman/claude-kit)](https://github.com/luiseiman/claude-kit/commits/main)

Configuration factory for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Templates, stacks, skills, agents, audit system, and a practices pipeline — all markdown + shell scripts.

Bootstrap any project with a complete `.claude/` setup in seconds. Audit it. Keep it in sync as claude-kit evolves.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/luiseiman/claude-kit.git
cd claude-kit

# 2. Install globally (symlinks skills, agents, commands into ~/.claude/)
export CLAUDE_KIT_DIR="$(pwd)"
./global/sync.sh

# 3. In any project directory:
/forge bootstrap    # Initialize .claude/ with full config
/forge audit        # Audit configuration and get a score (0-10)
/forge sync         # Update against current template
```

> **New here?** Read the **[Usage Guide](docs/usage-guide.md)** for a complete walkthrough with examples.

## Why claude-kit

There are many Claude Code starter kits, skills collections, and CLAUDE.md generators. claude-kit is different because it's the only **end-to-end configuration management system** — not a one-shot bootstrap or a static collection.

### What makes it unique

| Feature | What it means | Who else does this |
|---------|---------------|-------------------|
| **Additive stack layering** | Auto-detects your tech (13 stacks) and merges matching configs on top of a base template. Multi-stack projects get all layers combined. | No one — closest is project-type scanning, but without composable layering |
| **Template sync with markers** | `<!-- forge:section -->` separates managed sections from your customizations. `/forge sync` updates the managed parts without touching yours. | No one |
| **Audit scoring (0-10)** | 12-item checklist (5 obligatory scored 0-2, 7 recommended scored 0-1), normalized to 10. Security-critical items cap the score at 6.0 if missing. Project tier (simple/standard/complex) adjusts expectations. | tw93/claude-health has tiers but no numeric normalization or security cap |
| **Practices pipeline** | Continuous improvement lifecycle: `inbox/ → evaluating/ → active/ → deprecated/`. Practices arrive from capture, web watch, repo scouting, audit gaps, or post-session hooks. | No one |
| **Cross-project registry** | `registry/projects.yml` tracks audit scores with history across all managed projects. Spot regressions, compare configurations. | No one |
| **Global config via symlinks** | `global/sync.sh` installs skills, agents, and commands as symlinks into `~/.claude/`. One source of truth, instant propagation. | No one with this symlink-based approach |

### How it compares

- **Skills collections** (superpowers, claude-skills) give you components — claude-kit gives you the system that manages them
- **Starter kits** (claude-bootstrap, claude-starter-kit) bootstrap once — claude-kit bootstraps, syncs, audits, and evolves
- **CLAUDE.md generators** generate one file — claude-kit generates and maintains the entire `.claude/` directory
- **Audit tools** (claude-health) check once — claude-kit checks, scores, tracks over time, and feeds gaps back into the practices pipeline

## What it does

`/forge bootstrap` detects your project's tech stack and generates:

- **CLAUDE.md** — project instructions with build/test commands
- **.claude/settings.json** — permissions (allow/deny), hooks
- **.claude/rules/** — contextual rules auto-loaded by glob patterns
- **.claude/hooks/** — block destructive commands, lint on save
- **.claude/commands/** — audit, debug, health, review
- **.claude/agents/** — 6 specialized subagents with orchestration
- **CLAUDE_ERRORS.md** — error log for cross-session learning

Multi-stack projects get all matching stack configs merged automatically.

## Architecture

```
claude-kit/
├── template/       # Base scaffold (CLAUDE.md.tmpl, settings, hooks, rules, commands)
├── stacks/         # Technology modules (13 stacks, additive)
├── agents/         # 6 subagents (researcher, architect, implementer, ...)
├── skills/         # 13 skills installed as ~/.claude/skills/ symlinks
├── audit/          # Checklist (12 items) + scoring normalized to 10
├── practices/      # Pipeline: inbox → evaluating → active → deprecated
├── global/         # Global ~/.claude/ management (CLAUDE.md, settings, sync.sh)
├── registry/       # Project tracking with scores and history
├── hooks/          # Global post-session change detection hook
├── docs/           # Guides, patterns, security checklist
└── tests/          # Hook test suite
```

## Stacks

Each stack provides contextual rules, permissions, and optional hooks. Stacks are auto-detected and additive.

| Stack | Detects | Rules |
|-------|---------|-------|
| **python-fastapi** | `pyproject.toml`, `requirements.txt` | backend.md, tests.md |
| **react-vite-ts** | `package.json` with react/vite | frontend.md |
| **swift-swiftui** | `Package.swift`, `*.xcodeproj` | ios.md |
| **supabase** | `supabase/`, `@supabase/supabase-js` | database.md |
| **docker-deploy** | `Dockerfile`, `docker-compose*` | infra.md |
| **data-analysis** | `*.ipynb`, `*.csv`, `*.xlsx` | data.md |
| **gcp-cloud-run** | `app.yaml`, `cloudbuild.yaml` | gcp.md |
| **redis** | `redis` in dependencies | redis.md |
| **node-express** | `package.json` with express/fastify | backend.md |
| **java-spring** | `pom.xml`, `build.gradle`, Spring | backend.md |
| **aws-deploy** | `cdk.json`, `template.yaml` (SAM) | aws.md |
| **go-api** | `go.mod`, `*.go` | backend.md |
| **devcontainer** | `.devcontainer/` | devcontainer.md |

Creating a new stack: see [docs/creating-stacks.md](docs/creating-stacks.md).

## Skills

All skills are invoked through the `/forge` command:

| Command | What it does |
|---------|-------------|
| `/forge bootstrap` | Initialize `.claude/` in a new project |
| `/forge sync` | Update config against current template (merge, not overwrite) |
| `/forge audit` | Audit configuration + calculate score (0-10) |
| `/forge diff` | Show what changed in claude-kit since last sync |
| `/forge reset` | Restore `.claude/` from template with backup |
| `/forge capture` | Register a practice in `practices/inbox/` |
| `/forge update` | Process practices: inbox → evaluate → incorporate |
| `/forge watch` | Search for upstream changes in Anthropic docs |
| `/forge scout` | Review curated repos for useful patterns |
| `/forge export` | Export config to Cursor, Codex, Windsurf, or OpenClaw format |
| `/forge insights` | Analyze sessions for patterns and recommendations |
| `/forge rule-check` | Detect inert rules by cross-referencing globs against git history |
| `/forge benchmark` | Compare full config vs minimal config on standardized tasks |
| `/forge global sync` | Sync global `~/.claude/` config |
| `/forge global status` | Show global config status |

## Agents

Six specialized subagents, deployed to every bootstrapped project:

| Agent | Role | Memory |
|-------|------|--------|
| **researcher** | Read-only codebase exploration | transactional |
| **architect** | Design decisions, tradeoff analysis | persistent |
| **implementer** | Code + tests | persistent |
| **code-reviewer** | Review by severity (critical/warning/suggestion) | persistent |
| **security-auditor** | Vulnerability scanning | persistent |
| **test-runner** | Run tests + report coverage | transactional |

Orchestration follows a decision tree: researcher → architect → implementer → test-runner → code-reviewer. See [agents/](agents/) for definitions.

## Audit System

`/forge audit` scores your project's Claude Code configuration on a 10-point scale:

- **5 obligatory items** (scored 0-2): settings.json, block-destructive hook, CLAUDE.md, rules, deny list
- **7 recommended items** (scored 0-1): lint hook, commands, error log, agents, manifest, global hook, prompt injection scan
- **Project tier**: simple/standard/complex adjusts scoring expectations
- **Security cap**: missing settings.json or block-destructive hook caps score at 6.0

Scores are tracked in `registry/projects.yml` with history for trending over time.

## Practices Pipeline

A continuous improvement system for discovering and incorporating Claude Code configuration patterns:

```
inbox/ → evaluating/ → active/ → deprecated/
```

Practices arrive from: `/forge capture` (manual), `/forge update` (web search), `/forge watch` (upstream docs), `/forge scout` (curated repos), audit gaps, or post-session hooks.

See [practices/README.md](practices/README.md) for the lifecycle and format.

## Documentation

- **[Usage Guide](docs/usage-guide.md)** — Complete step-by-step guide: install, bootstrap, sync, audit, practices ([Español](docs/guia-uso.md))
- [Best Practices](docs/best-practices.md) — Claude Code configuration patterns
- [Security Checklist](docs/security-checklist.md) — 62 items for pre-deploy review
- [Prompting Patterns](docs/prompting-patterns.md) — 10 reproducible patterns
- [Creating Stacks](docs/creating-stacks.md) — How to add a new technology stack
- [Anatomy of CLAUDE.md](docs/anatomy-claude-md.md) — Deep dive into project instructions
- [Memory Strategy](docs/memory-strategy.md) — 5-layer memory policy for agents
- [Troubleshooting](docs/troubleshooting.md) — Common problems and diagnostics
- [Changelog](docs/changelog.md) — Version history (v0.1.0 → v2.0.0)
- [Roadmap](ROADMAP.md) — Development history (v1.0.0 → v2.0.0)

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `bash` (hooks are shell scripts)
- `python3` with `pyyaml` (for registry validation, optional)

## Configuration

claude-kit uses a single environment variable:

```bash
export CLAUDE_KIT_DIR="/path/to/claude-kit"
```

This is set automatically by `global/sync.sh`. All skills and hooks resolve paths through this variable.

## License

[MIT](LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

# claude-kit (Español)

Fábrica de configuración para [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Plantillas, stacks, skills, agentes, sistema de auditoría y un pipeline de prácticas — todo en markdown + shell scripts.

Inicializá cualquier proyecto con una configuración `.claude/` completa en segundos. Auditalo. Mantenelo sincronizado a medida que claude-kit evoluciona.

## Inicio Rápido

```bash
# 1. Clonar
git clone https://github.com/luiseiman/claude-kit.git
cd claude-kit

# 2. Instalar globalmente (crea symlinks de skills, agentes y comandos en ~/.claude/)
export CLAUDE_KIT_DIR="$(pwd)"
./global/sync.sh

# 3. En cualquier directorio de proyecto:
/forge bootstrap    # Inicializar .claude/ con configuración completa
/forge audit        # Auditar la configuración y obtener un puntaje (0-10)
/forge sync         # Actualizar contra la plantilla actual
```

> **Primera vez?** Leé la **[Guía de Uso](docs/guia-uso.md)** para un walkthrough completo con ejemplos.

## Por qué claude-kit

Hay muchos starter kits, colecciones de skills y generadores de CLAUDE.md para Claude Code. claude-kit es diferente porque es el único **sistema de gestión de configuración end-to-end** — no un bootstrap one-shot ni una colección estática.

### Qué lo hace único

| Feature | Qué significa | Quién más lo hace |
|---------|---------------|-------------------|
| **Stack layering aditivo** | Auto-detecta tu tech (13 stacks) y mergea configs coincidentes sobre una plantilla base. Proyectos multi-stack reciben todas las capas combinadas. | Nadie — lo más cercano es detección de tipo de proyecto, pero sin layering composable |
| **Template sync con markers** | `<!-- forge:section -->` separa secciones gestionadas de tus customizaciones. `/forge sync` actualiza lo gestionado sin tocar lo tuyo. | Nadie |
| **Audit scoring (0-10)** | Checklist de 12 ítems (5 obligatorios 0-2, 7 recomendados 0-1), normalizado a 10. Ítems críticos de seguridad capean el score a 6.0 si faltan. Tier de proyecto (simple/standard/complex) ajusta expectations. | tw93/claude-health tiene tiers pero sin normalización numérica ni security cap |
| **Pipeline de prácticas** | Ciclo de mejora continua: `inbox/ → evaluating/ → active/ → deprecated/`. Las prácticas llegan desde capture, web watch, repo scouting, audit gaps, o hooks post-sesión. | Nadie |
| **Registry cross-proyecto** | `registry/projects.yml` trackea audit scores con historial en todos los proyectos gestionados. Detectá regresiones, compará configuraciones. | Nadie |
| **Config global via symlinks** | `global/sync.sh` instala skills, agentes y commands como symlinks en `~/.claude/`. Una sola fuente de verdad, propagación instantánea. | Nadie con este enfoque basado en symlinks |

### Cómo se compara

- **Colecciones de skills** (superpowers, claude-skills) te dan componentes — claude-kit te da el sistema que los gestiona
- **Starter kits** (claude-bootstrap, claude-starter-kit) bootstrapean una vez — claude-kit bootstrapea, sincroniza, audita y evoluciona
- **Generadores de CLAUDE.md** generan un archivo — claude-kit genera y mantiene todo el directorio `.claude/`
- **Herramientas de auditoría** (claude-health) revisan una vez — claude-kit revisa, puntúa, trackea en el tiempo y alimenta los gaps al pipeline de prácticas

## Qué hace

`/forge bootstrap` detecta el stack tecnológico de tu proyecto y genera:

- **CLAUDE.md** — instrucciones del proyecto con comandos de build/test
- **.claude/settings.json** — permisos (allow/deny), hooks
- **.claude/rules/** — reglas contextuales cargadas automáticamente por patrones glob
- **.claude/hooks/** — bloqueo de comandos destructivos, lint al guardar
- **.claude/commands/** — auditoría, debug, salud, revisión
- **.claude/agents/** — 6 subagentes especializados con orquestación
- **CLAUDE_ERRORS.md** — registro de errores para aprendizaje entre sesiones

Los proyectos multi-stack reciben todas las configuraciones de stacks coincidentes fusionadas automáticamente.

## Arquitectura

```
claude-kit/
├── template/       # Scaffold base (CLAUDE.md.tmpl, settings, hooks, rules, commands)
├── stacks/         # Módulos tecnológicos (13 stacks, aditivos)
├── agents/         # 6 subagentes (researcher, architect, implementer, ...)
├── skills/         # 13 skills instalados como symlinks en ~/.claude/skills/
├── audit/          # Checklist (12 ítems) + puntaje normalizado a 10
├── practices/      # Pipeline: inbox → evaluating → active → deprecated
├── global/         # Gestión global de ~/.claude/ (CLAUDE.md, settings, sync.sh)
├── registry/       # Seguimiento de proyectos con puntajes e historial
├── hooks/          # Hook global post-sesión para detección de cambios
├── docs/           # Guías, patrones, checklist de seguridad
└── tests/          # Suite de tests para hooks
```

## Stacks

Cada stack provee reglas contextuales, permisos y hooks opcionales. Los stacks se auto-detectan y son aditivos.

| Stack | Detecta | Reglas |
|-------|---------|--------|
| **python-fastapi** | `pyproject.toml`, `requirements.txt` | backend.md, tests.md |
| **react-vite-ts** | `package.json` con react/vite | frontend.md |
| **swift-swiftui** | `Package.swift`, `*.xcodeproj` | ios.md |
| **supabase** | `supabase/`, `@supabase/supabase-js` | database.md |
| **docker-deploy** | `Dockerfile`, `docker-compose*` | infra.md |
| **data-analysis** | `*.ipynb`, `*.csv`, `*.xlsx` | data.md |
| **gcp-cloud-run** | `app.yaml`, `cloudbuild.yaml` | gcp.md |
| **redis** | `redis` en dependencias | redis.md |
| **node-express** | `package.json` con express/fastify | backend.md |
| **java-spring** | `pom.xml`, `build.gradle`, Spring | backend.md |
| **aws-deploy** | `cdk.json`, `template.yaml` (SAM) | aws.md |
| **go-api** | `go.mod`, `*.go` | backend.md |
| **devcontainer** | `.devcontainer/` | devcontainer.md |

Para crear un nuevo stack: ver [docs/creating-stacks.md](docs/creating-stacks.md).

## Skills

Todos los skills se invocan a través del comando `/forge`:

| Comando | Qué hace |
|---------|----------|
| `/forge bootstrap` | Inicializar `.claude/` en un proyecto nuevo |
| `/forge sync` | Actualizar configuración contra la plantilla actual (merge, no sobreescritura) |
| `/forge audit` | Auditar configuración + calcular puntaje (0-10) |
| `/forge diff` | Mostrar qué cambió en claude-kit desde la última sincronización |
| `/forge reset` | Restaurar `.claude/` desde la plantilla con backup |
| `/forge capture` | Registrar una práctica en `practices/inbox/` |
| `/forge update` | Procesar prácticas: inbox → evaluar → incorporar |
| `/forge watch` | Buscar cambios upstream en la documentación de Anthropic |
| `/forge scout` | Revisar repos curados en busca de patrones útiles |
| `/forge export` | Exportar config a formato Cursor, Codex, Windsurf u OpenClaw |
| `/forge insights` | Analizar sesiones para patrones y recomendaciones |
| `/forge rule-check` | Detectar reglas inertes cruzando globs contra historial de git |
| `/forge benchmark` | Comparar config completa vs minimal en tareas estandarizadas |
| `/forge global sync` | Sincronizar configuración global de `~/.claude/` |
| `/forge global status` | Mostrar estado de la configuración global |

## Agentes

Seis subagentes especializados, desplegados en cada proyecto inicializado:

| Agente | Rol | Memoria |
|--------|-----|---------|
| **researcher** | Exploración de código (solo lectura) | transaccional |
| **architect** | Decisiones de diseño, análisis de tradeoffs | persistente |
| **implementer** | Código + tests | persistente |
| **code-reviewer** | Revisión por severidad (crítico/advertencia/sugerencia) | persistente |
| **security-auditor** | Escaneo de vulnerabilidades | persistente |
| **test-runner** | Ejecución de tests + reporte de cobertura | transaccional |

La orquestación sigue un árbol de decisión: researcher → architect → implementer → test-runner → code-reviewer. Ver [agents/](agents/) para las definiciones.

## Sistema de Auditoría

`/forge audit` puntúa la configuración de Claude Code de tu proyecto en una escala de 10 puntos:

- **5 ítems obligatorios** (puntaje 0-2): settings.json, hook de bloqueo destructivo, CLAUDE.md, rules, lista de denegación
- **7 ítems recomendados** (puntaje 0-1): hook de lint, commands, registro de errores, agentes, manifiesto, hook global, scan de prompt injection
- **Tier de proyecto**: simple/standard/complex ajusta expectations de scoring
- **Tope de seguridad**: si falta settings.json o el hook de bloqueo destructivo, el puntaje máximo es 6.0

Los puntajes se registran en `registry/projects.yml` con historial para seguimiento de tendencias.

## Pipeline de Prácticas

Un sistema de mejora continua para descubrir e incorporar patrones de configuración de Claude Code:

```
inbox/ → evaluating/ → active/ → deprecated/
```

Las prácticas llegan desde: `/forge capture` (manual), `/forge update` (búsqueda web), `/forge watch` (docs upstream), `/forge scout` (repos curados), brechas de auditoría, o hooks post-sesión.

Ver [practices/README.md](practices/README.md) para el ciclo de vida y formato.

## Documentación

- **[Guía de Uso](docs/guia-uso.md)** — Guía completa paso a paso: instalación, bootstrap, sync, auditoría, prácticas ([English](docs/usage-guide.md))
- [Best Practices](docs/best-practices.md) — Patrones de configuración de Claude Code
- [Security Checklist](docs/security-checklist.md) — 62 ítems para revisión pre-deploy
- [Prompting Patterns](docs/prompting-patterns.md) — 10 patrones reproducibles
- [Creating Stacks](docs/creating-stacks.md) — Cómo agregar un nuevo stack tecnológico
- [Anatomy of CLAUDE.md](docs/anatomy-claude-md.md) — Análisis detallado de las instrucciones de proyecto
- [Memory Strategy](docs/memory-strategy.md) — Política de memoria de 5 capas para agentes
- [Troubleshooting](docs/troubleshooting.md) — Problemas comunes y diagnósticos
- [Changelog](docs/changelog.md) — Historial de versiones (v0.1.0 → v2.0.0)
- [Roadmap](ROADMAP.md) — Planes a futuro (v1.6.0+)

## Requisitos

- CLI de [Claude Code](https://docs.anthropic.com/en/docs/claude-code) instalado
- `bash` (los hooks son shell scripts)
- `python3` con `pyyaml` (para validación del registro, opcional)

## Configuración

claude-kit usa una única variable de entorno:

```bash
export CLAUDE_KIT_DIR="/path/to/claude-kit"
```

Se configura automáticamente con `global/sync.sh`. Todos los skills y hooks resuelven rutas a través de esta variable.

## Licencia

[MIT](LICENSE)

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md).
