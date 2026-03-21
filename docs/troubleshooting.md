> **[English](#troubleshooting)** | **[Español](#solución-de-problemas)**

# Troubleshooting

## Bootstrap doesn't detect my stack

**Symptom:** `/forge bootstrap` says "stack not detected" or detects the wrong stack.

**Cause:** Detection looks for specific files:
- Python → `pyproject.toml`, `requirements.txt`, `Pipfile`
- React → `package.json` with `react` or `vite` in dependencies
- Swift → `Package.swift`, `*.xcodeproj`
- Supabase → `supabase/` directory, `@supabase` imports
- Docker → `docker-compose*`, `Dockerfile*`
- GCP → `app.yaml`, `cloudbuild.yaml`
- Redis → `redis` in Python dependencies

**Fix:** If not detected, specify manually: "My stack is python-fastapi + docker-deploy".

## Hook doesn't execute

**Symptom:** You edit a .py file and the linter doesn't run automatically.

**Checklist:**
1. Is the hook executable? → `chmod +x .claude/hooks/lint-python.sh`
2. Is it referenced in `.claude/settings.json` under `hooks`?
3. Is the linter installed? → `which ruff` (Python) / `npx eslint --version` (TS)
4. Does the hook read `$TOOL_INPUT` correctly? → Verify `jq` is installed

**Quick fix:**
```bash
chmod +x .claude/hooks/*.sh
```

## Low score after sync

**Symptom:** You ran `/forge sync` but the score didn't improve.

**Common causes:**
- CLAUDE.md exists but doesn't have required sections (stack, build, architecture) → score 1, not 2
- Hook exists but isn't executable → score 1, not 2
- Settings.json without deny list → score 1, not 2
- Security cap: if settings.json or block-destructive is missing → max score 6.0

**Fix:** Run `/forge audit` to see the per-item breakdown. Fix the gap with the lowest score first.

## detect-claude-changes doesn't generate notes

**Symptom:** You work on a project, modify `.claude/`, but nothing appears in `practices/inbox/`.

**Checklist:**
1. Is the hook installed globally?
   - Check `~/.claude/settings.json` has a reference to `detect-claude-changes.sh` under `hooks.Stop`
2. Is the script executable?
   - `chmod +x $CLAUDE_KIT_DIR/hooks/detect-claude-changes.sh`
3. Were files modified less than 2 hours ago?
   - The hook looks for changes in the last 2 hours
4. Does a note already exist for this project today?
   - The hook avoids duplicates per day

**Fix:** Manually install the global hook following the instructions in the script.

---

# Solución de problemas

## Bootstrap no detecta mi stack

**Síntoma:** `/forge bootstrap` dice "stack no detectado" o detecta el stack equivocado.

**Causa:** La detección busca archivos específicos:
- Python → `pyproject.toml`, `requirements.txt`, `Pipfile`
- React → `package.json` con `react` o `vite` en dependencias
- Swift → `Package.swift`, `*.xcodeproj`
- Supabase → directorio `supabase/`, imports de `@supabase`
- Docker → `docker-compose*`, `Dockerfile*`
- GCP → `app.yaml`, `cloudbuild.yaml`
- Redis → `redis` en dependencias Python

**Fix:** Si no detecta, especificar manualmente: "Mi stack es python-fastapi + docker-deploy".

## Hook no se ejecuta

**Síntoma:** Editás un archivo .py y el linter no corre automáticamente.

**Checklist:**
1. ¿El hook es ejecutable? → `chmod +x .claude/hooks/lint-python.sh`
2. ¿Está referenciado en `.claude/settings.json` bajo `hooks`?
3. ¿El linter está instalado? → `which ruff` (Python) / `npx eslint --version` (TS)
4. ¿El hook lee `$TOOL_INPUT` correctamente? → Verificar que `jq` está instalado

**Fix rápido:**
```bash
chmod +x .claude/hooks/*.sh
```

## Score bajo después de sync

**Síntoma:** Corriste `/forge sync` pero el score no mejoró.

**Causas comunes:**
- CLAUDE.md existe pero no tiene las secciones requeridas (stack, build, arquitectura) → score 1, no 2
- Hook existe pero no es ejecutable → score 1, no 2
- Settings.json sin deny list → score 1, no 2
- Cap de seguridad: si falta settings.json o block-destructive → score max 6.0

**Fix:** Correr `/forge audit` para ver el desglose item por item. Corregir el gap con score más bajo primero.

## detect-claude-changes no genera notas

**Síntoma:** Trabajás en un proyecto, modificás `.claude/`, pero no aparece nada en `practices/inbox/`.

**Checklist:**
1. ¿El hook está instalado globalmente?
   - Verificar `~/.claude/settings.json` tiene referencia a `detect-claude-changes.sh` bajo `hooks.Stop`
2. ¿El script es ejecutable?
   - `chmod +x $CLAUDE_KIT_DIR/hooks/detect-claude-changes.sh`
3. ¿Los archivos se modificaron hace <2 horas?
   - El hook busca cambios en las últimas 2 horas
4. ¿Ya existe una nota de hoy para ese proyecto?
   - El hook evita duplicados por día

**Fix:** Instalar manualmente el hook global siguiendo las instrucciones en el script.

## MCP server tools not available

**Symptom:** Claude can't use GitHub/Postgres/Supabase tools even though the MCP server is configured.

**Checklist:**
1. Is the server registered in `~/.claude/settings.json` under `mcpServers`?
2. Is the required env var set? (`GITHUB_TOKEN`, `DATABASE_URL`, `SUPABASE_ACCESS_TOKEN`)
3. Is the npm package installed or accessible via `npx`?

**Fix:** Copy the `mcpServers` entry from `mcp/<server>/config.json` into `~/.claude/settings.json`.

## MCP tool denied unexpectedly

**Symptom:** Claude says a tool is blocked when you expected it to work.

**Cause:** The tool appears in the `deny` list in `.claude/settings.json` from the template in `mcp/<server>/permissions.json`.

**Fix:** Review `mcp/<server>/permissions.json`. Move the tool from `deny` to `allow` (or remove from deny) in `.claude/settings.json` if appropriate for your project.

## /cap or /forge capture auto-detect finds nothing

**Symptom:** Running `/cap` returns "No generalizable insight detected in this session."

**Cause:** The skill looks for specific signals (workaround, multi-attempt bug, arch decision, non-obvious API behavior). Routine sessions with clean first-attempt solutions won't trigger.

**Fix:** Use `/cap "description"` with explicit text. Auto-detect is for non-trivial sessions only.
