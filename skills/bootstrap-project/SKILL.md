---
name: bootstrap-project
description: Inicializa la configuración de Claude Code en un proyecto nuevo o existente usando la plantilla claude-kit.
---

# Bootstrap Proyecto

Inicializar `.claude/` completo en el proyecto actual usando la plantilla claude-kit.

## Paso 1: Detectar stack

Analizar el directorio actual para detectar stacks (misma lógica que audit-project).
Si no se puede detectar automáticamente, preguntar al usuario.

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
2. Para cada stack detectado, leer `~/Documents/GitHub/claude-kit/stacks/{stack}/settings.json.partial`
3. Merge: combinar los arrays `allow` de todos los partials con la base
4. Escribir en `.claude/settings.json`

## Paso 5: Copiar hooks

1. Copiar `~/Documents/GitHub/claude-kit/template/hooks/block-destructive.sh` → `.claude/hooks/`
2. Copiar hook de lint del stack correspondiente (o el genérico `lint-on-save.sh`)
3. `chmod +x` en ambos

## Paso 6: Copiar rules

1. Copiar `~/Documents/GitHub/claude-kit/template/rules/_common.md` → `.claude/rules/`
2. Para cada stack detectado, copiar rules de `~/Documents/GitHub/claude-kit/stacks/{stack}/rules/` → `.claude/rules/`

## Paso 7: Copiar comandos

Copiar `~/Documents/GitHub/claude-kit/template/commands/` → `.claude/commands/`

## Paso 8: Crear CLAUDE_ERRORS.md

```markdown
# Errores conocidos — {{PROJECT_NAME}}

Registro evolutivo de errores y lecciones aprendidas. Consultar ANTES de trabajar en áreas con errores previos.

Jerarquía de verdad: código fuente > CLAUDE.md > CLAUDE_ERRORS.md > auto-memory

## Formato
| Fecha | Área | Error | Causa raíz | Fix | Regla derivada |
|-------|------|-------|------------|-----|---------------|
```

## Paso 9: Reportar

Mostrar resumen de archivos creados y sugerir ejecutar `/audit-project` para verificar.
