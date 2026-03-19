# Troubleshooting

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
