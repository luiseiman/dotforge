# dotforge v2.9+ — Plan de ejecucion (corregido)

**Fecha:** 2026-04-05
**Basado en:** Analisis competitivo + verificacion de estado actual + research de competidores + revision de confiabilidad del repo

---

## Correcciones al analisis original

| Supuesto original | Realidad verificada (5 abril 2026) | Impacto |
|---|---|---|
| gstack tiene 15K stars | **~64.5K stars** (10K en 48h por ser Garry Tan/YC) | Gap de traccion 4x peor. Discord posts no van a cerrar esto. |
| claude-skills tiene 147 skills | **248 skills**, 11 plataformas, **5,200+ stars** | Refuerza decision de no competir en volumen |
| ClaudeOS-Core genera reglas AST | **No existe como producto standalone**. ast-grep/agent-skill es lo mas cercano | Benchmark de debilidad 3 es contra duthaho (modos) y claude-bootstrap (knowledge graph), no ClaudeOS-Core |
| Brad Feld tiene skill graduation via GH Actions | **No verificado**. No se encontro pipeline publico | `/forge promote` no tiene precedente — diferenciador pero sin validacion de mercado |
| `disableSkillShellExecution` es riesgo critico | **Falso positivo**. Ninguna SKILL.md de dotforge usa `!` shell execution | Eliminado. Ahorro: 2-4 horas |
| Awesome-claude-code (hesreallyhim) 21.6K stars | **36.6K stars** | PR sigue siendo buena inversion, traccion mayor de la estimada |
| awesome-agent-skills (VoltAgent) no evaluado | **14.2K stars**, activo | PR vale la pena |
| Score 4.4->10.0 es cotiza-api-cloud | **Es vault-bot**. cotiza-api-cloud es 9.6->10.0 | Corregir en todo material publicado |
| 35 practicas capturadas | **28 totales**: 9 inbox, 2 evaluating, 8 active, 9 deprecated | Corregir antes de publicar |
| Registry publico muestra 12 proyectos | **Registry publico vacio** (`projects: []`). 12 proyectos solo en projects.local.yml (gitignored) | Articulo debe usar snapshot exportado, no pretender que el publico tiene datos |

---

## Problemas de confiabilidad verificados (P1) — TODOS RESUELTOS

| Archivo | Problema | Estado |
|---|---|---|
| `audit/score.sh` | JSON roto: triple quotes + true/false Python | ✓ Sanitizado + True/False |
| `template/hooks/check-updates.sh` | Path incorrecto del manifest | ✓ Corregido a `.claude/.forge-manifest.json` |
| `template/hooks/detect-stack-drift.sh` | Schema mismatch + mensaje incorrecto | ✓ Lee stacks de file sources + mensaje corregido |
| `stacks/hookify/` | `$DOTFORGE_DIR` no disponible en runtime | ✓ Paths relativos `.claude/hooks/hookify/` |
| `tests/test-config.sh` | Falso positivo injection scan | ✓ `<instructions>` requiere closing tag |
| Manifest schema | Campo `stacks` ausente | ✓ Agregado en bootstrap + sync skills |

---

## Principios del plan

1. **Trust first** — No se lanza nada hasta que el producto funcione sin errores verificables. Hardening antes de marketing.
2. **Lifecycle first** — Todo el messaging lidera con audit/sync/practices/registry. Bootstrap es la puerta de entrada, no el pitch.
3. **Senal antes de feature** — No construir features especulativas. Cada feature de Fase 2+ requiere senal de demanda (issues, Discord questions, feedback directo).
4. **Contenido > posts** — Un articulo tecnico con datos reales del registry vale mas que 10 Discord posts de una linea.
5. **Sin dependencias propias obligatorias** — dotforge no instala ni requiere tooling externo. Los stacks (tdd, hookify) pueden usar herramientas que ya existen en el proyecto destino, pero dotforge mismo es markdown + shell.

---

## Fase 1: Trust (Semana 1-2, ~16h)

### 1.1 Hardening de confiabilidad
**Esfuerzo:** 4-5h | **Prioridad:** Dia 1-2

**score.sh (JSON):**
- Sanitizar variables de notas antes de interpolar en JSON
- Opcion A: escapar newlines/quotes con `sed` antes del heredoc
- Opcion B: construir JSON con `jq` si esta disponible, fallback a sed
- Verificar: correr `audit/score.sh` contra 3 proyectos del registry local y validar output con `jq .`

