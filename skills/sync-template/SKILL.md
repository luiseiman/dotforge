---
name: sync-template
description: Actualiza la configuración de Claude Code de un proyecto existente contra la plantilla claude-kit actual, sin perder customizaciones locales.
---

# Sincronizar Template

Actualizar la configuración de Claude Code del proyecto actual contra la versión más reciente de claude-kit.

## Principio: merge, no overwrite

NUNCA sobrescribir archivos existentes sin confirmación. Comparar y proponer cambios.

## Paso 1: Detectar estado actual

1. Leer `.claude/settings.json` actual
2. Leer `CLAUDE.md` actual
3. Leer `.claude/rules/` existentes
4. Leer `.claude/hooks/` existentes
5. Detectar stacks del proyecto

## Paso 2: Comparar contra template

Para cada componente, comparar con la versión de claude-kit:

### settings.json
- ¿Faltan permisos del template base?
- ¿Faltan permisos del stack?
- ¿Falta la deny list de seguridad?
- ¿Faltan hooks?

### Rules
- ¿Falta `_common.md`?
- ¿Faltan rules del stack detectado?
- ¿Las rules existentes están desactualizadas?

### Hooks
- ¿Falta `block-destructive.sh`?
- ¿Falta hook de lint?
- ¿Los hooks existentes están desactualizados?

## Paso 3: Generar diff

Mostrar al usuario qué cambiaría:
```
═══ SYNC: {{proyecto}} ═══

ARCHIVOS NUEVOS (se crearán):
+ .claude/rules/_common.md
+ .claude/hooks/block-destructive.sh

ARCHIVOS ACTUALIZADOS (se modificarán):
~ .claude/settings.json — agregar 3 permisos, agregar deny list
~ CLAUDE.md — agregar sección "Errores conocidos"

SIN CAMBIOS:
= .claude/rules/backend.md (ya actualizado)

¿Aplicar cambios? (sí/no/seleccionar)
```

## Paso 4: Aplicar con confirmación

Solo aplicar los cambios que el usuario apruebe. Para settings.json, hacer merge inteligente (no overwrite).

## Paso 5: Verificar

Ejecutar la lógica de `/audit-project` para confirmar que el score mejoró.
