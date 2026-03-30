> **[English](#memory-strategy)** | **[Español](#estrategia-de-memoria)**

# Memory Strategy

How claude-kit manages memory across projects. Five layers, each with a distinct purpose.

## The 5 Layers

```
Layer          What              Where                     Injection    Maintained by
─────────────────────────────────────────────────────────────────────────────────────
1. CLAUDE.md   Prescriptive      <project>/CLAUDE.md       Auto-always  Human
               (what to do)      ~/.claude/CLAUDE.md

2. Rules       Contextual        .claude/rules/*.md        Auto-by-glob Human via sync
               (when to do it)

3. Errors      Known issues      CLAUDE_ERRORS.md          Auto-always  Claude + Human
               (what NOT to do)  (via memory.md rule)

4. Auto-memory Discoveries       ~/.claude/projects/       Auto-always  Claude Code
               (what was found)  */memory/

5. Agent mem   Per-role learning  .claude/agent-memory/     Auto-on-use  Each agent
               (what each role   <agent-name>/
               learned)
```

## How They Interact

```
                    PRESCRIPTIVE                    DESCRIPTIVE
                    (human-curated)                 (auto-accumulated)
                    ────────────────                ──────────────────
Always loaded:      CLAUDE.md ←──────────────────→ Auto-memory
                    Rules (by glob)                 Agent memory (on invoke)
                    Errors (by memory.md rule)

                    ↕ promote (3+ occurrences)      ↕ discovered patterns

                    _common.md / stack rules ←────── CLAUDE_ERRORS.md
```

- **CLAUDE.md** and **auto-memory** both describe the project, but CLAUDE.md is what SHOULD happen (conventions, architecture) while auto-memory is what WAS discovered (build quirks, debugging insights). They diverge — that's expected.
- **CLAUDE_ERRORS.md** feeds **rules**: when an error repeats 3+ times, the derived rule should be promoted to `_common.md` or a stack-specific rule. This is manual — the memory.md rule reminds Claude to do it.
- **Agent memory** is independent per agent. The code-reviewer accumulates code quality patterns. The architect accumulates design decisions. They don't cross-pollinate — each agent's memory is its own.

## Design Decisions

### Why not centralize errors?
Each project has its own CLAUDE_ERRORS.md. Cross-project patterns get captured via `/forge capture` into the practices pipeline, not via a central error file. This keeps errors contextual to their project.

### Why no memory for researcher and test-runner?
These agents are **transactional**: they explore/test and return a summary. Their value is in the report, not in accumulated knowledge. Adding memory would make them slower (reading past context) without benefit.

### Why autoMemoryEnabled in template?
Claude Code's auto-memory captures insights that no other layer does: build command quirks, environment issues, debugging paths. It's the cheapest form of cross-session learning. Enabled by default in the template; can be disabled per-project in settings.local.json.

### Why a separate memory.md rule?
CLAUDE_ERRORS.md needs to be read before modifying code, but injecting the entire file as a rule would waste context on every tool use. Instead, the memory.md rule is a lightweight reminder that tells Claude to READ the file when relevant — not a dump of its contents.

## Context Continuity (PostCompact cycle)

Claude Code compacts the context window when it approaches the token limit. Without intervention, resuming after compaction means Claude has no memory of what was just done.

**How it works:**

```
Session running → context fills → compaction triggered
       ↓
post-compact.sh (PostCompact hook)
  writes compact_summary + git state → .claude/session/last-compact.md
       ↓
Next session starts with source="compact"
  session-restore.sh (SessionStart hook)
  re-injects last-compact.md as context
       ↓
Claude resumes with full task awareness
```

**Configuration:** set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75` in your shell to trigger compaction at 75% instead of the default (90%), giving `post-compact.sh` more room to write useful summaries.

Claude also updates `last-compact.md` proactively after significant tasks (defined in `template/rules/_common.md`) — not just on compaction events.

**Files:**

| File | Purpose |
|------|---------|
| `template/hooks/post-compact.sh` | PostCompact hook — captures summary + git state |
| `template/hooks/session-restore.sh` | SessionStart hook — re-injects summary on resume |
| `template/rules/_common.md` | Context Continuity section — proactive update rules |

## Template Files

| File | Purpose |
|------|---------|
| `template/settings.json.tmpl` | `autoMemoryEnabled: true` |
| `template/rules/memory.md` | Memory policy (error reading, agent memory, auto-memory) |
| `template/CLAUDE_ERRORS.md` | Empty template with table structure |
| `agents/*.md` | `memory: project` on 4 agents, commented on 2 |

---

> **[English](#memory-strategy)** | **[Español](#estrategia-de-memoria)**

# Estrategia de Memoria

Cómo claude-kit gestiona la memoria entre proyectos. Cinco capas, cada una con un propósito distinto.

## Las 5 Capas

```
Capa           Qué               Dónde                     Inyección      Mantenida por
──────────────────────────────────────────────────────────────────────────────────────────
1. CLAUDE.md   Prescriptivo      <proyecto>/CLAUDE.md      Auto-siempre   Humano
               (qué hacer)       ~/.claude/CLAUDE.md

2. Rules       Contextual        .claude/rules/*.md        Auto-por-glob  Humano vía sync
               (cuándo hacerlo)

3. Errors      Problemas         CLAUDE_ERRORS.md          Auto-siempre   Claude + Humano
               conocidos         (vía regla memory.md)
               (qué NO hacer)

4. Auto-memory Descubrimientos   ~/.claude/projects/       Auto-siempre   Claude Code
               (qué se encontró) */memory/

5. Agent mem   Aprendizaje       .claude/agent-memory/     Auto-al-usar   Cada agente
               por rol           <nombre-agente>/
               (qué aprendió
               cada rol)
```

## Cómo Interactúan

```
                    PRESCRIPTIVO                    DESCRIPTIVO
                    (curado por humanos)            (acumulado automáticamente)
                    ────────────────                ──────────────────
Siempre cargado:    CLAUDE.md ←──────────────────→ Auto-memory
                    Rules (por glob)                Agent memory (al invocar)
                    Errors (por regla memory.md)

                    ↕ promover (3+ ocurrencias)     ↕ patrones descubiertos

                    _common.md / stack rules ←────── CLAUDE_ERRORS.md
```

- **CLAUDE.md** y **auto-memory** ambos describen el proyecto, pero CLAUDE.md es lo que DEBERÍA pasar (convenciones, arquitectura) mientras que auto-memory es lo que SE DESCUBRIÓ (peculiaridades del build, insights de debugging). Divergen — eso es esperado.
- **CLAUDE_ERRORS.md** alimenta las **reglas**: cuando un error se repite 3+ veces, la regla derivada debe promoverse a `_common.md` o a una regla específica del stack. Esto es manual — la regla memory.md le recuerda a Claude que lo haga.
- **Agent memory** es independiente por agente. El code-reviewer acumula patrones de calidad de código. El architect acumula decisiones de diseño. No se cruzan — la memoria de cada agente es propia.

## Decisiones de Diseño

### ¿Por qué no centralizar los errores?
Cada proyecto tiene su propio CLAUDE_ERRORS.md. Los patrones entre proyectos se capturan vía `/forge capture` hacia el pipeline de prácticas, no mediante un archivo central de errores. Esto mantiene los errores contextuales a su proyecto.

### ¿Por qué no hay memoria para researcher y test-runner?
Estos agentes son **transaccionales**: exploran/testean y devuelven un resumen. Su valor está en el reporte, no en el conocimiento acumulado. Agregar memoria los haría más lentos (leyendo contexto pasado) sin beneficio.

### ¿Por qué autoMemoryEnabled en el template?
La auto-memory de Claude Code captura insights que ninguna otra capa captura: peculiaridades de comandos de build, problemas de entorno, caminos de debugging. Es la forma más económica de aprendizaje entre sesiones. Habilitada por defecto en el template; se puede deshabilitar por proyecto en settings.local.json.

### ¿Por qué una regla memory.md separada?
CLAUDE_ERRORS.md necesita leerse antes de modificar código, pero inyectar el archivo completo como regla desperdiciaría contexto en cada uso de herramienta. En su lugar, la regla memory.md es un recordatorio liviano que le dice a Claude que LEA el archivo cuando sea relevante — no un volcado de su contenido.

## Context Continuity (ciclo PostCompact)

Claude Code compacta el contexto cuando se acerca al límite de tokens. Sin intervención, retomar después de una compactación significa que Claude no recuerda lo que acababa de hacer.

**Cómo funciona:**

```
Sesión en curso → contexto se llena → compactación disparada
       ↓
post-compact.sh (hook PostCompact)
  escribe compact_summary + estado git → .claude/session/last-compact.md
       ↓
Nueva sesión inicia con source="compact"
  session-restore.sh (hook SessionStart)
  re-inyecta last-compact.md como contexto
       ↓
Claude retoma con conciencia completa de la tarea
```

**Configuración:** establecer `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75` en el shell para disparar compactación al 75% en lugar del default (90%), dándole más espacio a `post-compact.sh` para escribir resúmenes útiles.

Claude también actualiza `last-compact.md` proactivamente después de tareas significativas (definidas en `template/rules/_common.md`) — no solo en eventos de compactación.

**Archivos:**

| Archivo | Propósito |
|---------|-----------|
| `template/hooks/post-compact.sh` | Hook PostCompact — captura resumen + estado git |
| `template/hooks/session-restore.sh` | Hook SessionStart — re-inyecta resumen al retomar |
| `template/rules/_common.md` | Sección Context Continuity — reglas de actualización proactiva |

## Archivos del Template

| Archivo | Propósito |
|---------|-----------|
| `template/settings.json.tmpl` | `autoMemoryEnabled: true` |
| `template/rules/memory.md` | Política de memoria (lectura de errores, memoria de agentes, auto-memory) |
| `template/CLAUDE_ERRORS.md` | Template vacío con estructura de tabla |
| `agents/*.md` | `memory: project` en 4 agentes, comentado en 2 |
