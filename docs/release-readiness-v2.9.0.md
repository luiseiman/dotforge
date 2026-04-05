# dotforge v2.9.0 — Protocolo final de validación

Fecha: 2026-04-05
Objetivo: validar que `v2.9.0` está lista para release público
Estado: **SHIP** — e2e completado, 28/28 checklist items passed

## 1. Resumen

La validación local ya confirmó:

- `install.sh` funcional en instalación limpia simulada
- `audit/score.sh --json` funcionando
- `tests/test-hooks.sh` en PASS
- `tests/lint-rules.sh` en PASS
- `tests/test-config.sh` en PASS con warnings, sin fails
- `bash -n template/hooks/*.sh` en PASS

Lo que falta para cerrar `v2.9.0` no es reparación técnica profunda, sino validación operativa final:

- `/forge bootstrap` en proyecto limpio
- `/forge audit` en runtime real
- `/forge status` en runtime real
- limpieza final del worktree

## 2. Criterio de release

`v2.9.0` puede considerarse lista para lanzamiento si se cumplen todos estos puntos:

1. El versionado está alineado en todos los archivos relevantes
2. El README refleja correctamente el posicionamiento y los links externos funcionan
3. La suite local principal pasa
4. `install.sh` funciona en entorno limpio
5. `/forge bootstrap` funciona en un proyecto vacío
6. `/forge audit` funciona en runtime real
7. `/forge status` funciona en runtime real
8. El worktree queda limpio o solo con cambios intencionales

## 3. Protocolo e2e

## Paso 1 — Crear proyecto limpio de prueba

Ejecutar:

```bash
mkdir -p /tmp/dotforge-e2e
cd /tmp/dotforge-e2e
git init
```

Criterio de aceptación:

- el directorio existe
- no contiene `.claude/`
- no contiene `CLAUDE.md`

## Paso 2 — Abrir el proyecto en Claude Code

Dentro de Claude Code, abrir `/tmp/dotforge-e2e`.

Criterio de aceptación:

- Claude Code trabaja sobre el directorio correcto

## Paso 3 — Ejecutar bootstrap

En Claude Code, correr uno de estos comandos:

```text
/forge init
```

o

```text
/forge bootstrap
```

Criterio de aceptación:

- se crea `.claude/`
- se crea `CLAUDE.md`
- se crea `CLAUDE_ERRORS.md`
- se crea `.claude/.forge-manifest.json`

## Paso 4 — Verificar estructura generada

Ejecutar:

```bash
cd /tmp/dotforge-e2e
ls -R .claude
cat .claude/.forge-manifest.json
```

Criterio de aceptación:

- `.claude/settings.json` existe
- `.claude/rules/` existe
- `.claude/hooks/` existe
- `.claude/commands/` existe
- `.claude/agents/` existe
- el manifest es JSON válido
- el manifest incluye:
  - `dotforge_version`
  - `synced_at`
  - `stacks`
  - `files`

## Paso 5 — Ejecutar auditoría real

En Claude Code:

```text
/forge audit
```

Criterio de aceptación:

- el comando corre sin error
- devuelve score coherente
- no falla por JSON inválido
- no falla por hooks o manifest

## Paso 6 — Ejecutar status real

En Claude Code:

```text
/forge status
```

Criterio de aceptación:

- lee `projects.local.yml` si existe
- si no existe, usa fallback a `projects.yml`
- muestra proyectos, score, tendencia y última auditoría
- no falla por parseo o paths

## Paso 7 — Ejecutar sync básico

En Claude Code:

```text
/forge sync
```

Criterio de aceptación:

- no destruye customizaciones
- mantiene integridad de `settings.json`
- actualiza manifest si corresponde

## Paso 8 — Cerrar con chequeo del proyecto de prueba

Ejecutar:

```bash
cd /tmp/dotforge-e2e
git status --short
```

Criterio de aceptación:

- solo aparecen archivos esperables del bootstrap
- no aparecen errores de generación
- no hay archivos corruptos o vacíos donde no corresponde

## 4. Qué revisar si algo falla

## Falla del manifest

Revisar:

- [skills/bootstrap-project/SKILL.md](/Users/luiseiman/Documents/github/dotforge/skills/bootstrap-project/SKILL.md)
- [skills/sync-template/SKILL.md](/Users/luiseiman/Documents/github/dotforge/skills/sync-template/SKILL.md)

Señales típicas:

- falta `stacks`
- falta `dotforge_version`
- `files` incompleto

## Falla de auditoría JSON

Revisar:

- [audit/score.sh](/Users/luiseiman/Documents/github/dotforge/audit/score.sh)

Señales típicas:

- error Python
- JSON mal formado
- campos booleanos inválidos

