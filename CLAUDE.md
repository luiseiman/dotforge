# CLAUDE.md — claude-kit

Este proyecto es una fábrica de configuración para Claude Code. Contiene plantillas, stacks, skills y herramientas de auditoría.

## Stack
Markdown puro + shell scripts. No hay código ejecutable — todo lo consume Claude Code directamente.

## Estructura
- `template/` — plantilla base genérica para cualquier proyecto
- `stacks/` — módulos por stack tecnológico (python-fastapi, react-vite-ts, swift, etc.)
- `agents/` — definiciones de subagentes especializados (researcher, architect, implementer, etc.)
- `skills/` — skills globales instalables via symlink en ~/.claude/skills/
- `audit/` — checklist y scoring para auditar proyectos
- `practices/` — ciclo de vida de prácticas (inbox → evaluating → active → deprecated)
- `registry/` — registro de proyectos gestionados
- `global/` — plantillas y herramientas para gestionar ~/.claude/ (CLAUDE.md, settings.json, symlinks)
- `docs/` — mejores prácticas, patrones de prompting, referencias

## Convenciones
- Archivos de reglas: markdown con frontmatter `globs:` para auto-load
- Hooks: bash scripts con exit 0 (ok) o exit 2 (block)
- Skills: SKILL.md con frontmatter name/description
- Templates: extensión .tmpl con marcadores `<!-- forge:section -->`

## Build & Validación
```bash
# Validar hooks (bash syntax)
bash -n .claude/hooks/*.sh

# Validar hooks (shellcheck si disponible)
shellcheck .claude/hooks/*.sh

# Verificar permisos de hooks
ls -la .claude/hooks/*.sh  # todos deben ser -rwxr-xr-x

# Verificar estructura de stacks (cada stack necesita rules/ + settings.json.partial)
for d in stacks/*/; do ls "$d"rules/ "$d"settings.json.partial 2>/dev/null || echo "INCOMPLETE: $d"; done

# Validar YAML del registry
python3 -c "import yaml; yaml.safe_load(open('registry/projects.yml'))"

# Verificar frontmatter en rules
grep -rL "^globs:" .claude/rules/ stacks/*/rules/  # archivos sin globs (ok para _common.md)
```

## Cómo se usa
1. `/forge bootstrap` — inicializar .claude/ en proyecto nuevo
2. `/forge audit` — escanear proyecto y reportar gaps
3. `/forge sync` — actualizar config contra plantilla actual
4. `/forge global sync` — sincronizar ~/.claude/ (skills, agents, deny list)
5. `/forge status` — ver registro de proyectos y scores

## No hacer
- No generar código de aplicación — solo configuración de Claude Code
- No modificar archivos fuera de .claude/ sin confirmación del usuario
- No inventar reglas — extraer de proyectos reales que funcionan
