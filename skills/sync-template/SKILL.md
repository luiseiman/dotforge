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

## Paso 0: Verificar global

Antes de sincronizar el proyecto, verificar que `~/.claude/CLAUDE.md` existe y tiene las reglas de comportamiento (comunicación, planificación, autonomía). Si las reglas de global están activas, `_common.md` del proyecto solo necesita reglas técnicas (git, naming, testing, seguridad). No duplicar lo que ya está en global.

## Paso 1: Detectar estado actual

1. Leer `.claude/settings.json` actual
2. Leer `CLAUDE.md` actual
3. Leer `.claude/rules/` existentes
4. Leer `.claude/hooks/` existentes
5. Detect stacks using `$CLAUDE_KIT_DIR/stacks/detect.md`
6. Leer `~/.claude/CLAUDE.md` para saber qué reglas ya están cubiertas globalmente

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

Para settings.json: construir el JSON final mergeado. Antes de escribir, validar que el JSON es válido:

```bash
echo '<json_content>' | python3 -c 'import json,sys; json.load(sys.stdin)'
```

Si la validación falla, mostrar el error exacto y NO escribir el archivo. Corregir el JSON antes de continuar.

Para hooks: copiar + `chmod +x`.

## Paso 4b: Actualizar manifest

Después de aplicar cambios, actualizar (o crear) `.claude/.forge-manifest.json`:

1. Si existe el manifest, leerlo
2. Para cada archivo creado o modificado durante el sync, recalcular hash:
   ```bash
   shasum -a 256 <file> | cut -d' ' -f1
   ```
3. Actualizar `claude_kit_version` y `synced_at`
4. Escribir el manifest actualizado

Formato:
```json
{
  "claude_kit_version": "<version de $CLAUDE_KIT_DIR/VERSION>",
  "synced_at": "<fecha actual YYYY-MM-DD>",
  "files": {
    ".claude/settings.json": {"hash": "sha256:<hash>", "source": "template+stacks"},
    ".claude/rules/_common.md": {"hash": "sha256:<hash>", "source": "template"}
  }
}
```

Incluir TODOS los archivos en `.claude/` que son gestionados por claude-kit (no solo los que cambiaron en este sync).

## Paso 5: Actualizar registry

Actualizar en `$CLAUDE_KIT_DIR/registry/projects.yml`:
- `last_sync:` → fecha actual
- `claude_kit_version:` → versión actual de claude-kit

## Paso 6: Verificar

Ejecutar la lógica de `/audit-project` para confirmar que el score mejoró o se mantiene.
Mostrar score antes y después.
