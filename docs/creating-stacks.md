> **[English](#how-to-create-a-new-stack)** | **[Español](#cómo-crear-un-stack-nuevo)**

# How to create a new stack

## Required structure

```
stacks/{stack-name}/
├── rules/
│   └── {name}.md          ← Stack-specific rules (required)
└── settings.json.partial   ← Additional permissions (required)
```

Optionally:
```
stacks/{stack-name}/
├── hooks/
│   └── lint-{name}.sh     ← Post-write lint hook (recommended)
```

## 1. Rules (required)

Create `stacks/{stack}/rules/{name}.md` with `globs:` frontmatter (eager loading). For large stacks where context optimization matters, use `paths:` with `alwaysApply: false` for lazy loading. Since Claude Code v2.1.84+, `paths:` accepts both unquoted CSV and YAML list syntax:

```markdown
---
globs: "**/*.py"
---

# Stack Name Rules

## Stack
Brief technology description.

## Patterns
- Pattern 1: what to do and why
- Pattern 2: clear preference

## Common mistakes
- Typical error → how to avoid it
```

**Best practices for rules:**
- Specific globs (not generic `*`)
- Imperative: "Use X" not "You could use X"
- Include common errors with solutions
- Maximum 50 lines. If more needed, split into multiple files.

## 2. Settings partial (required)

Create `stacks/{stack}/settings.json.partial`:

```json
{
  "_comment": "Merge with template/settings.json.tmpl",
  "permissions": {
    "allow": [
      "Bash(tool *)"
    ]
  }
}
```

Only include CLI tools specific to the stack. The base template already includes git, rg, etc.

## 3. Lint hook (recommended)

Create `stacks/{stack}/hooks/lint-{name}.sh`:

```bash
#!/bin/bash
# PostToolUse hook: lint on {stack} files
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" =~ \.ext$ ]] && [[ -f "$FILE_PATH" ]]; then
  if command -v linter &>/dev/null; then
    OUTPUT=$(linter "$FILE_PATH" 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi
fi
exit 0
```

**Important:** `chmod +x` the script after creating it.

## Stack hooks during bootstrap

Stack hooks in `stacks/{name}/hooks/` are automatically copied to `.claude/hooks/{name}/` during bootstrap, preserving the stack namespace. For stacks with Python-based hooks (e.g., `hookify`), the `core/` directory is also copied to support the hook implementation.

**Example:** A `hookify` stack with hooks would have:
```
stacks/hookify/
├── hooks/
│   └── lint-hookify.sh
└── core/
    └── hookify.py     ← Helper library for hooks
```
After bootstrap, both appear in `.claude/hooks/hookify/` with the core module available to the hook scripts.

## 4. Register detection

Add the new stack to `stacks/detect.md` detection rules table.

Pattern: look for indicator files of the stack in the root directory.

## Full example: "redis" stack

```
stacks/redis/
├── rules/redis.md            ← Streams, keys, connection pool
└── settings.json.partial     ← Permissions for redis-cli
```

Detection in bootstrap: `redis` appears in `requirements.txt` or `pyproject.toml`.

## Example with hook: "tdd" stack

The `tdd` stack demonstrates how to combine a rule file with a hook:

```
stacks/tdd/
├── rules/tdd-workflow.md     ← TDD workflow rules (red-green-refactor)
├── hooks/test-on-edit.sh     ← PostToolUse hook: run tests on file edit
└── settings.json.partial     ← Permissions for test runners
```

Detection: `pytest.ini`, `vitest.config.*`, or `jest.config.*` present.

---

# Cómo crear un stack nuevo

## Estructura requerida

```
stacks/{nombre-del-stack}/
├── rules/
│   └── {nombre}.md          ← Reglas específicas del stack (obligatorio)
└── settings.json.partial     ← Permisos adicionales (obligatorio)
```

Opcionalmente:
```
stacks/{nombre-del-stack}/
├── hooks/
│   └── lint-{nombre}.sh     ← Hook de lint post-write (recomendado)
```

## 1. Rules (obligatorio)

Crear `stacks/{stack}/rules/{nombre}.md` con frontmatter `globs:` (eager loading). Para stacks grandes donde importa la optimización de contexto, usar `paths:` con `alwaysApply: false` para lazy loading. Desde Claude Code v2.1.84+, `paths:` acepta tanto CSV sin quotes como sintaxis YAML list:

```markdown
---
globs: "**/*.py"
---

# Nombre del Stack Rules

## Stack
Descripción breve de las tecnologías.

## Patterns
- Patrón 1: qué hacer y por qué
- Patrón 2: preferencia clara

## Errores comunes
- Error típico → cómo evitarlo
```

**Buenas prácticas para rules:**
- Globs específicos (no `*` genérico)
- Imperativos: "Usar X" no "Se podría usar X"
- Incluir errores comunes con solución
- Máximo 50 líneas. Si necesita más, dividir en múltiples archivos.

## 2. Settings partial (obligatorio)

Crear `stacks/{stack}/settings.json.partial`:

```json
{
  "_comment": "Merge con template/settings.json.tmpl",
  "permissions": {
    "allow": [
      "Bash(herramienta *)"
    ]
  }
}
```

Solo incluir herramientas CLI específicas del stack. El template base ya incluye git, rg, etc.

## 3. Hook de lint (recomendado)

Crear `stacks/{stack}/hooks/lint-{nombre}.sh`:

```bash
#!/bin/bash
# PostToolUse hook: lint on {stack} files
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty' 2>/dev/null)

if [[ "$FILE_PATH" =~ \.ext$ ]] && [[ -f "$FILE_PATH" ]]; then
  if command -v linter &>/dev/null; then
    OUTPUT=$(linter "$FILE_PATH" 2>&1)
    if [[ $? -ne 0 ]]; then
      echo "$OUTPUT" >&2
      exit 2
    fi
  fi
fi
exit 0
```

**Importante:** `chmod +x` el script después de crearlo.

## Hooks de stack durante bootstrap

Los hooks en `stacks/{nombre}/hooks/` se copian automáticamente a `.claude/hooks/{nombre}/` durante bootstrap, preservando el namespace del stack. Para stacks con hooks basados en Python (ej. `hookify`), el directorio `core/` también se copia para soportar la implementación del hook.

**Ejemplo:** Un stack `hookify` con hooks tendría:
```
stacks/hookify/
├── hooks/
│   └── lint-hookify.sh
└── core/
    └── hookify.py     ← Librería auxiliar para los hooks
```
Después de bootstrap, ambos aparecen en `.claude/hooks/hookify/` con el módulo core disponible para los scripts.

## 4. Registrar detección

Agregar el nuevo stack a la tabla de detección en `stacks/detect.md`.

Patrón: buscar archivos indicadores del stack en el directorio raíz.

## Ejemplo completo: stack "redis"

```
stacks/redis/
├── rules/redis.md            ← Streams, keys, connection pool
└── settings.json.partial     ← Permisos para redis-cli
```

Detección en bootstrap: `redis` aparece en `requirements.txt` o `pyproject.toml`.

## Ejemplo con hook: stack "tdd"

El stack `tdd` demuestra cómo combinar una rule con un hook:

```
stacks/tdd/
├── rules/tdd-workflow.md     ← Reglas de workflow TDD (red-green-refactor)
├── hooks/test-on-edit.sh     ← Hook PostToolUse: corre tests al editar
└── settings.json.partial     ← Permisos para test runners
```

Detección: `pytest.ini`, `vitest.config.*`, o `jest.config.*` presentes.

## Stacks vs MCP templates

Stacks and MCP server templates are complementary, not alternatives:

| | Stack | MCP template |
|---|---|---|
| **What it provides** | Rules, permissions, hooks for local code | Config, permissions, rules for external services |
| **Location** | `stacks/<name>/` | `mcp/<name>/` |
| **Installed to** | `.claude/rules/` + `.claude/settings.json` | `.claude/rules/mcp-<name>.md` + permissions |
| **When to use** | Your code uses this technology | Claude uses this external service via MCP |

Example: A project using Redis locally AND the Redis MCP server would use **both**: the `redis` stack (rules for writing Redis code) and `mcp/redis/` (rules for using Redis tools in Claude sessions).