## Falla de updates o status

Revisar:

- [template/hooks/check-updates.sh](/Users/luiseiman/Documents/github/dotforge/template/hooks/check-updates.sh)
- [global/commands/forge.md](/Users/luiseiman/Documents/github/dotforge/global/commands/forge.md)

Señales típicas:

- manifest no encontrado
- registry no leído correctamente
- fallback roto entre `projects.local.yml` y `projects.yml`

## Falla de stack drift o hookify

Revisar:

- [template/hooks/detect-stack-drift.sh](/Users/luiseiman/Documents/github/dotforge/template/hooks/detect-stack-drift.sh)
- [stacks/hookify/settings.json.partial](/Users/luiseiman/Documents/github/dotforge/stacks/hookify/settings.json.partial)
- [stacks/hookify/rules/hookify.md](/Users/luiseiman/Documents/github/dotforge/stacks/hookify/rules/hookify.md)

Señales típicas:

- warning falso de stack no instalado
- hook path inválido
- recursos de hookify no copiados

## 5. Checklist de release

## A. Versionado

- [x] `VERSION` en `2.9.0`
- [x] `install.sh` en `2.9.0`
- [x] `.claude-plugin/plugin.json` en `2.9.0`
- [x] `README.md` actualizado a `2.9.0`
- [x] `docs/changelog.md` con entrada `v2.9.0`

## B. README

- [x] tagline nueva aplicada ("Configuration governance")
- [x] lifecycle loop visible (bootstrap → audit → sync → capture → propagate)
- [x] sección `Works with` correcta (alirezarezvani/claude-skills, garrytan/gstack)
- [x] links externos verificados
- [x] sección export multi-platform presente
- [x] requirements con WSL/Windows guidance

## C. Suite local

- [x] `bash tests/test-hooks.sh` — 10/10
- [x] `bash tests/lint-rules.sh` — 23/23
- [x] `bash tests/test-config.sh .` — 55/55 (0 fails, 3 warnings)
- [x] `bash audit/score.sh . --json` — JSON válido, score 9.3
- [x] `bash -n template/hooks/*.sh` — todos pasan

## D. Instalación

- [x] `install.sh` existe, ejecutable, sintaxis válida
- [x] `global/sync.sh` ejecuta correctamente
- [x] skills: 17/17 instaladas
- [x] agents: 7/7 instalados
- [x] commands: 18/18 instalados

## E. Runtime real (e2e ejecutado 2026-04-05)

- [x] `/forge bootstrap` sobre `/tmp/dotforge-e2e` — 20 archivos creados, stack react-vite-ts detectado
- [x] `/forge audit` — score 8.87/10 (Bueno), JSON válido, sin errores
- [x] `/forge status` — 12 proyectos leídos de registry, avg 9.8/10
- [x] `/forge sync` — todo in sync, sin destrucción de customizaciones

## F. Limpieza

- [x] worktree limpio (solo `.claude/session/` gitignored)
- [x] sin artefactos accidentales
- [x] JSONs validados (settings.json, settings.local.json, forge-manifest.json)

## 6. Veredicto operativo

## Ship

Marcar como `SHIP` si:

- todos los pasos críticos de la sección 3 pasan
- la checklist de la sección 5 no tiene bloqueadores

## No ship

Marcar como `NO SHIP` si ocurre cualquiera de estos:

- falla `/forge bootstrap`
- falla `/forge audit`
- falla `/forge status`
- falla `install.sh`
- el manifest se genera sin `stacks`
- el worktree queda con inconsistencias no explicadas

## 7. Resultado de validación — 2026-04-05

### E2E completado

| Step | Resultado | Detalle |
|------|-----------|---------|
| 1. Proyecto limpio | ✓ | `/tmp/dotforge-e2e` con package.json (react+vite) |
| 2. Bootstrap | ✓ | 20 archivos, stack react-vite-ts, manifest con `stacks` |
| 3. Estructura | ✓ | settings.json (14 deny), 4 hooks ejecutables, 3 rules, 7 agents, 4 commands |
| 4. Audit | ✓ | 8.87/10 — texto y JSON válidos, sin security cap |
| 5. Status | ✓ | 12 proyectos, avg 9.8/10, trends correctos |
| 6. Sync | ✓ | Todo in sync, sin destrucción |
| 7. Worktree | ✓ | Solo archivos esperables, JSONs válidos |

### Checklist: 28/28 passed

### Bloqueantes: 0

## 8. Veredicto final

**SHIP**

`v2.9.0` pasó validación e2e completa dentro de Claude Code. Suite local, instalación, bootstrap, audit, status y sync verificados contra proyecto real. Release público autorizado.
