---
name: reset-project
description: Restaura .claude/ de un proyecto a la plantilla claude-kit desde cero, con backup y opción de rollback.
---

# Reset Proyecto

Restaurar `.claude/` completo del proyecto actual a la plantilla claude-kit, desde cero.

## Paso 1: Confirmar con el usuario (OBLIGATORIO)

Mostrar advertencia antes de proceder:

```
╔══════════════════════════════════════════════════╗
║  RESET: se reemplazará .claude/ completo        ║
║                                                  ║
║  Se perderán:                                    ║
║  - Customizaciones en settings.json              ║
║  - Rules personalizadas                          ║
║  - Hooks custom                                  ║
║  - Cualquier archivo manual en .claude/          ║
║                                                  ║
║  Se preservará:                                  ║
║  - settings.local.json (no se toca)              ║
║  - CLAUDE.md (se regenera desde template)        ║
║  - CLAUDE_ERRORS.md (se preserva si existe)      ║
║                                                  ║
║  Se creará backup en .claude.backup-YYYY-MM-DD/  ║
╚══════════════════════════════════════════════════╝

¿Confirmar reset? (sí/no)
```

Si el usuario dice "no", cancelar inmediatamente. NO proceder sin confirmación explícita.

## Paso 2: Detectar stacks

Analizar el directorio actual para detectar stacks (misma lógica que bootstrap):
- `pyproject.toml`, `requirements.txt`, `Pipfile` → **python-fastapi**
- `package.json` con react/vite/next → **react-vite-ts**
- `Package.swift`, `*.xcodeproj`, `*.xcworkspace` → **swift-swiftui**
- `supabase/`, `supabase.ts`, `@supabase/supabase-js` en package.json → **supabase**
- `*.db`, `*.sqlite`, `*.ipynb` prominentes → **data-analysis**
- `docker-compose*`, `Dockerfile*` → **docker-deploy**
- `app.yaml`, `cloudbuild.yaml`, `gcloud` en scripts → **gcp-cloud-run**
- `redis` en requirements.txt/pyproject.toml → **redis**

Confirmar stacks con el usuario.

## Paso 3: Hacer backup

1. Crear directorio `.claude.backup-{YYYY-MM-DD}/` en la raíz del proyecto
2. Copiar TODO `.claude/` al backup:
   ```bash
   cp -R .claude/ .claude.backup-$(date +%Y-%m-%d)/
   ```
3. Si `CLAUDE_ERRORS.md` existe, copiarlo aparte (se restaurará después)
4. Verificar que el backup existe y tiene contenido

## Paso 4: Re-ejecutar bootstrap completo

1. Eliminar `.claude/` actual:
   ```bash
   rm -rf .claude/
   ```
2. Ejecutar el skill `/bootstrap-project` completo desde cero
3. Si `CLAUDE_ERRORS.md` existía, restaurar el archivo original (no el template vacío)

## Paso 5: Mostrar diff entre backup y nuevo

Comparar backup vs nuevo `.claude/`:

```
═══ RESET COMPLETADO ═══

Archivos nuevos (no existían antes):
+ .claude/rules/agents.md
+ .claude/agents/researcher.md

Archivos actualizados (diferencias con backup):
~ .claude/settings.json — 3 permisos nuevos en allow
~ .claude/hooks/block-destructive.sh — 2 patterns nuevos

Archivos eliminados (estaban en backup, no en template):
- .claude/rules/custom-strategy.md

Archivos preservados:
= CLAUDE_ERRORS.md (restaurado del backup)
```

## Paso 6: Ofrecer rollback

```
Backup disponible en: .claude.backup-YYYY-MM-DD/
Para restaurar: rm -rf .claude && mv .claude.backup-YYYY-MM-DD .claude
¿Eliminar backup? (sí/no — recomendado: no, al menos hasta verificar)
```

Si el usuario quiere restaurar, ejecutar el rollback inmediatamente.
Si el usuario quiere eliminar el backup, hacerlo.
Si el usuario no decide, dejar el backup (se puede limpiar manualmente después).

## Instalación

Este skill se instala automáticamente si ya existe el symlink de `skills/` en `~/.claude/skills/`. Si no, crear el symlink:
```bash
ln -sf ~/Documents/GitHub/claude-kit/skills ~/.claude/skills
```