**check-updates.sh (path):**
- Corregir linea 17: `.forge-manifest.json` -> `.claude/.forge-manifest.json`
- Reemplazar awk YAML parsing (lineas 28-32) con algo mas robusto
- Verificar: correr hook en proyecto con manifest y sin manifest

**detect-stack-drift.sh (schema):**
- Alinear con schema real del manifest (no tiene array `stacks`)
- Corregir mensaje de linea 50 (no es `/forge mcp add`)
- Verificar: correr contra proyecto con stacks detectados

**hookify (estructura):**
- Agregar `stacks/hookify/rules/` con al menos una rule minima
- Resolver portabilidad de paths (no depender de `$DOTFORGE_DIR` en contexto de proyecto)
- Verificar: `for d in stacks/*/; do ls "$d"rules/ "$d"settings.json.partial 2>/dev/null || echo "INCOMPLETE: $d"; done`

**Validacion final:**
```bash
bash -n template/hooks/*.sh
shellcheck template/hooks/*.sh  # si disponible
bash tests/test-hooks.sh
bash tests/test-config.sh
bash tests/lint-rules.sh
```

### 1.2 Portabilidad (COMPLETADO 2026-04-05)

Fixes ya aplicados a template/hooks/ y propagados a 12 proyectos:

| Fix | Archivo(s) | Cambio |
|-----|-----------|--------|
| `timeout` portable | check-updates.sh | `timeout` -> `gtimeout` -> skip (macOS + Git Bash) |
| `md5sum` portable | block-destructive.sh, lint-on-save.sh, session-report.sh | Funcion `_hash()`: md5sum -> md5 -> cksum (POSIX) |
| Shebangs normalizados | 11 archivos .sh | `#!/bin/bash` -> `#!/usr/bin/env bash` |

**Matriz de soporte resultante:**

| Plataforma | Estado | Notas |
|------------|--------|-------|
| macOS | ✓ completo | Con o sin coreutils |
| Linux | ✓ completo | — |
| WSL | ✓ completo | — |
| Git Bash (Windows) | ⚠ funcional | Requiere jq + python3 en PATH |
| PowerShell/CMD nativo | ✗ no soportado | Requiere capa bash — no se planea soporte |

### 1.3 install.sh — One-liner de instalacion
**Esfuerzo:** 2-3h | **Prioridad:** Dia 2-3

```bash
curl -fsSL https://raw.githubusercontent.com/luiseiman/dotforge/main/install.sh | bash
```

Que hace:
- Detecta OS (macOS/Linux/WSL/Git Bash)
- En Git Bash: warn sobre jq + python3, recomendar WSL
- En PowerShell/CMD: exit con mensaje "Requires bash (macOS/Linux/WSL)"
- Clona en `~/.dotforge/` (o `$DOTFORGE_DIR` si ya definido)
- Ejecuta `global/sync.sh`
- Agrega `export DOTFORGE_DIR=...` a `.bashrc`/`.zshrc`
- Imprime resumen: version, skills instalados, proximo paso (`/forge init`)

Deteccion de plataforma:
```bash
case "$(uname -s)" in
  Linux*)   grep -qi microsoft /proc/version 2>/dev/null && PLATFORM="wsl" || PLATFORM="linux" ;;
  Darwin*)  PLATFORM="macos" ;;
  MINGW*|MSYS*|CYGWIN*) PLATFORM="gitbash" ;;
  *)        echo "Unsupported platform. Requires bash (macOS/Linux/WSL)."; exit 1 ;;
esac
```

Verificacion: correr en macOS limpio + Ubuntu Docker + Git Bash Windows.

### 1.4 README: reposicionar messaging + "Works with"
**Esfuerzo:** 2-3h | **Prioridad:** Dia 3-4

Cambios concretos:
- **Tagline nueva:** "Configuration governance for Claude Code" (no "factory")
- **Hero section:** liderar con el lifecycle loop (bootstrap -> audit -> sync -> capture -> propagate), no con el bootstrap
- **Seccion "Works with":** tabla con claude-skills, duthaho/claudekit, gstack — mostrar que dotforge gestiona, no reemplaza
- **Seccion "What makes dotforge different":** 4 bullets unicos verificados:
  - Cross-project registry con audit history y trending
  - Practices pipeline (inbox -> active -> deprecated)
  - Template sync con preservacion de customizaciones
  - Audit scoring con security cap (ningun competidor tiene esto)
