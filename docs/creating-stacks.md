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

Agregar el nuevo stack al skill `bootstrap-project/SKILL.md` y `audit-project/SKILL.md` en la sección de detección de stacks.

Patrón: buscar archivos indicadores del stack en el directorio raíz.

## Ejemplo completo: stack "redis"

```
stacks/redis/
├── rules/redis.md            ← Streams, keys, connection pool
└── settings.json.partial     ← Permisos para redis-cli
```

Detección en bootstrap: `redis` aparece en `requirements.txt` o `pyproject.toml`.
