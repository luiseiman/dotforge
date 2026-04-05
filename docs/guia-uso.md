# Guía de Uso — claude-kit

**Versión:** 2.8.0
**Fecha:** 2026-04-05

claude-kit es una fábrica de configuración para Claude Code. Genera y mantiene la carpeta `.claude/` de tus proyectos: reglas, hooks, permisos, agentes y comandos. Todo es markdown + shell scripts — no hay código de aplicación.

---

## Tabla de contenidos

1. [Instalación (paso cero)](#1-instalación-paso-cero)
2. [Proyecto nuevo (desde cero)](#2-proyecto-nuevo-desde-cero)
3. [Proyecto existente (sin claude-kit)](#3-proyecto-existente-sin-claude-kit)
4. [Proyecto ya usando claude-kit (mantenimiento)](#4-proyecto-ya-usando-claude-kit-mantenimiento)
5. [Referencia de comandos](#5-referencia-de-comandos)
6. [Stacks disponibles](#6-stacks-disponibles)
7. [Sistema de auditoría](#7-sistema-de-auditoría)
8. [Pipeline de prácticas](#8-pipeline-de-prácticas)
9. [Perfiles de bootstrap](#9-perfiles-de-bootstrap)
10. [Estructura generada](#10-estructura-generada)
11. [Validación de configuración](#11-validación-de-configuración)
12. [FAQ](#12-faq)
13. [Templates MCP](#13-templates-mcp)
14. [Model routing](#14-model-routing)
15. [Comandos de domain knowledge](#15-comandos-de-domain-knowledge)
16. [Continuidad de contexto](#16-continuidad-de-contexto)

---

## 1. Instalación (paso cero)

Antes de usar cualquier comando `/forge`, necesitás instalar la infraestructura global en `~/.claude/`. Esto se hace **una sola vez** por máquina.

### Opción A: Script directo

```bash
cd ~/Documents/GitHub/claude-kit   # o donde tengas clonado claude-kit
./global/sync.sh
```

### Opción B: Desde Claude Code

```
/forge global sync
```

### ¿Qué instala?

| Componente | Ubicación | Método |
|-----------|-----------|--------|
| Skills (15) | `~/.claude/skills/` | Symlinks |
| Agents (7) | `~/.claude/agents/` | Symlinks |
| Comando `/forge` | `~/.claude/commands/forge.md` | Copia (Claude Code no sigue symlinks para commands) |
| CLAUDE.md global | `~/.claude/CLAUDE.md` | Merge con preservación de `<!-- forge:custom -->` |
| settings.json global | `~/.claude/settings.json` | Merge de deny list + hooks |

**Multiplataforma:** Linux, macOS, WSL, Git Bash. Usa copias como fallback si los symlinks no funcionan.

### Verificar instalación

```
/forge global status
```

Muestra:
```
═══ GLOBAL STATUS ═══
CLAUDE.md:     ✓ sincronizado
settings.json: deny list 9 items (plantilla: 9)
Skills:        15/15 instalados
Agents:        7/7 instalados
Commands:      forge.md (archivo)
```

---

## 2. Proyecto nuevo (desde cero)

### Paso a paso

```bash
# 1. Crear carpeta e inicializar git
mkdir mi-proyecto
cd mi-proyecto
git init

# 2. Abrir Claude Code
claude

# 3. Dentro de Claude Code, ejecutar:
/forge bootstrap
```

### ¿Qué pasa durante el bootstrap?

1. **Detecta stack** — escanea archivos del proyecto (package.json, pyproject.toml, go.mod, etc.) para identificar tecnologías. En un proyecto vacío, te pregunta qué stacks querés.

2. **Pide confirmación** — muestra qué va a crear:
   ```
   Profile: standard
   Stack detectado: react-vite-ts, supabase
   Se creará:
   - CLAUDE.md (plantilla base + stack rules)
   - .claude/settings.json (permisos base + stack)
   - .claude/rules/ (reglas comunes + stack)
   - .claude/hooks/ (block-destructive + lint)
   - .claude/commands/ (audit, health, debug, review)
   - .claude/agents/ + orchestration
   - CLAUDE_ERRORS.md (vacío, para registro de errores)

   ¿Proceder? (sí/no)
   ```

3. **Genera archivos** — crea todo, mergeando permisos de cada stack detectado.

4. **Genera manifest** — `.claude/.forge-manifest.json` con hashes SHA256 de cada archivo (baseline para futuros diffs y syncs).

### Después del bootstrap

1. **Personalizar CLAUDE.md** — editá la sección debajo de `<!-- forge:custom -->` con la descripción específica de tu proyecto: arquitectura, endpoints, decisiones de diseño, etc. Todo lo que esté encima del marker es "managed" por forge (se actualiza en syncs). Todo debajo es tuyo y nunca se toca.

2. **Verificar** — ejecutar:
   ```
   /forge audit
   ```
   Te da un score de 0-10 con gaps específicos a corregir.

---

## 3. Proyecto existente (sin claude-kit)

El proceso es **idéntico** al proyecto nuevo. Bootstrap detecta los archivos que ya existen para elegir stacks automáticamente.

```bash
cd ~/Documents/GitHub/mi-proyecto-existente
claude
```

```
/forge bootstrap
```

### Diferencias con proyecto nuevo

- **Detección de stack más precisa** — tiene package.json, go.mod, etc. reales para analizar.
- **Si ya existe `.claude/` parcial** — bootstrap lo respeta y completa lo que falta.
- **Si ya existe CLAUDE.md** — te pregunta si querés preservar el contenido existente dentro de `<!-- forge:custom -->`.

### Post-bootstrap en proyecto existente

Es más importante personalizar CLAUDE.md con:
- Comandos build/test exactos del proyecto
- Arquitectura y estructura de directorios
- Convenciones específicas del equipo
- Variables de entorno necesarias

```
/forge audit
```

Si el score es < 9, el reporte te dice exactamente qué falta.

---

## 4. Proyecto ya usando claude-kit (mantenimiento)

### Ciclo regular de actualización

```
/forge diff     # ¿cambió algo en claude-kit desde mi último sync?
/forge sync     # aplicar actualizaciones
/forge audit    # verificar score post-sync
```

#### `/forge diff` — ver qué cambió

Compara tu `.forge-manifest.json` local contra la versión actual de claude-kit. Muestra:
- Archivos nuevos en la plantilla que no tenés
- Archivos que cambiaron en la plantilla (reglas, hooks, settings)
- Archivos que **vos** modificaste localmente (para no perderlos)
- Recomendación: sync sí/no

#### `/forge sync` — aplicar cambios

Principio fundamental: **merge, no overwrite**. Nunca sobrescribe sin confirmación.

1. Muestra dry-run completo (archivos nuevos, actualizados, sin cambios, ignorados)
2. Podés aprobar todo, nada, o seleccionar individualmente
3. Preserva siempre:
   - Sección `<!-- forge:custom -->` de CLAUDE.md
   - `settings.local.json` (tu configuración personal)
   - Archivos que modificaste localmente (te avisa y pregunta)
4. Actualiza manifest y registry
5. Ejecuta audit automáticamente al final para mostrar score antes/después

#### `/forge audit` — verificar estado

Score 0-10 normalizado contra un checklist de 12 items.

### Dashboard multi-proyecto

```
/forge status
```

```
═══ REGISTRO claude-kit ═══
Proyecto         Stack                    Score   Trend     Última auditoría
──────────────────────────────────────────────────────────────────────────
my-api           python-fastapi, docker   9.5     ▁▃▇ ↑    2026-03-19
my-frontend      react-vite-ts            7.2     ▇▅▃ ↓    2026-03-18
```

Alertas automáticas:
- Score que baja >1.5 puntos
- Proyectos con versión vieja de claude-kit

### Análisis de sesiones

```
/forge insights
```

Cruza CLAUDE_ERRORS.md + git log + agent-memory + registry para generar:
- Patrones de error recurrentes
- Archivos más editados (hot files)
- Uso de agentes
- Tendencia de score
- Recomendaciones accionables
- Top 3 hallazgos van automáticamente al pipeline de prácticas

### Nuclear option: reset

```
/forge reset
```

Borra `.claude/` y re-ejecuta bootstrap completo. Pero:
- Backup obligatorio en `.claude.backup-YYYY-MM-DD/`
- Preserva `settings.local.json` y `CLAUDE_ERRORS.md`
- Muestra diff entre backup y nuevo
- Ofrece rollback inmediato

---

## 5. Referencia de comandos

### Comandos de proyecto

| Comando | Descripción |
|---------|-------------|
| `/forge init` | Setup rápido: auto-detecta stack, 3 preguntas, config personalizada |
| `/forge bootstrap` | Bootstrap completo con preview y confirmación |
| `/forge bootstrap --profile minimal` | Bootstrap con solo lo esencial |
| `/forge bootstrap --profile full` | Bootstrap con todo incluido |
| `/forge sync` | Actualizar config preservando customizaciones |
| `/forge audit` | Auditar contra checklist, score 0-10 |
| `/forge diff` | Ver cambios pendientes desde último sync |
| `/forge reset` | Restaurar desde cero (con backup) |
| `/forge insights` | Analizar sesiones pasadas |
| `/forge rule-check` | Detectar reglas inertes (cruzar globs vs git history) |
| `/forge benchmark` | Comparar config full vs minimal en tareas estandarizadas |
| `/forge plugin` | Generar paquete de plugin para el marketplace de Claude Code |
| `/forge unregister` | Eliminar proyecto del registro |
| `/forge export cursor` | Exportar config a Cursor |
| `/forge export codex` | Exportar config a Codex |
| `/forge export windsurf` | Exportar config a Windsurf |
| `/forge export openclaw` | Exportar config a OpenClaw |
| `/forge domain extract` | Extraer domain rules del código del proyecto |
| `/forge domain sync-vault` | Sincronizar domain rules al vault de Obsidian |
| `/forge domain list` | Listar domain rules con cobertura |

### Comandos globales

| Comando | Descripción |
|---------|-------------|
| `/forge global sync` | Instalar/actualizar `~/.claude/` |
| `/forge global status` | Estado de `~/.claude/` vs plantilla |
| `/forge status` | Dashboard multi-proyecto con scores |
| `/forge version` | Mostrar versión de claude-kit |

### Pipeline de prácticas

| Comando | Descripción |
|---------|-------------|
| `/forge capture "texto"` | Registrar un insight en inbox (explícito) |
| `/forge capture` | Modo auto-detección: analiza contexto, propone insight, pide Y/n/edit |
| `/cap` | Alias shorthand de `/forge capture` (modo auto-detección) |
| `/forge update` | Procesar inbox → evaluar → incorporar |
| `/forge watch` | Buscar actualizaciones en docs de Anthropic |
| `/forge scout` | Revisar repos curados por patterns |
| `/forge inbox` | Listar prácticas pendientes |
| `/forge pipeline` | Estado del ciclo de prácticas |

---

## 6. Stacks disponibles

15 stacks que se detectan automáticamente y se pueden combinar (multi-stack):

| Stack | Indicadores de detección |
|-------|-------------------------|
| **python-fastapi** | `pyproject.toml`, `requirements.txt`, `Pipfile` |
| **react-vite-ts** | `package.json` con react/vite/next |
| **node-express** | `package.json` con express/fastify (sin react/vite/next) |
| **swift-swiftui** | `Package.swift`, `*.xcodeproj`, `*.xcworkspace` |
| **java-spring** | `pom.xml`, `build.gradle`, `*.java` con Spring imports |
| **go-api** | `go.mod`, `go.sum`, `**/*.go` |
| **supabase** | `supabase/`, `supabase.ts`, `@supabase/supabase-js` en package.json |
| **docker-deploy** | `docker-compose*`, `Dockerfile*` |
| **gcp-cloud-run** | `app.yaml`, `cloudbuild.yaml`, `gcloud` en scripts |
| **aws-deploy** | `cdk.json`, `template.yaml` (SAM), `samconfig.toml` |
| **redis** | `redis` en requirements.txt/pyproject.toml |
| **data-analysis** | `*.ipynb`, `*.csv`, `*.xlsx` prominentes |
| **devcontainer** | `.devcontainer/`, `devcontainer.json` |

Cada stack aporta:
- `rules/*.md` — reglas contextuales con `globs:` frontmatter (eager loading). Para lazy loading, usar `paths:` como CSV sin quotes con `alwaysApply: false`
- `settings.json.partial` — permisos y hooks específicos del stack
- (Opcional) `hooks/*.sh` — hooks de validación específicos

**Multi-stack:** si tu proyecto usa Python + Docker + Redis, los tres stacks se detectan y sus permisos se mergean (unión de sets, sin duplicados).

---

## 7. Sistema de auditoría

### Checklist (12 items)

#### Obligatorios (0-2 puntos cada uno, peso 70%)

| # | Item | 0 | 1 | 2 |
|---|------|---|---|---|
| 1 | **CLAUDE.md** | No existe | Existe pero incompleto (<20 líneas útiles) | Completo: stack, arquitectura, comandos build/test, convenciones |
| 2 | **settings.json** | No existe | Sin deny list o permisos excesivos | Permisos explícitos + deny list de seguridad |
| 3 | **Rules contextuales** | No existen | Sin frontmatter `globs:`/`paths:` | Rules con globs específicos por área + modo de carga correcto |
| 4 | **Hook block-destructive** | No existe | Existe pero mal configurado | Existe + ejecutable + wired en settings.json |
| 5 | **Comandos build/test** | No documentados | En README pero no en CLAUDE.md | Documentados en CLAUDE.md con comandos exactos |

#### Recomendados (0-1 punto cada uno, peso 30%)

| # | Item | Criterio |
|---|------|----------|
| 6 | CLAUDE_ERRORS.md | Existe con formato de tabla y tipos válidos |
| 7 | Hook de lint | Configurado para el stack + ejecutable |
| 8 | Comandos custom | Al menos 1 comando relevante |
| 9 | Memory del proyecto | Existe con contexto útil |
| 10 | Agentes | Instalados + regla de orquestación activa |
| 11 | .gitignore | Protege .env, *.key, *.pem, credentials |
| 12 | Prompt injection scan | Sin patrones sospechosos en rules/CLAUDE.md |

### Fórmula de scoring

```
score = obligatorio × 0.7 + recomendado × (3.0 / 7)
```

- Obligatorios perfectos sin recomendados = **7.0** (Bueno)
- Para llegar a 9+ necesitás al menos 4 recomendados

### Cap de seguridad

Si falta **settings.json** (item 2) o **hook block-destructive** (item 4), el score máximo es **6.0** — un proyecto sin seguridad básica no puede ser "Excelente".

### Niveles

| Score | Nivel | Acción |
|-------|-------|--------|
| 9-10 | Excelente | Solo ajustes menores |
| 7-8.9 | Bueno | Faltan algunos recomendados |
| 5-6.9 | Aceptable | Gaps importantes, necesita sync |
| 3-4.9 | Deficiente | Faltan obligatorios, bootstrap parcial |
| 0-2.9 | Crítico | Bootstrap completo necesario |

---

## 8. Pipeline de prácticas

Las prácticas son insights, patterns y lecciones aprendidas que alimentan la evolución de claude-kit.

### Ciclo de vida

```
inbox/ → evaluating/ → active/ → deprecated/
```

### Fuentes de entrada

| Fuente | Comando | Descripción |
|--------|---------|-------------|
| Manual | `/forge capture "texto"` | Registrar un insight descubierto durante el trabajo |
| Automática | Hook `detect-claude-changes.sh` | Detecta cambios en `.claude/` al finalizar sesiones |
| Web | `/forge watch` | Novedades de docs oficiales de Anthropic |
| Repos | `/forge scout` | Patterns de repos curados en `practices/sources.yml` |
| Análisis | `/forge insights` | Top 3 hallazgos de sesiones pasadas |
| Auditoría | `/forge audit` | Gaps detectados generan prácticas automáticamente |

### Procesamiento

```
/forge update
```

Ejecuta 3 fases:
1. **Evaluar** — clasifica inbox en aceptar/rechazar/posponer (criterios: actionable, nueva, generalizable)
2. **Incorporar** — aplica cambios aceptados a template/stacks/rules de claude-kit, bump version
3. **Propagar** — lista proyectos que necesitan sync (NO auto-propaga, solo informa)

### Monitoreo

```
/forge inbox      # listar prácticas pendientes
/forge pipeline   # conteo por estado
```

```
═══ PIPELINE DE PRÁCTICAS ═══
Inbox:      3 prácticas pendientes
Evaluando:  1 en evaluación
Activas:    12 incorporadas
Deprecadas: 2 retiradas
Última actualización: 2026-03-20
```

---

## 9. Perfiles de bootstrap

| Componente | minimal | standard | full |
|-----------|---------|----------|------|
| CLAUDE.md + settings.json | ✓ | ✓ | ✓ |
| Hook block-destructive | ✓ | ✓ | ✓ |
| Rules (_common + stack) | ✓ | ✓ | ✓ |
| Hook lint-on-save | — | ✓ | ✓ |
| Comandos (audit, health, debug, review) | — | ✓ | ✓ |
| Agentes (7) + orquestación | — | ✓ | ✓ |
| CLAUDE_ERRORS.md | — | ✓ (vacío) | ✓ (pre-poblado) |
| Rule memory.md | — | ✓ | ✓ |
| Hook warn-missing-test | — | — | ✓ |
| agent-memory/ (seed files) | — | — | ✓ |

**Cuándo usar cada perfil:**
- **minimal** — proyectos chicos, scripts, prototipos. Lo mínimo para tener seguridad y reglas.
- **standard** (default) — la mayoría de proyectos. Balance entre cobertura y complejidad.
- **full** — proyectos grandes o críticos donde querés máxima cobertura desde el día uno.

---

## 10. Estructura generada

Después de `/forge bootstrap` con perfil `standard`, tu proyecto queda así:

```
mi-proyecto/
├── CLAUDE.md                          # Contexto del proyecto para Claude
├── CLAUDE_ERRORS.md                   # Registro evolutivo de errores
├── .claude/
│   ├── settings.json                  # Permisos, deny list, hooks
│   ├── settings.local.json            # Tu config personal (no se toca en syncs)
│   ├── .forge-manifest.json           # Hashes SHA256 (baseline para diff/sync)
│   ├── rules/
│   │   ├── _common.md                 # Reglas generales (git, naming, testing, seguridad)
│   │   ├── agents.md                  # Protocolo de orquestación de agentes
│   │   ├── memory.md                  # Política de memoria
│   │   └── <stack>-*.md               # Reglas específicas del stack
│   ├── hooks/
│   │   ├── block-destructive.sh       # Bloquea rm -rf, DROP, force push
│   │   └── lint-on-save.sh            # Lint automático post-write/edit
│   ├── commands/
│   │   ├── audit.md                   # /audit — auditar proyecto
│   │   ├── health.md                  # /health — health check
│   │   ├── debug.md                   # /debug — debug asistido
│   │   └── review.md                  # /review — code review
│   └── agents/
│       ├── researcher.md              # Exploración read-only
│       ├── architect.md               # Diseño y tradeoffs
│       ├── implementer.md             # Código + tests
│       ├── code-reviewer.md           # Review por severidad
│       ├── security-auditor.md        # Vulnerabilidades
│       └── test-runner.md             # Tests + coverage
└── ...                                # tu código
```

### Archivos clave

**CLAUDE.md** — lo más importante. Es el contexto que Claude lee al iniciar cada sesión. Contiene:
- Nombre del proyecto y stack
- Arquitectura y estructura
- Comandos exactos de build/test
- Convenciones del equipo
- Todo debajo de `<!-- forge:custom -->` es tuyo

**settings.json** — permisos granulares:
- `allow`: qué herramientas puede usar Claude sin preguntar (git, ls, read, etc.)
- `deny`: qué está prohibido siempre (rm -rf, force push, leer .env)
- `hooks`: scripts que se ejecutan antes/después de cada acción

**block-destructive.sh** — el hook más importante. Intercepta comandos Bash y bloquea patrones peligrosos. Tres perfiles configurables via `FORGE_HOOK_PROFILE`:
- `minimal`: solo lo catastrófico (rm -rf /, force push main)
- `standard` (default): + DROP TABLE, git reset --hard, chmod 777
- `strict`: + curl|sh, eval, dd if=/dev/

---

## 11. Validación de configuración

claude-kit no solo verifica si la configuración existe — mide si es efectiva.

### Métricas de sesión (automático)

Después del bootstrap, cada sesión genera métricas en `~/.claude/metrics/{proyecto}/`:

```json
{
  "sessions": 1,
  "errors_added": 0,
  "hook_blocks": 1,
  "lint_blocks": 3,
  "files_touched": 12,
  "rules_matched": 9,
  "rule_coverage": 0.75,
  "commits": 4
}
```

Los hooks cuentan bloqueos automáticamente. `session-report.sh` (Stop hook) agrega y guarda los datos.

Para generar también un `SESSION_REPORT.md` legible:
```bash
export FORGE_SESSION_REPORT=true
```

### Efectividad de reglas

```
/forge rule-check
```

Cruza globs de reglas contra `git log` para clasificar cada regla:

| Clasificación | Match rate | Acción |
|---------------|-----------|--------|
| **Activa** | > 50% | Mantener |
| **Ocasional** | 10-50% | Evaluar si vale los tokens de contexto |
| **Inerte** | < 10% | Candidata a eliminar |

También reporta **cobertura**: qué porcentaje de archivos tocados cae bajo al menos una regla.

### Benchmark

```
/forge benchmark
```

Ejecuta la misma tarea estándar en dos worktrees aislados:
1. **Config completa** — tu `.claude/` completo
2. **Config mínima** — solo `CLAUDE.md` + `settings.json` básico

Compara: archivos creados, tests pasando, lint issues, errores.

**Costo:** ejecuta Claude Code dos veces. Siempre opt-in con confirmación.

### Coherencia de configuración

```bash
bash tests/test-config.sh
```

30 checks que validan consistencia interna: hooks existen, globs válidos, deny list completa, sin contradicciones.

---

## 12. FAQ

### ¿Puedo usar claude-kit sin el CLAUDE.md global?

Sí, pero perdés las reglas de comportamiento (comunicación, planificación, partner crítico). El CLAUDE.md global define **cómo** trabaja Claude. El de proyecto define **en qué** trabaja.

### ¿Qué pasa si modifico un archivo managed por forge?

`/forge diff` lo detecta y `/forge sync` te avisa antes de sobrescribir. Podés aceptar o rechazar cada archivo individualmente.

### ¿Cómo agrego un stack que no existe?

Crear directorio en `claude-kit/stacks/<nombre>/` con:
- `rules/*.md` — reglas con frontmatter `globs:` (eager) o `paths:` + `alwaysApply: false` (lazy)
- `settings.json.partial` — permisos y hooks

Ver `docs/creating-stacks.md` para detalles.

### ¿Puedo exportar la config a Cursor/Codex?

```
/forge export cursor
/forge export codex
/forge export windsurf
/forge export openclaw
```

Los hooks se convierten a instrucciones textuales (sin enforcement fuera de Claude Code).

### ¿Cómo actualizo claude-kit en sí?

```bash
cd ~/Documents/GitHub/claude-kit
git pull
./global/sync.sh              # actualiza ~/.claude/
```

Después, en cada proyecto:
```
/forge diff    # ver qué cambió
/forge sync    # aplicar
```

### ¿Qué es el registry?

`registry/projects.yml` es un archivo YAML que trackea todos los proyectos bootstrapped: nombre, path, stacks, score, historial de auditorías. `/forge status` lo lee para mostrar el dashboard.

### ¿Los agentes son obligatorios?

No. Con perfil `minimal` no se instalan. Con `standard` y `full` sí, pero Claude decide cuándo usarlos según la regla de orquestación en `.claude/rules/agents.md`.

---

## Flujo visual completo

```
┌─────────────────────────────────────────────────┐
│                  INSTALACIÓN                     │
│  ./global/sync.sh  →  ~/.claude/ configurado     │
│  (una sola vez por máquina)                      │
└──────────────────────┬──────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────┐     ┌──────────────────────┐
│  PROYECTO NUEVO  │     │  PROYECTO EXISTENTE  │
│  o SIN claude-kit│     │  CON claude-kit      │
├──────────────────┤     ├──────────────────────┤
│ /forge bootstrap │     │ /forge diff          │
│ /forge audit     │     │ /forge sync          │
│ editar CLAUDE.md │     │ /forge audit         │
│   (forge:custom) │     │                      │
└────────┬─────────┘     └──────────┬───────────┘
         │                          │
         └──────────┬───────────────┘
                    ▼
         ┌──────────────────┐
         │  MANTENIMIENTO   │
         ├──────────────────┤
         │ /forge diff      │  ← ¿hay updates?
         │ /forge sync      │  ← aplicar
         │ /forge audit     │  ← verificar
         │ /forge insights  │  ← optimizar
         │ /forge status    │  ← dashboard
         └────────┬─────────┘
                  │
                  ▼
         ┌──────────────────┐
         │  APRENDIZAJE     │
         ├──────────────────┤
         │ /forge capture   │  ← registrar insight
         │ /forge watch     │  ← docs Anthropic
         │ /forge scout     │  ← repos curados
         │ /forge update    │  ← procesar inbox
         │ /forge pipeline  │  ← ver estado
         └──────────────────┘
```

---

## 13. Templates MCP

Los servidores MCP extienden Claude Code con herramientas para servicios externos. claude-kit provee templates listos en `mcp/` con configuración, permisos y reglas de uso.

### Templates disponibles

| Servidor | Paquete | Herramientas |
|----------|---------|-------------|
| `github` | `@modelcontextprotocol/server-github` | Issues, PRs, búsqueda de código, contenidos |
| `postgres` | `@modelcontextprotocol/server-postgres` | Queries SQL read-only, inspección de schema |
| `supabase` | `@supabase/mcp-server-supabase` | Proyectos, tablas, migraciones, branches, logs |
| `redis` | `mcp-server-redis` (community) | Inspección de keys, monitoreo de streams |
| `slack` | `@modelcontextprotocol/server-slack` | Mensajes, canales, búsqueda |

### Instalación

**Paso 1 — Registrar el servidor globalmente (una vez por máquina):**
Copiar la entrada `mcpServers` de `mcp/<server>/config.json` a `~/.claude/settings.json`. Reemplazar `${ENV_VAR}` con valores reales o setear env vars en el perfil del shell.

**Paso 2 — Instalar reglas del proyecto:**
```bash
cp mcp/<server>/rules.md .claude/rules/mcp-<server>.md
```

O dejar que `/forge bootstrap` lo maneje automáticamente.

### Postura de seguridad

Cada template define tres niveles:
- **Auto-permitido**: operaciones de lectura (list, get, search)
- **Requiere prompt**: operaciones de escritura no en allow/deny
- **Siempre denegado**: operaciones destructivas (delete_project, merge_pull_request, flushdb)

---

## 14. Model routing

claude-kit incluye criterios explícitos de selección de modelo en `template/rules/model-routing.md`.

### Criterios

| Modelo | Usar para |
|--------|-----------|
| **haiku** | Búsquedas, tests, transforms repetitivos, lookups cortos |
| **sonnet** | Implementación, bug fixing, code review, debugging, docs |
| **opus** | Decisiones arquitectónicas, auditorías de seguridad, tareas ambiguas de alto riesgo |

### Asignaciones de agentes

| Agente | Modelo | Razón |
|--------|--------|-------|
| researcher | haiku | Exploración — velocidad sobre profundidad |
| test-runner | haiku | Ejecutar y reportar — no requiere razonamiento |
| implementer | sonnet | Trabajo de implementación estándar |
| code-reviewer | sonnet | Review enfocado |
| session-reviewer | sonnet | Análisis de patrones |
| architect | opus | Tradeoffs con consecuencias duraderas |
| security-auditor | opus | Perder una vulnerabilidad tiene consecuencias en prod |

### Regla de escalación

Empezar con sonnet. Escalar a opus cuando: 2+ approaches válidos con consecuencias reales, tarea toca seguridad/integridad de datos/producción, o después de 2 intentos el approach sigue poco claro.

---

## 15. Comandos de domain knowledge

Las domain rules capturan qué hace un proyecto, no solo cómo codificar en él. Viven en `.claude/rules/domain/` y nunca se sobrescriben por `/forge sync`.

### Comandos

| Comando | Descripción |
|---------|-------------|
| `/forge domain extract` | Analiza código, CLAUDE.md e historial git para generar domain rules iniciales |
| `/forge domain sync-vault` | Sincroniza domain rules a `decisions/` en tu vault de Obsidian |
| `/forge domain list` | Lista domain rules existentes con globs y fecha de verificación |

### Frontmatter de domain rules

```yaml
---
globs: "src/billing/**"
domain: billing
last_verified: 2026-03-30
domain_source: code-review   # code-review | git-history | manual | practice
---
```

Para lazy loading en proyectos grandes con muchas domain rules, usar `paths:` como CSV sin quotes con `alwaysApply: false` en vez de `globs:`.

### Cuándo ejecutar `/forge domain extract`

- Después del bootstrap, antes de empezar a trabajar — establece la baseline
- Después de un cambio arquitectónico grande — captura la nueva realidad
- Al onboardear a un proyecto existente — más rápido que leer todo el código

---

## 16. Continuidad de contexto

Claude Code compacta la ventana de contexto cuando se llena. El par de hooks PostCompact + session-restore preserva la continuidad de tareas entre compactaciones.

### Cómo funciona

```
1. Contexto se llena → compactación triggered
2. post-compact.sh escribe:
   - compact_summary (qué se estaba haciendo)
   - git state (branch actual, últimos commits, archivos dirty)
   → .claude/session/last-compact.md

3. Siguiente sesión arranca (source="compact")
4. session-restore.sh lee last-compact.md
   → re-inyecta como contexto antes del primer mensaje del usuario
5. Claude retoma consciente del estado anterior
```

### Configuración

```bash
# Compactar al 75% en vez de 90% — más espacio para el resumen
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75
```

Agregar a `~/.zshrc` o `~/.bashrc` para persistir.

### Actualizaciones proactivas

Claude también actualiza `.claude/session/last-compact.md` después de completar tareas significativas — no solo en eventos de compactación. Esto se define en `template/rules/_common.md`. El archivo es efímero (scoped a la sesión) y no se commitea a git.
