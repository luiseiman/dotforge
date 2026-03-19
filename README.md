# claude-kit

Fábrica de configuración para Claude Code. Templates, stacks, skills, auditoría y pipeline de prácticas.

## Quick Start

```bash
# 1. Clonar
git clone https://github.com/luiseiman/claude-kit.git ~/Documents/GitHub/claude-kit

# 2. Instalar skills globales (symlinks)
ln -sf ~/Documents/GitHub/claude-kit/skills/* ~/.claude/skills/

# 3. En cualquier proyecto:
/forge bootstrap    # Inicializar .claude/ completo
/forge audit        # Auditar configuración y ver score
/forge sync         # Actualizar contra plantilla actual
```

## Estructura

```
claude-kit/
├── template/       ← Plantilla base (CLAUDE.md.tmpl, settings, hooks, rules, commands)
├── stacks/         ← Módulos por stack (python-fastapi, react-vite-ts, swift, supabase, ...)
├── agents/         ← 6 subagentes especializados (researcher, architect, implementer, ...)
├── skills/         ← Skills globales (bootstrap, sync, audit, capture, update-practices)
├── audit/          ← Checklist (11 items) + scoring normalizado a 10
├── practices/      ← Pipeline: inbox → evaluating → active → deprecated
├── registry/       ← Registro de proyectos gestionados con scores
├── docs/           ← Best practices, security checklist, prompting patterns
└── hooks/          ← Hook global de detección de cambios post-sesión
```

## Stacks disponibles

| Stack | Rules | Hooks | Settings |
|-------|-------|-------|----------|
| python-fastapi | backend.md, tests.md | lint-python.sh | ✓ |
| react-vite-ts | frontend.md | lint-ts.sh | ✓ |
| swift-swiftui | ios.md | lint-swift.sh | ✓ |
| supabase | database.md | — | ✓ |
| docker-deploy | infra.md | — | ✓ |
| data-analysis | data.md | — | ✓ |
| gcp-cloud-run | gcp.md | — | ✓ |
| redis | redis.md | — | ✓ |

## Skills

| Skill | Comando | Qué hace |
|-------|---------|----------|
| bootstrap-project | `/forge bootstrap` | Inicializa .claude/ en proyecto nuevo |
| sync-template | `/forge sync` | Actualiza config contra plantilla (merge, no overwrite) |
| audit-project | `/forge audit` | Audita config + calcula score |
| capture-practice | `/forge capture` | Registra insight en practices/inbox |
| update-practices | `/forge update` | Procesa inbox → evalúa → incorpora → propaga |

## Docs

- [Best Practices](docs/best-practices.md) — Configuración de Claude Code
- [Security Checklist](docs/security-checklist.md) — 31 items pre-deploy
- [Prompting Patterns](docs/prompting-patterns.md) — 10 patrones reproducibles
- [Creating Stacks](docs/creating-stacks.md) — Cómo agregar un stack nuevo
- [Troubleshooting](docs/troubleshooting.md) — Problemas comunes