- **Seccion "Multi-platform":**
  ```
  /forge export cursor     -> .cursorrules
  /forge export codex      -> AGENTS.md
  /forge export windsurf   -> .windsurfrules
  /forge export openclaw   -> SKILL.md
  ```
- **Seccion "Requirements":** `bash (macOS, Linux, WSL). Git Bash works but WSL recommended on Windows.`
- **Eliminar** comparaciones numericas (skills count, agent count) — dotforge pierde esa batalla

### 1.5 Verificacion end-to-end
**Esfuerzo:** 2-3h | **Prioridad:** Dia 4-5

- Correr `/forge audit` en 3 proyectos del registry local — verificar que score.sh produce JSON valido
- Correr `/forge status` — verificar que lee registry local correctamente
- Correr install.sh en entorno limpio
- Correr `/forge bootstrap` en proyecto nuevo de prueba
- Documentar cualquier issue encontrado como GitHub issue (preparar para lanzamiento publico)

---

## Fase 2: Lanzamiento + features (Semana 3-6, ~22-28h)

> **Gate:** Hardening completo, install.sh funciona, test suite pasa, verificacion e2e OK.

### 2.1 Distribucion: Discord + awesome-lists
**Esfuerzo:** 4-5h spread over 10 days | **Prioridad:** Semana 3

**Dia 1:** Post en `#agent-skills` — angulo: "Configuration governance, not another skill collection. 12 projects, audit scores 4.4->9.1"
**Dia 3:** Post en `#claude-code` — angulo: "How I manage .claude/ across 12 projects with zero deps"
**Dia 5:** PR a awesome-claude-code (hesreallyhim, 36.6K stars) — category: Configuration Management
**Dia 6:** Post en `#built-with-claude` — angulo: demo GIF de `/forge audit` + `/forge status`
**Dia 8:** PR a awesome-agent-skills (VoltAgent, 14.2K stars) + awesome-claude-code-toolkit (rohitg00)
**Dia 10:** Responder threads organicamente en Discord con valor (no spam)

**Datos a usar en posts (verificados):**
- gstack: ~64.5K stars (complementario, no competidor)
- claude-skills: 248 skills / 5,200+ stars (complementario)
- Score progression: vault-bot 4.4 -> 9.1 (NO cotiza-api-cloud)
- Practicas: 28 en pipeline (9 inbox, 2 evaluating, 8 active, 9 deprecated)

### 2.2 `/forge learn` — Domain knowledge extraction
**Esfuerzo:** 8-12h | **Prioridad:** Semana 3-4

Skill que escanea el proyecto y genera rules domain-specific:

**Paso 1 — Scan (grep/find, zero deps):**
- `package.json` / `pyproject.toml` / `go.mod` / `Podfile` -> dependencias clave
- Top 20 imports mas frecuentes -> librerias core
- Estructura de directorios (src/, app/, lib/, pages/, routes/)
- Patrones de naming (grep para convenciones)
- Config files presentes (.eslintrc, ruff.toml, tsconfig.json)

**Paso 2 — Classify:**
- ORM detectado (SQLAlchemy, Prisma, TypeORM, GORM)
- Framework de auth (JWT, OAuth, session-based)
- Test framework (pytest, vitest, jest, go test)
- Build system (vite, webpack, esbuild, setuptools)
- Deployment (Docker, serverless, cloud run)

**Paso 3 — Generate proposals (interactive):**
```
Detected patterns for [project-name]:

1. ORM: SQLAlchemy 2.x (async sessions detected)
   -> Create .claude/rules/domain/orm-patterns.md? [y/n/edit]

2. Auth: python-jose (JWT)
   -> Create .claude/rules/domain/auth-flow.md? [y/n/edit]

3. Naming: snake_case functions, PascalCase models
   -> Create .claude/rules/domain/naming.md? [y/n/edit]
```

**Diferencia con `/forge domain extract`:** `domain extract` lee fuentes internas de dotforge (memory, errors, agent memory). `/forge learn` lee el CODIGO del proyecto directamente. Son complementarios:
- `learn` -> detecta patterns del codigo
- `domain extract` -> captura conocimiento de sesiones previas

