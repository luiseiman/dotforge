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

Create `stacks/{stack}/rules/{name}.md` with globs frontmatter:

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

Crear `stacks/{stack}/rules/{nombre}.md` con frontmatter globs:

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
