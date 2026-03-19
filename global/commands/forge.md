Sos el operador de claude-kit, la fábrica de configuración para Claude Code.
El proyecto claude-kit vive en `~/Documents/GitHub/claude-kit/`.

## Acción según $ARGUMENTS

### `audit`
Ejecutar el skill `/audit-project` en el proyecto actual.
Leer `~/Documents/GitHub/claude-kit/audit/checklist.md` y `scoring.md` como referencia.

### `sync`
Ejecutar el skill `/sync-template` en el proyecto actual.
Comparar contra `~/Documents/GitHub/claude-kit/template/` + stacks detectados.

### `bootstrap`
Ejecutar el skill `/bootstrap-project` en el proyecto actual.
Usar `~/Documents/GitHub/claude-kit/template/` como base.

### `global sync`
Sincronizar `~/.claude/` contra `~/Documents/GitHub/claude-kit/global/`:

1. **CLAUDE.md**: comparar `~/.claude/CLAUDE.md` contra `global/CLAUDE.md.tmpl`.
   - Secciones ANTES de `<!-- forge:custom -->` se actualizan desde la plantilla.
   - Secciones DESPUÉS de `<!-- forge:custom -->` se preservan intactas.
   - Si no existe `<!-- forge:custom -->`, agregar el marker y preservar todo lo que no está en la plantilla.

2. **settings.json**: mergear deny list de `global/settings.json.tmpl` con `~/.claude/settings.json`.
   - Deny list: unión de sets (agregar faltantes, nunca quitar).
   - Allow list: preservar lo que el usuario tiene.
   - Hooks: preservar lo existente, agregar detect-claude-changes si no está.
   - Resolve `{{CLAUDE_KIT_PATH}}` in the template to the actual claude-kit directory (`~/Documents/GitHub/claude-kit`) before merging.
   - NUNCA tocar `skipDangerousModePermissionPrompt` — es decisión del usuario.

3. **Symlinks**: ejecutar `global/sync.sh` para skills, agents, commands.

4. Mostrar resumen de cambios.

### `global status`
Mostrar estado de `~/.claude/` vs plantilla:
```
═══ GLOBAL STATUS ═══
CLAUDE.md:    ✓/✗ sincronizado
settings.json: deny list N items (plantilla: M)
Skills:       N/M instalados
Agents:       N/M instalados
Commands:     forge.md (symlink/archivo/falta)
```

### `diff`
Ejecutar el skill `/diff-project` en el proyecto actual.
Compara la configuración del proyecto contra la versión actual de claude-kit.
Muestra qué cambió desde el último sync y recomienda si conviene sincronizar.

### `reset`
Ejecutar el skill `/reset-project` en el proyecto actual.
Restaura `.claude/` completo desde la plantilla claude-kit, con backup obligatorio y opción de rollback.

### `status`
Leer `~/Documents/GitHub/claude-kit/registry/projects.yml` y mostrar:
```
═══ REGISTRO claude-kit ═══
Proyecto         Stack                    Score   Última auditoría
─────────────────────────────────────────────────────────────────
SOMA             python-fastapi, docker   9.5     2026-03-19
...
```

### `capture <descripción>`
Ejecutar el skill `/capture-practice` con la descripción proporcionada.
Registra un insight o práctica descubierta en practices/inbox/.
Ejemplo: `/forge capture "hooks deberían ignorar archivos en migrations/"`

### `update`
Ejecutar el skill `/update-practices`.
Pipeline: procesa inbox → evalúa → incorpora → sugiere propagación.

### `watch`
Ejecutar el skill `/watch-upstream`.
Buscar actualizaciones en docs oficiales de Anthropic/Claude Code.
Comparar contra template y rules actuales. Reportar deltas.
NO auto-incorporar — solo informar.

### `scout`
Ejecutar el skill `/scout-repos`.
Leer repos de `~/Documents/GitHub/claude-kit/practices/sources.yml`.
Comparar sus `.claude/` configs contra template.
Reportar patterns interesantes. NO auto-incorporar.

### `inbox`
Listar prácticas pendientes en `~/Documents/GitHub/claude-kit/practices/inbox/`.
Mostrar título, fecha, source_type y tags de cada una.

### `pipeline`
Mostrar estado del pipeline de prácticas:
```
═══ PIPELINE DE PRÁCTICAS ═══
Inbox:      {{N}} prácticas pendientes
Evaluando:  {{N}} en evaluación
Activas:    {{N}} incorporadas
Deprecadas: {{N}} retiradas
Última actualización: {{fecha}}
```
Leer de practices/inbox/, evaluating/, active/, deprecated/.

### `version`
Leer `~/Documents/GitHub/claude-kit/VERSION` y mostrar.

### Sin argumentos
Mostrar ayuda:
```
/forge <comando>

Comandos:
  audit         Auditar proyecto actual contra plantilla
  sync          Sincronizar config contra plantilla
  bootstrap     Inicializar .claude/ en proyecto nuevo
  diff          Qué cambió desde último sync
  reset         Restaurar .claude/ a plantilla (con backup)
  global sync   Sincronizar ~/.claude/ contra plantilla global
  global status Estado de ~/.claude/ vs plantilla
  status        Ver registro de proyectos y scores
  capture       Registrar insight o práctica descubierta
  update        Pipeline de actualización de prácticas
  watch         Buscar actualizaciones en docs Anthropic
  scout         Revisar repos curados
  inbox         Ver prácticas pendientes
  pipeline      Estado del ciclo de prácticas
  version       Mostrar versión de claude-kit
```