### 2.3 Auto mode safety en audit checklist
**Esfuerzo:** 1h | **Prioridad:** Semana 3

Agregar item #13 al checklist:
```
13. Auto mode safety (0-1)
    - 0: Auto mode enabled sin deny list de seguridad
    - 1: Auto mode enabled CON deny list (.env, *.key, credentials) O auto mode disabled
```

Agregar rule template `auto-mode-safety.md` con guidelines.

### 2.4 Stack `tdd/` — TDD infrastructure
**Esfuerzo:** 3-4h | **Prioridad:** Semana 4-5

```
stacks/tdd/
  plugin.json
  rules/
    tdd-workflow.md    # "Write failing test first. Implement. Verify green. Refactor."
  hooks/
    test-on-edit.sh    # PostToolUse: runs detected test framework when source files change
```

Deteccion automatica: pytest -> `pytest -x`, vitest -> `npx vitest run`, jest -> `npx jest`, go -> `go test ./...`

El hook solo corre cuando el tool edito un archivo `.py`, `.ts`, `.tsx`, `.js`, `.go` (no en reads o greps).

Nota: el stack tdd/ depende de tooling del proyecto destino (pytest, vitest, etc.), no de dependencias propias de dotforge. Esto es consistente con el principio de zero deps propias.

### 2.5 Articulo tecnico
**Esfuerzo:** 3-4h | **Prioridad:** Semana 4 (despues de tener datos de lanzamiento)

**Titulo:** "Managing Claude Code configuration across 12 projects — lessons from building dotforge"

**Contenido con datos corregidos:**
- Score progression: vault-bot 4.4 -> 9.1 (con snapshot exportado del registry local como evidencia)
- 28 practices en pipeline: 8 activas, 9 deprecadas (lifecycle real)
- Audit security cap: por que un proyecto sin settings.json nunca pasa de 6.0
- Practices pipeline: como una practica descubierta en un proyecto se propago a otros

**Nota sobre registry:** el registry publico esta vacio por diseno (gitignored). El articulo debe usar un snapshot exportado o screenshots del registry local. No pretender que el publico tiene datos.

**Distribucion:** Dev.to + Hashnode + link en Discord `#claude-code-lounge`

Este articulo es el asset de distribucion de mayor ROI. Rankea en Google, genera trafico compound, y demuestra el lifecycle con datos verificables.

### 2.6 Mejorar output de `/forge status`
**Esfuerzo:** 1-2h | **Prioridad:** Semana 5

Output actual -> output con:
- Colores por score (verde >=8, amarillo 5-7, rojo <5)
- Trend arrows (up/down/equal) comparando ultimo vs penultimo audit
- Alerta si algun proyecto tiene score <6 o sync pendiente
- Resumen: "12 projects | avg score: 9.2 | 3 need sync"

### 2.7 PermissionDenied hook handler
**Esfuerzo:** 1-2h | **Prioridad:** Semana 5

Hook template para el evento PermissionDenied:
- Loguea: timestamp, tool, args, reason
- Output a `.claude/session/permission-denials.log`
- Alimenta practices pipeline (si pattern recurrente -> practice candidate)

### 2.8 Stack `modes/` — Behavioral modes (condicional)
**Esfuerzo:** 4-5h | **Prioridad:** Solo si hay senal de demanda

**Prerequisito tecnico:** hoy dotforge no tiene un mecanismo runtime claro para "activar una rule por comando". Implementar modes/ requiere disenar esa infraestructura primero. No es "low-effort" en el estado actual.

**Riesgo competitivo:** modos es terreno donde duthaho/claudekit ya tiene traccion. dotforge se diferencia por lifecycle, no por modos.

Si hay senal de demanda (issues, Discord questions), implementar como:
```
stacks/modes/
  plugin.json
  rules/
    mode-plan.md      # alwaysApply: false
    mode-review.md    # alwaysApply: false
    mode-debug.md     # alwaysApply: false
    mode-ship.md      # alwaysApply: false
```

Skill dispatcher: `skills/mode-switch/SKILL.md` — recibe argumento, activa la rule correspondiente.

Si no hay senal para semana 6, eliminar del roadmap.

---

## Fase 3: Evolucion (Semana 7+, condicional)

> **Gate:** Cada item requiere senal especifica de demanda antes de implementar.

