---
name: forge
description: claude-kit configuration factory — bootstrap, audit, sync, and manage Claude Code projects
---

Sos el operador de claude-kit, la fábrica de configuración para Claude Code.
El proyecto claude-kit vive en `$CLAUDE_KIT_DIR/`.

## Registry

The registry file for reading AND writing project data is always:
`$CLAUDE_KIT_DIR/registry/projects.local.yml`

If it doesn't exist, create it by copying the header from `registry/projects.yml` with `projects: []`.
NEVER write project data to `registry/projects.yml` (that's the template shipped with the repo).

## Precondiciones

ANTES de despachar cualquier acción, verificar las precondiciones de la tabla.
Si no se cumplen, mostrar el mensaje de error y NO ejecutar el skill.

| Acción | Requiere | Si falla |
|--------|----------|----------|
| `bootstrap` | — | — |
| `audit` | — | Si no hay `.claude/.forge-manifest.json`, advertir que el score no tiene baseline de comparación (pero ejecutar igual) |
| `sync` | `CLAUDE.md` + `.claude/settings.json` | "Este proyecto no tiene configuración claude-kit. Ejecutá `/forge bootstrap` primero." |
| `diff` | `.claude/.forge-manifest.json` | "No hay manifest de sync previo. Ejecutá `/forge bootstrap` para inicializar o `/forge audit` para evaluar el estado actual." |
| `reset` | `.claude/` directorio existe | "No hay configuración que resetear. Ejecutá `/forge bootstrap` para inicializar." |
| `export` | `CLAUDE.md` + `.claude/settings.json` | "No hay configuración para exportar. Ejecutá `/forge bootstrap` primero." |
| `insights` | `CLAUDE_ERRORS.md` o `.claude/agent-memory/` | "No hay historial para analizar. Usá el proyecto un tiempo y volvé a intentar." |
| `plugin` | `CLAUDE.md` + `.claude/settings.json` | "No hay configuración para convertir en plugin. Ejecutá `/forge bootstrap` primero." |
| `rule-check` | `.claude/rules/` con al menos 1 rule | "No hay reglas para evaluar. Ejecutá `/forge bootstrap` primero." |
| `benchmark` | `.claude/settings.json` + `CLAUDE.md` + git repo limpio | "Requiere proyecto con config claude-kit y working tree limpio." |
| `mcp add <server>` | target `settings.json` exists (project) OR `--global` flag | Si no hay settings.json: "No settings.json found. Run `/forge bootstrap` first, or use `--global` to install globally." |
| `capture` | — | — |
| `update` | — | — |
| `watch` | — | — |
| `scout` | — | — |
| `inbox` | — | — |
| `pipeline` | — | — |
| `status` | — | — |
| `global sync` | — | — |
| `global status` | — | — |
| `version` | — | — |

## Acción según $ARGUMENTS

### `audit`
Ejecutar el skill `/audit-project` en el proyecto actual.
Leer `$CLAUDE_KIT_DIR/audit/checklist.md` y `scoring.md` como referencia.

### `sync`
Ejecutar el skill `/sync-template` en el proyecto actual.
Comparar contra `$CLAUDE_KIT_DIR/template/` + stacks detectados.

### `init`
Ejecutar el skill `/init-project` en el proyecto actual.
Bootstrap simplificado: auto-detecta stacks, genera config, cero preguntas.
Output: una sola línea con stacks detectados y score.

### `bootstrap` o `bootstrap --profile <minimal|standard|full>`
Ejecutar el skill `/bootstrap-project` en el proyecto actual.
Usar `$CLAUDE_KIT_DIR/template/` como base.
Pasar el profile seleccionado (default: `standard`).

### `global sync`
Actualizar claude-kit y sincronizar `~/.claude/`:

0. **Auto-update**: If `$CLAUDE_KIT_DIR` is a git repo, run `git -C "$CLAUDE_KIT_DIR" pull --ff-only 2>&1`. Show result:
   - If updated: `✓ claude-kit updated: {old_hash}..{new_hash}`
   - If already up to date: `✓ claude-kit already up to date`
   - If pull fails (dirty tree, conflicts): `⚠ Auto-update failed: {reason}. Run 'cd $CLAUDE_KIT_DIR && git pull' manually.`

1. **CLAUDE.md**: comparar `~/.claude/CLAUDE.md` contra `global/CLAUDE.md.tmpl`.
   - Secciones ANTES de `<!-- forge:custom -->` se actualizan desde la plantilla.
   - Secciones DESPUÉS de `<!-- forge:custom -->` se preservan intactas.
   - Si no existe `<!-- forge:custom -->`, agregar el marker y preservar todo lo que no está en la plantilla.

2. **settings.json**: mergear deny list de `global/settings.json.tmpl` con `~/.claude/settings.json`.
   - Deny list: unión de sets (agregar faltantes, nunca quitar).
   - Allow list: preservar lo que el usuario tiene.
   - Hooks: preservar lo existente, agregar detect-claude-changes si no está.
   - Resolve `$CLAUDE_KIT_DIR` in the template to the actual claude-kit directory before merging.
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

### `export <cursor|codex|windsurf|openclaw>`
Ejecutar el skill `/export-config` con el target especificado.
Exporta la configuración claude-kit del proyecto actual a formato compatible con otra herramienta.

### `diff`
Ejecutar el skill `/diff-project` en el proyecto actual.
Compara la configuración del proyecto contra la versión actual de claude-kit.
Muestra qué cambió desde el último sync y recomienda si conviene sincronizar.

### `reset`
Ejecutar el skill `/reset-project` en el proyecto actual.
Restaura `.claude/` completo desde la plantilla claude-kit, con backup obligatorio y opción de rollback.

### `status`
Leer `$CLAUDE_KIT_DIR/registry/projects.local.yml` (si existe) o `$CLAUDE_KIT_DIR/registry/projects.yml` como fallback, y mostrar:
```
═══ REGISTRO claude-kit ═══
Proyecto         Stack                    Score   Trend     Última auditoría
──────────────────────────────────────────────────────────────────────────
my-api           python-fastapi, docker   9.5     ▁▃▇ ↑    2026-03-19
my-frontend      react-vite-ts            7.2     ▇▅▃ ↓    2026-03-18
...
```

**Trend visualization:**
- Show ASCII sparkline from last 5 audit scores in `history[]`
- Arrow: ↑ (improving: last > first), → (stable: delta < 0.5), ↓ (declining: last < first)

**Alerts:**
- If any project's score dropped >1.5 points between last two audits: show `⚠️ ALERT: {{project}} score dropped {{delta}} points`
- If any project has score < 7.0 and claude-kit has a newer version than their last sync: show `💡 {{project}}: run /forge sync (current: v{{their_version}}, available: v{{latest}})`

### `rule-check`
Ejecutar el skill `/rule-effectiveness` en el proyecto actual.
Cruza globs de `.claude/rules/*.md` contra `git log --name-only` para clasificar reglas en activas (>50% match), ocasionales (10-50%), e inertes (<10%).
Reporta rule coverage y directorios sin cobertura.

### `benchmark`
Ejecutar el skill `/benchmark` en el proyecto actual.
Compara config full vs minimal ejecutando la misma tarea estándar en dos worktrees aislados.
Carga task de `$CLAUDE_KIT_DIR/tests/benchmark-tasks/{stack}.yml` según stack detectado.
**Requiere confirmación explícita del usuario** (ejecuta Claude Code dos veces).

### `plugin [output-dir]`
Ejecutar el skill `/plugin-generator` en el proyecto actual.
Genera un paquete de plugin de Claude Code a partir de la configuración claude-kit del proyecto.
El output es un directorio listo para `claude --plugin-dir` o submission al marketplace.
Si no se especifica output-dir, usa `./claude-kit-plugin/`.

### `insights`
Ejecutar el skill `/session-insights` en el proyecto actual.
Analiza patrones de uso, errores frecuentes, archivos más editados y tendencias de score.
Genera recomendaciones y alimenta el pipeline de prácticas automáticamente.

### `unregister <project-name>`
Remove a project from the local registry (`$CLAUDE_KIT_DIR/registry/projects.local.yml`).
1. Read the registry file
2. Find the project by name (case-insensitive)
3. If not found, show: "Project '{{name}}' not found in registry."
4. If found, show project details (name, path, stacks, score) and ask for confirmation
5. On confirm: remove the entry from the YAML, save file
6. Show: "✓ {{name}} removed from registry. Config in the project directory is untouched."

This does NOT delete `.claude/` from the project — only removes it from tracking.

### `mcp add <server> [--global]`
Ejecutar el skill `/mcp-add` con el server especificado.
Instala un MCP server template de `$CLAUDE_KIT_DIR/mcp/<server>/` en la configuración del proyecto actual
(o global con `--global`): mergea mcpServers en settings.json, agrega permisos, y copia rules.md.
Servers disponibles: `github`, `postgres`, `supabase`, `redis`, `slack`.

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
Leer repos de `$CLAUDE_KIT_DIR/practices/sources.yml`.
Comparar sus `.claude/` configs contra template.
Reportar patterns interesantes. NO auto-incorporar.

### `inbox`
Listar prácticas pendientes en `$CLAUDE_KIT_DIR/practices/inbox/`.
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
Leer `$CLAUDE_KIT_DIR/VERSION` y mostrar.

### Sin argumentos
Mostrar ayuda:
```
/forge <comando>

Comandos:
  init          Setup rápido — auto-detecta stacks, cero preguntas
  audit         Auditar proyecto actual contra plantilla
  sync          Sincronizar config contra plantilla
  bootstrap     Inicializar .claude/ en proyecto nuevo [--profile minimal|standard|full]
  export        Exportar config a cursor|codex|windsurf|openclaw
  diff          Qué cambió desde último sync
  reset         Restaurar .claude/ a plantilla (con backup)
  global sync   Sincronizar ~/.claude/ contra plantilla global
  global status Estado de ~/.claude/ vs plantilla
  status        Ver registro de proyectos, scores y tendencias
  rule-check    Detectar reglas inertes cruzando globs contra git history
  benchmark     Comparar config full vs minimal en tareas estandarizadas
  plugin        Generar paquete de plugin para Claude Code marketplace
  insights      Analizar sesiones pasadas y generar recomendaciones
  unregister    Eliminar proyecto del registro (no borra config)
  mcp add       Instalar MCP server template en proyecto o global [--global]
  capture       Registrar insight o práctica descubierta
  update        Pipeline de actualización de prácticas
  watch         Buscar actualizaciones en docs Anthropic
  scout         Revisar repos curados
  inbox         Ver prácticas pendientes
  pipeline      Estado del ciclo de prácticas
  version       Mostrar versión de claude-kit
```
