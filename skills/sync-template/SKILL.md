---
name: sync-template
description: Actualiza la configuración de Claude Code de un proyecto existente contra la plantilla claude-kit actual, sin perder customizaciones locales.
---

# Sincronizar Template

Actualizar la configuración de Claude Code del proyecto actual contra la versión más reciente de claude-kit.

## Principio: merge, no overwrite

NUNCA sobrescribir archivos existentes sin confirmación. Comparar y proponer cambios.
NUNCA tocar `settings.local.json` — es configuración personal del usuario.
NUNCA modificar secciones marcadas con `<!-- forge:custom -->` en CLAUDE.md.

## Paso 1: Detectar estado actual

1. Leer `.claude/settings.json` actual
2. Leer `CLAUDE.md` actual
3. Leer `.claude/rules/` existentes
4. Leer `.claude/hooks/` existentes
5. Detectar stacks del proyecto (misma lógica que bootstrap/audit)

## Paso 2: Comparar contra template

Para cada componente, comparar con la versión de claude-kit:

### settings.json — Merge inteligente
- **allow**: unión de sets. Agregar permisos del template base + stacks que falten. NUNCA quitar permisos locales que el proyecto ya tiene.
- **deny**: unión de sets. Agregar denys de seguridad que falten. NUNCA quitar denys locales.
- **hooks**: agregar hooks faltantes del template. Preservar hooks custom del proyecto.
- **Otros campos**: preservar todo lo que no sea allow/deny/hooks (ej: MCP configs).

### Rules
- ¿Falta `_common.md`? → proponer agregar
- ¿Faltan rules del stack detectado? → proponer agregar
- ¿Rules existentes están desactualizadas? → mostrar diff, proponer update
- Rules custom del proyecto (no en template) → NO TOCAR

### Hooks
- ¿Falta `block-destructive.sh`? → proponer agregar + chmod +x
- ¿Falta hook de lint del stack? → proponer agregar + chmod +x
- Hooks custom del proyecto → NO TOCAR
- Verificar que hooks existentes son ejecutables (chmod +x)

### CLAUDE.md
- Comparar secciones estándar del template con las del proyecto
- Secciones con `<!-- forge:custom -->` → SALTAR completamente
- Secciones faltantes del template → proponer agregar
- Secciones custom del proyecto → NO TOCAR

## Paso 3: Generar dry-run

Mostrar al usuario qué cambiaría ANTES de aplicar nada:
```
═══ SYNC DRY-RUN: {{proyecto}} ═══
claude-kit: {{version}} (actual del proyecto: {{version_anterior o "desconocida"}})

ARCHIVOS NUEVOS (se crearán):
+ .claude/rules/_common.md
+ .claude/hooks/block-destructive.sh

ARCHIVOS ACTUALIZADOS (merge):
~ .claude/settings.json
  + allow: "Bash(docker *)", "Bash(docker compose *)"
  + deny: "**/.env.local"
  (permisos locales preservados: "Bash(custom-script *)")

~ .claude/rules/backend.md
  diff: +3 líneas (nuevos errores comunes)

SIN CAMBIOS:
= .claude/rules/frontend.md (ya actualizado)
= .claude/hooks/lint-ts.sh (ya actualizado)

IGNORADOS (custom):
⊘ .claude/rules/strategies.md (no existe en template)
⊘ CLAUDE.md sección "<!-- forge:custom -->"

¿Aplicar cambios? (sí/no/seleccionar)
```

## Paso 4: Aplicar con confirmación

Solo aplicar los cambios que el usuario apruebe.
- `sí` → aplicar todo
- `no` → cancelar
- `seleccionar` → mostrar cada cambio y pedir sí/no individual

Para settings.json: construir el JSON final mergeado y escribir. Verificar que el JSON es válido antes de escribir.

Para hooks: copiar + `chmod +x`.

## Paso 5: Actualizar registry

Actualizar en `~/Documents/GitHub/claude-kit/registry/projects.yml`:
- `last_sync:` → fecha actual
- `claude_kit_version:` → versión actual de claude-kit

## Paso 6: Verificar

Ejecutar la lógica de `/audit-project` para confirmar que el score mejoró o se mantiene.
Mostrar score antes y después.
