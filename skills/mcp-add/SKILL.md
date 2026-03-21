---
name: mcp-add
description: Install an MCP server template from claude-kit into a project or global Claude Code config with a single command.
---

# MCP Add

Install a claude-kit MCP server template into the current project's or global Claude Code configuration.

## Input parsing

From `$ARGUMENTS` (format: `mcp add <server> [--global]`):
- Extract `<server>`: the word after `mcp add` — one of `github`, `postgres`, `supabase`, `redis`, `slack`
- Detect `--global` flag: if present, target `~/.claude/settings.json`; otherwise target `.claude/settings.json`

## Step 0: Validate

1. Verify the server template exists: `$CLAUDE_KIT_DIR/mcp/<server>/`
   - If directory not found:
     ```
     ✗ Unknown server '{{server}}'.
     Available: github, postgres, supabase, redis, slack
     Usage: /forge mcp add <server> [--global]
     ```
     Stop.

2. Determine target settings path:
   - `--global` → `~/.claude/settings.json`
   - default → `.claude/settings.json`
   - If target doesn't exist and not `--global`: warn "No settings.json found. Run `/forge bootstrap` first, or use `--global` to install globally." Stop.
   - If target doesn't exist and `--global`: create `~/.claude/settings.json` with `{"permissions": {"allow": [], "deny": []}, "mcpServers": {}}`.

## Step 1: Load template files

Read all three template files:
- `$CLAUDE_KIT_DIR/mcp/<server>/config.json`
- `$CLAUDE_KIT_DIR/mcp/<server>/permissions.json`
- `$CLAUDE_KIT_DIR/mcp/<server>/rules.md`

From `config.json`:
- **Server key**: the non-metadata top-level key (e.g., `"github"`, `"postgres"`)
- **Server config block**: the value of that key (the object with `type`, `command`, `args`, `env`)
- **Install note**: the `_install` string — contains required env vars and instructions
- Ignore all keys starting with `_` (metadata)

From `permissions.json`:
- **allow**: the `allow` array value (or `[]` if absent)
- **deny**: the `deny` array value (or `[]` if absent)
- Ignore all keys starting with `_`

## Step 2: Check for existing configuration

Read the target `settings.json`.

Check if the server is already configured:
- Present if `mcpServers.<server>` key exists in settings, OR
- Present if any of the server's allow entries appear in `permissions.allow`

If already configured:
```
⚠  {{server}} MCP ya está configurado en {{target}}.

   Opciones:
   [a] Actualizar — reemplaza mcpServers.{{server}}, agrega permisos faltantes (no quita existentes)
   [s] Salir — no hacer cambios

¿Qué hacemos? [a/S]
```
- `a` → continue with update flow (Step 3)
- `S` or anything else → stop

## Step 3: Show preview

```
══════════════════════════════════════════
  MCP Add: {{SERVER}} → {{target path}}
══════════════════════════════════════════

mcpServers.{{server}}:
{{pretty-print the server config block, replacing env var values like "${GITHUB_TOKEN}"
with the literal placeholder strings — do not expand env vars}}

Permisos nuevos:
  allow (+{{N}} nuevos): {{list entries not already in target settings}}
  deny  (+{{N}} nuevos): {{list entries not already in target settings}}
  (Los permisos existentes no se modifican)

Rules:
  $CLAUDE_KIT_DIR/mcp/{{server}}/rules.md
  → {{rules destination}}

Variables de entorno requeridas:
  {{_install text from config.json}}

¿Proceder? [S/n]
```

If all permissions are already present, show "Permisos: sin cambios (ya configurados)".
If no new denies to add, omit that line.

## Step 4: Apply changes

Only proceed if user confirms (S, s, Enter, or "sí").

### 4a. Merge mcpServers

Read target `settings.json` as JSON.
Set `settings["mcpServers"]["{{server}}"]` = the server config block.
If `mcpServers` key doesn't exist in settings, create it.

### 4b. Merge permissions

**Allow list:**
- For each entry in template `allow[]`: add to `settings.permissions.allow` only if not already present
- Never remove or reorder existing entries

**Deny list:**
- For each entry in template `deny[]`: add to `settings.permissions.deny` only if not already present
- Never remove or reorder existing entries

If `settings.permissions` doesn't exist, create it with `{"allow": [], "deny": []}`.

### 4c. Write settings.json

Write the modified settings.json with 2-space indentation. Preserve all other existing keys
(hooks, autoMemoryEnabled, env, etc.) exactly as they were.

### 4d. Copy rules.md

Determine rules destination:
- Project mode: `.claude/rules/mcp-{{server}}.md`
- Global mode: `~/.claude/rules/mcp-{{server}}.md`

Copy `$CLAUDE_KIT_DIR/mcp/{{server}}/rules.md` to the destination.
If the file already exists: overwrite — it's a managed template file. Any project-specific
customizations should live in a separate rule file, not in `mcp-{{server}}.md`.

Create the destination directory if it doesn't exist.

## Step 5: Confirm result

```
✓ {{SERVER}} MCP configurado

  Archivos actualizados:
    {{target settings.json}} — mcpServers.{{server}} agregado
    {{rules destination}} — reglas de comportamiento copiadas
    {{"+N permisos" if any were added, else "permisos: sin cambios"}}

  Próximo paso:
    {{_install text from config.json}}
    Reiniciá Claude Code para activar el servidor MCP.
```

If global install:
  Add: "Instalado globalmente — activo en todos los proyectos."

If project-only install:
  Add: "Instalado en el proyecto actual. Para uso global: /forge mcp add {{server}} --global"
