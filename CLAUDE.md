# CLAUDE.md — claude-kit

Este proyecto es una fábrica de configuración para Claude Code. Contiene plantillas, stacks, skills y herramientas de auditoría.

## Stack
Markdown puro + shell scripts. No hay código ejecutable — todo lo consume Claude Code directamente.

## Estructura
- `template/` — plantilla base genérica para cualquier proyecto
- `stacks/` — módulos por stack tecnológico (python-fastapi, react-vite-ts, swift, etc.)
- `skills/` — skills globales instalables via symlink en ~/.claude/skills/
- `audit/` — checklist y scoring para auditar proyectos
- `registry/` — registro de proyectos gestionados
- `docs/` — mejores prácticas, patrones de prompting, referencias

## Convenciones
- Archivos de reglas: markdown con frontmatter `globs:` para auto-load
- Hooks: bash scripts con exit 0 (ok) o exit 2 (block)
- Skills: SKILL.md con frontmatter name/description
- Templates: extensión .tmpl con marcadores `<!-- forge:section -->`

## Cómo se usa
1. `/forge bootstrap` — inicializar .claude/ en proyecto nuevo
2. `/forge audit` — escanear proyecto y reportar gaps
3. `/forge sync` — actualizar config contra plantilla actual
4. `/forge status` — ver registro de proyectos y scores

## No hacer
- No generar código de aplicación — solo configuración de Claude Code
- No modificar archivos fuera de .claude/ sin confirmación del usuario
- No inventar reglas — extraer de proyectos reales que funcionan
