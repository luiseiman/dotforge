# Auditar proyecto

Ejecutá una auditoría del proyecto actual contra la plantilla claude-kit.

## Steps

1. Detectar el stack del proyecto:
   - `pyproject.toml` o `requirements.txt` → python-fastapi
   - `package.json` con react/vite → react-vite-ts
   - `Package.swift` o `*.xcodeproj` → swift-swiftui
   - `supabase/` o referencias a Supabase → supabase
   - `*.db` o `*.sqlite` o notebooks → data-analysis
   - `docker-compose*` o `Dockerfile*` → docker-deploy
   - `app.yaml`, `cloudbuild.yaml`, `gcloud` en scripts → gcp-cloud-run
   - `redis` en requirements/pyproject.toml → redis

2. Leer el checklist de auditoría: `~/Documents/GitHub/claude-kit/audit/checklist.md`

3. Evaluar cada item del checklist contra el proyecto actual:
   - ¿Existe CLAUDE.md? ¿Tiene >20 líneas útiles?
   - ¿Existe .claude/settings.json con permisos explícitos?
   - ¿Hay rules contextuales en .claude/rules/?
   - ¿Hay hook block-destructive?
   - ¿Los comandos build/test están documentados?
   - Items recomendados del checklist

4. Calcular score según `~/Documents/GitHub/claude-kit/audit/scoring.md`

5. Generar reporte con formato estándar de auditoría.
