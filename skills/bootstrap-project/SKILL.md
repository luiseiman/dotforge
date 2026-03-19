---
name: bootstrap-project
description: Inicializa la configuración de Claude Code en un proyecto nuevo o existente usando la plantilla claude-kit.
---

# Bootstrap Proyecto

Inicializar `.claude/` completo en el proyecto actual usando la plantilla claude-kit.

## Paso 1: Detectar stack

Use detection rules from `~/Documents/GitHub/claude-kit/stacks/detect.md`.

## Paso 2: Confirmar con usuario

Mostrar:
```
Stack detectado: {{stacks}}
Se creará:
- CLAUDE.md (plantilla base + stack rules)
- .claude/settings.json (permisos base + stack)
- .claude/rules/ (reglas comunes + stack)
- .claude/hooks/ (block-destructive + lint)
- .claude/commands/ (audit, health)
- CLAUDE_ERRORS.md (vacío, para registro de errores)

¿Proceder? (sí/no)
```

## Paso 3: Generar CLAUDE.md

Usar `~/Documents/GitHub/claude-kit/template/CLAUDE.md.tmpl` como base.
Reemplazar marcadores:
- `{{PROJECT_NAME}}` → nombre del directorio actual
- `<!-- forge:stack -->` → tecnologías detectadas
- `<!-- forge:commands -->` → comandos de build/test detectados (package.json scripts, Makefile targets, etc.)

## Paso 4: Generar settings.json

1. Cargar `~/Documents/GitHub/claude-kit/template/settings.json.tmpl` como base
2. Para **cada** stack detectado, leer `~/Documents/GitHub/claude-kit/stacks/{stack}/settings.json.partial`
3. Merge: combinar los arrays `allow` de **todos** los partials con la base (unión de sets, sin duplicados)
4. Merge: combinar los arrays `deny` igualmente
5. Escribir en `.claude/settings.json`

**Multi-stack:** Si se detectan múltiples stacks (ej: python-fastapi + react-vite-ts + docker-deploy), mergear TODOS los partials. Orden no importa — es unión de sets.

## Paso 4b: Validar JSON

Antes de escribir `settings.json`, validar que el JSON generado es válido:

```bash
python3 -c 'import json; json.load(open(".claude/settings.json"))' 2>&1
```

O si aún no se escribió, validar el contenido en memoria/string:
```bash
echo '<json_content>' | python3 -c 'import json,sys; json.load(sys.stdin)'
```

Si la validación falla, mostrar el error exacto y NO escribir el archivo. Corregir el JSON antes de continuar.

## Paso 5: Copiar hooks

1. Copiar `~/Documents/GitHub/claude-kit/template/hooks/block-destructive.sh` → `.claude/hooks/`
2. Copiar siempre el hook genérico `~/Documents/GitHub/claude-kit/template/hooks/lint-on-save.sh` (soporta Python + TS + Swift). Los hooks de lint por stack (`lint-python.sh`, `lint-ts.sh`, `lint-swift.sh`) son referencia, no se copian.
3. `chmod +x` en ambos

## Paso 6: Copiar rules

1. Copiar `~/Documents/GitHub/claude-kit/template/rules/_common.md` → `.claude/rules/`
2. Para cada stack detectado, copiar rules de `~/Documents/GitHub/claude-kit/stacks/{stack}/rules/` → `.claude/rules/`

## Paso 7: Copiar comandos

Copiar `~/Documents/GitHub/claude-kit/template/commands/` → `.claude/commands/`

## Paso 8: Copiar agentes y regla de orquestación

1. Copiar `~/Documents/GitHub/claude-kit/agents/*.md` → `.claude/agents/`
2. Copiar `~/Documents/GitHub/claude-kit/template/rules/agents.md` → `.claude/rules/agents.md`

Esto da al proyecto acceso a los 6 subagentes especializados (researcher, architect, implementer, code-reviewer, security-auditor, test-runner) y la regla de orquestación que define cuándo delegar.

## Paso 9: Crear CLAUDE_ERRORS.md

```markdown
# Errores conocidos — {{PROJECT_NAME}}

Registro evolutivo de errores y lecciones aprendidas. Consultar ANTES de trabajar en áreas con errores previos.

Jerarquía de verdad: código fuente > CLAUDE.md > CLAUDE_ERRORS.md > auto-memory

## Formato
| Fecha | Área | Error | Causa raíz | Fix | Regla derivada |
|-------|------|-------|------------|-----|---------------|
```

## Paso 9b: Crear agent-memory/

Create `.claude/agent-memory/` directory for agents with `memory: project` to persist learnings:

```bash
mkdir -p .claude/agent-memory
```

Create a seed file for each memory-enabled agent so the directory structure is ready:
```bash
for agent in implementer architect code-reviewer security-auditor; do
  touch ".claude/agent-memory/${agent}.md"
done
```

This enables implementer, architect, code-reviewer, and security-auditor to accumulate project-specific knowledge across sessions.

## Paso 10: Sugerir hook global

Si el usuario no tiene `detect-claude-changes.sh` instalado en `~/.claude/settings.json`, mostrar:

```
💡 Tip: Para captura automática de prácticas, instalar el hook global:
Copiar hooks/detect-claude-changes.sh a ~/.claude/hooks/
Agregar en ~/.claude/settings.json bajo hooks → Stop
Ver docs para detalles.
```

## Paso 11: Generar manifest

Crear `.claude/.forge-manifest.json` con el hash SHA256 de cada archivo creado durante el bootstrap:

```bash
shasum -a 256 <file> | cut -d' ' -f1
```

Formato:
```json
{
  "claude_kit_version": "<version de ~/Documents/GitHub/claude-kit/VERSION>",
  "synced_at": "<fecha actual YYYY-MM-DD>",
  "files": {
    ".claude/settings.json": {"hash": "sha256:<hash>", "source": "template+stacks"},
    ".claude/rules/_common.md": {"hash": "sha256:<hash>", "source": "template"},
    ".claude/hooks/block-destructive.sh": {"hash": "sha256:<hash>", "source": "template"},
    ".claude/hooks/lint-on-save.sh": {"hash": "sha256:<hash>", "source": "template"}
  }
}
```

- `source` indica de dónde vino el archivo: `"template"`, `"template+stacks"` (si es merge de base + stacks), o `"stacks/<nombre>"`.
- Incluir TODOS los archivos creados en `.claude/` (rules, hooks, commands, agents).
- NO incluir CLAUDE.md ni CLAUDE_ERRORS.md (están en la raíz, no en `.claude/`).

## Paso 12: Reportar

Mostrar resumen de archivos creados y sugerir ejecutar `/audit-project` para verificar.