### 3.1 `/forge promote` — Practice -> template graduation
**Senal requerida:** Al menos 2 proyectos en registry con la misma practica activa.
**Esfuerzo:** 6-8h

Flow:
1. Usuario corre `/forge promote <practice-id>` en proyecto A
2. dotforge identifica que archivo del template cambia
3. Aplica cambio en `$DOTFORGE_DIR/template/` o `$DOTFORGE_DIR/stacks/`
4. Registra en la practica: `incorporated_in: [template/rules/X.md]`
5. Proximo `/forge sync` en otros proyectos recibe el cambio

### 3.2 Integracion con `/schedule` — Auditorias periodicas
**Senal requerida:** Claude Code `/schedule` estable y documentado.
**Esfuerzo:** 3-4h

Generar un prompt de auditoria que corra via `/schedule` weekly y actualice el registry automaticamente.

### 3.3 Runtime rule injection (estilo CARL)
**Senal requerida:** 5+ issues o requests pidiendo carga dinamica de rules por keyword.
**Esfuerzo:** 8-10h

Re-evaluar si el overhead de un MCP server se justifica vs globs existentes.

---

## Cronograma visual

```
Semana 1  ████████ Hardening (score.sh, hooks, hookify) + install.sh
Semana 2  ████████ README rewrite + verificacion end-to-end
          --- GATE: tests pasan, install.sh funciona, e2e OK ---
Semana 3  ████████ Discord posts + awesome-list PRs + /forge learn (start) + auto mode audit
Semana 4  ████████ /forge learn (finish) + articulo tecnico
Semana 5  ████░░░░ tdd stack + /forge status output + PermissionDenied hook
Semana 6  ██░░░░░░ Buffer / feedback / modes (si hay senal)
          --- GATE: senales especificas por feature ---
Semana 7+ ░░░░░░░░ /forge promote, /schedule, runtime injection (si hay demanda)
```

## Esfuerzo total

| Fase | Horas | Periodo | Gate |
|------|-------|---------|------|
| Fase 1 | ~12-16h | 2 semanas | Ninguno — ejecutar |
| Fase 2 | ~22-28h | 4 semanas | Hardening completo + install.sh funcional |
| Fase 3 | ~17-22h | Condicional | Senal especifica por feature |
| Community | 2-3h/sem ongoing | — | — |

---

## Metricas de exito

| Metrica | Semana 2 | Semana 6 | Semana 12 |
|---------|----------|----------|-----------|
| GitHub stars | — | 30+ | 150+ |
| Clones/semana | — | 30+ | 80+ |
| Issues/PRs externos | — | 3+ | 8+ |
| Proyectos en registry (propios) | 12 | 12 | 12 |
| Proyectos en registry (otros) | 0 | 1+ | 3+ |
| Awesome-list entries | 0 | 2+ | 3 |
| Bugs reportados post-launch | — | <3 | <5 |

Semana 2 no tiene metricas externas porque es fase de hardening (no hay lanzamiento publico todavia).
Si semana 6 no alcanza 30 stars -> pivotar distribucion a YouTube/tutorial video en lugar de texto.

---

## Lo que NO se hace (y por que)

| Feature | Razon de exclusion |
|---|---|
| 100+ skills genericos | No es el juego. Documentar "Works with" y listo. |
| Web dashboard | Terminal-native es el posicionamiento. `/forge status` con colores basta. |
| npm install / CLI npm | Destruye zero-deps. install.sh cubre el gap. |
| Code Graph (Joern/CodeQL) | Deps pesadas. `/forge learn` cubre 80% del valor para config generation. |
| LLM-driven CLAUDE.md generation | Trade-off intencional: deterministico > inteligente. `/forge learn` enriquece post-bootstrap. |
| Multi-platform nativo | dotforge gestiona, exporta a destinos. `/forge export` ya resuelve esto. |
| Windows nativo (PowerShell/CMD) | dotforge es bash-only. Usuarios Windows usan WSL o Git Bash. Mantener dos codebases no justifica el ROI. |
| modes/ sin senal | No hay mecanismo runtime hoy; competidores tienen traccion. Solo si hay demanda. |

---

## Versioning

| Entregable | Version |
|---|---|
| Hardening + install.sh + README rewrite + docs | **v2.9.0** |
| /forge learn + auto mode audit + tdd stack | **v3.0.0** |
| /forge promote + scheduled audits | **v3.1.0** |
