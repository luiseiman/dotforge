> **[English](#best-practices--claude-code-march-2026)** | **[Español](#mejores-prácticas--claude-code-marzo-2026)**

# Best Practices — Claude Code (March 2026)

Source of truth for claude-kit. Compiled from official documentation, community, and hands-on experience.

---

## 1. CLAUDE.md — The project's brain

### Recommended structure
```
# CLAUDE.md — project-name
## Build & Development       ← exact commands (build, test, lint, run)
## Stack                     ← technologies with versions
## Architecture              ← folder structure + data flow
## Conventions               ← naming, error handling, testing
## Working Rules             ← scope, plan mode, verification
## Known Errors              ← reference to CLAUDE_ERRORS.md
```

### Golden rules
- Keep <100 lines. If it grows, modularize with `@path/to/import`
- Each line must pass: "Would Claude fail without this?" If not → cut it
- Update at the end of each session with relevant changes
- Don't duplicate what's in rules/ — CLAUDE.md is overview, rules/ is detail

### Modularization
For large projects, use imports:
```
@.claude/rules/backend.md
@.claude/rules/frontend.md
```
Rules with `globs:` frontmatter load eagerly at session start. For lazy loading (on file match only), use `paths:` as unquoted CSV with `alwaysApply: false`.

---

## 2. Project configuration (.claude/)

### settings.json — Permissions
```json
{
  "permissions": {
    "allow": ["Bash(git *)", "Read", "Write", "Edit", "Glob", "Grep"],
    "deny": ["Bash(rm -rf /)", "Read(.env)", "Read(*.key)"]
  },
  "hooks": { ... }
}
```
- ALWAYS include a security deny list
- Minimum necessary permissions — no `Bash(*)`
- settings.json → project (commit). settings.local.json → personal (don't commit)

### Rules — Automatic context
- Two loading modes: `globs:` for eager loading (always in context), `paths:` + `alwaysApply: false` for lazy loading (on file match only)
- `paths:` must be unquoted CSV — YAML arrays and quoted strings fail silently
- One rule per domain (backend, frontend, infra, testing)
- Include "Gotchas" at the top of each rule
- Keep <50 lines per rule

### Hooks — Automation
Available events: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `PreCompact`, `PostCompact`, `SessionStart`, `SessionEnd`, `PermissionRequest`, `SubagentStart`, `CwdChanged`, `StopFailure`

Essential hooks:
1. **block-destructive** (PreToolUse:Bash) — block rm -rf, DROP, force push
2. **lint-on-save** (PostToolUse:Write|Edit) — auto lint per stack
3. **post-compact** (PostCompact) — capture summary to `.claude/session/last-compact.md`
4. **session-restore** (SessionStart, source:compact) — re-inject last-compact.md on resume

Exit codes: 0 = ok, 1 = error (warning), 2 = block (stop operation)

### Domain rules — Project knowledge layer

Domain rules live in `.claude/rules/domain/` and represent accumulated knowledge about the project's specific domain (business logic, architectural decisions, non-obvious constraints). Unlike stack rules (how to code), domain rules encode what the project does and why.

**When to use each layer:**

| Layer | Use for |
|-------|---------|
| `CLAUDE.md` | Overview: role, stack, build commands, architecture overview |
| `template/rules/` + `stacks/*/rules/` | Technical patterns: how to code in this stack |
| `.claude/rules/domain/` | Domain knowledge: what this project does, decisions with context |

**Extended frontmatter for domain rules:**
```yaml
---
globs: "src/payments/**"
domain: payments
last_verified: 2026-03-30
domain_source: code-review
---
```

Use `/forge domain extract` to generate initial domain rules from existing code. Use `/forge domain list` to see current coverage.

### Commands — Repeatable actions
Files in `.claude/commands/name.md`. Invocable via `/name`.
- Use `$ARGUMENTS` to receive parameters
- Document clear, sequential Steps
- Reference env vars with defaults: `${VAR:-default}`

### Skills — Reusable capabilities
Files in `.claude/skills/name/SKILL.md` with frontmatter:
```yaml
---
name: skill-name
description: What it does and when to use it
---
```
Auto-discovery: loaded automatically without restart.

---

## 3. Subagents — Specialization

### When to use subagents
- Codebase exploration (protect main context)
- Broad searches (>3 queries)
- Independent parallelizable tasks
- Read-only audits

### Architect-Implementer pattern
| Role | Tools | Usage |
|------|-------|-------|
| Explore | Read, Grep, Glob | Explore codebase |
| Plan | Read, Grep, Glob | Design approach |
| Implementer | Write, Edit, Bash | Code + tests |
| Auditor | Read, Grep, Glob | Read-only |

### Available agents (claude-kit)

| Agent | Role | Permissions | Color |
|-------|------|-------------|-------|
| `researcher` | Exploration, search, context | Read-only | Cyan |
| `architect` | Design, tradeoffs, ADRs | Read-only | Purple |
| `implementer` | Code, tests, verification | Read-write | Green |
| `code-reviewer` | Review by severity | Read-only | Yellow |
| `security-auditor` | Vulnerabilities, secrets, CVEs | Read-only | Red |
| `test-runner` | Tests, coverage, diagnostics | Read-write | Blue |

### Typical chains
- **New feature**: researcher → architect → implementer → test-runner → code-reviewer
- **Bug fix**: researcher → implementer → code-reviewer
- **Pre-deploy**: security-auditor → code-reviewer
- **Cross-component refactor**: Agent Team (lead + 3-4 teammates)

### Rules
- Invoke with `Agent(subagent_type="<name>", ...)` — NEVER via bash
- One task per subagent
- Intermediate tool calls DON'T return to parent — only the final message
- Provide enough context at spawn (don't assume inheritance)
- Subagents can't invoke other subagents — chain from the main thread
- Agent Teams: only for refactors ≥3 independent files, requires prior plan

### Agent Teams (experimental)
Enable: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- Lead coordinates, does NOT implement
- Max 3-4 teammates (diminishing returns)
- Each teammate = full session (~5x tokens)
- Verify they don't edit the same files

### Model selection

Use the right model for the task — defined in `template/rules/model-routing.md`:

- **haiku**: search, test execution, repetitive transforms, short lookups
- **sonnet**: implementation, debugging, code review, documentation
- **opus**: architecture decisions, security audits, ambiguous high-stakes tasks

Escalate when: multiple valid approaches with real consequences, production/security risk, or unclear approach after 2 attempts.

Agents have explicit model defaults. Override only when the task warrants it.

---

## 4. Project lifecycle

### Integrated workflow
```
CONTEXT → PLANNING → EXECUTION → VALIDATION → REFINEMENT → DOCUMENTATION
```

1. **Context**: CLAUDE.md + rules + memory
2. **Planning**: Plan Mode for >3 files. Ask for plan before code.
3. **Execution**: Small iterations. One feature/fix at a time.
4. **Validation**: Tests + lint + review
5. **Refinement**: Improve prompt before editing code
6. **Documentation**: Update CLAUDE.md with changes

### Plan Mode
- Activate for tasks >3 files or architectural changes
- Discrete steps: input → action → verification
- If something goes wrong → stop, review, re-plan

### Context management
- Set `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75` to compact at 75% — gives post-compact hook more room
- After completing a significant task, update `.claude/session/last-compact.md` proactively
- The PostCompact → session-restore cycle recovers context automatically; don't rely on it exclusively
- Use subagents for token-heavy exploration to preserve the main thread

### Evolutionary error tracking
- CLAUDE_ERRORS.md: per-project log
- Recurring errors (3+ times) → promote to rule in CLAUDE.md or rules/
- Auto-memory for cross-project errors

---

## 5. Effective prompting

### Specific instructions
BAD: "Build me a trading app"
GOOD: "REST API in FastAPI: POST /orders (body: symbol, quantity, side), GET /positions, auth via X-API-Key, tests with pytest"

### Ask for plan before code
"Before writing code, describe: what files you'll create/modify, what specific changes, risks. Wait for my OK."

### Incremental iteration
Step 1: model → review → Step 2: endpoint → review → Step 3: tests

### Scope control
"Only modify strictly necessary files. Don't refactor or improve anything I didn't ask for."

### Give complete errors
Paste full stack trace + relevant code + context of when it occurs.

---

## 6. Security

### Pre-deploy checklist
- [ ] User inputs sanitized
- [ ] No hardcoded credentials (use .env)
- [ ] Errors don't expose sensitive info to user
- [ ] Parameterized queries (no string interpolation)
- [ ] Rate limiting on public endpoints
- [ ] Authentication on endpoints that require it
- [ ] HTTPS in production
- [ ] .env in .gitignore
- [ ] Dependencies without known vulnerabilities
- [ ] Logs don't contain sensitive data

### settings.json security
- deny list: .env, *.key, *.pem, *credentials*
- block-destructive hook always active
- No Bash(*) — explicit permissions

---

# Mejores Prácticas — Claude Code (Marzo 2026)

Fuente de verdad para claude-kit. Compilado de documentación oficial, comunidad, y experiencia propia.

---

## 1. CLAUDE.md — El cerebro del proyecto

### Estructura recomendada
```
# CLAUDE.md — nombre-proyecto
## Build & Development       ← comandos exactos (build, test, lint, run)
## Stack                     ← tecnologías con versiones
## Arquitectura              ← estructura de carpetas + flujo de datos
## Convenciones              ← naming, error handling, testing
## Reglas de trabajo         ← scope, plan mode, verificación
## Errores conocidos         ← referencia a CLAUDE_ERRORS.md
```

### Reglas de oro
- Mantener <100 líneas. Si crece, modularizar con `@path/to/import`
- Cada línea debe pasar: "¿Claude falla sin esto?" Si no → cortar
- Actualizar al final de cada sesión con cambios relevantes
- No duplicar lo que está en rules/ — CLAUDE.md es overview, rules/ es detalle

### Modularización
Para proyectos grandes, usar imports:
```
@.claude/rules/backend.md
@.claude/rules/frontend.md
```
Las rules con frontmatter `globs:` se cargan eager al inicio de sesión. Para lazy loading (solo cuando se toca un archivo que matchea), usar `paths:` como CSV sin quotes con `alwaysApply: false`.

---

## 2. Configuración de proyecto (.claude/)

### settings.json — Permisos
```json
{
  "permissions": {
    "allow": ["Bash(git *)", "Read", "Write", "Edit", "Glob", "Grep"],
    "deny": ["Bash(rm -rf /)", "Read(.env)", "Read(*.key)"]
  },
  "hooks": { ... }
}
```
- SIEMPRE incluir deny list de seguridad
- Permisos mínimos necesarios — no `Bash(*)`
- settings.json → proyecto (commitear). settings.local.json → personal (no commitear)

### Rules — Contexto automático
- Dos modos de carga: `globs:` para eager loading (siempre en contexto), `paths:` + `alwaysApply: false` para lazy loading (solo al tocar archivos que matchean)
- `paths:` debe ser CSV sin quotes — YAML arrays y strings entre comillas fallan silenciosamente
- Una rule por dominio (backend, frontend, infra, testing)
- Incluir "Gotchas" al inicio de cada rule
- Mantener <50 líneas por rule

### Hooks — Automatización
Eventos disponibles: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `PreCompact`, `PostCompact`, `SessionStart`, `SessionEnd`, `PermissionRequest`, `SubagentStart`, `CwdChanged`, `StopFailure`

Hooks esenciales:
1. **block-destructive** (PreToolUse:Bash) — bloquear rm -rf, DROP, force push
2. **lint-on-save** (PostToolUse:Write|Edit) — lint automático por stack
3. **post-compact** (PostCompact) — captura resumen en `.claude/session/last-compact.md`
4. **session-restore** (SessionStart, source:compact) — re-inyecta last-compact.md al retomar

Exit codes: 0 = ok, 1 = error (warning), 2 = block (detener operación)

### Domain rules — Capa de conocimiento del proyecto

Las domain rules viven en `.claude/rules/domain/` y representan conocimiento acumulado sobre el dominio específico del proyecto (lógica de negocio, decisiones arquitectónicas, restricciones no-obvias). A diferencia de las stack rules (cómo codificar), las domain rules codifican qué hace el proyecto y por qué.

**Cuándo usar cada capa:**

| Capa | Para qué |
|------|----------|
| `CLAUDE.md` | Overview: rol, stack, comandos de build, resumen arquitectónico |
| `template/rules/` + `stacks/*/rules/` | Patrones técnicos: cómo codificar en este stack |
| `.claude/rules/domain/` | Conocimiento de dominio: qué hace este proyecto, decisiones con contexto |

**Frontmatter extendido para domain rules:**
```yaml
---
globs: "src/payments/**"
domain: payments
last_verified: 2026-03-30
domain_source: code-review
---
```

Usar `/forge domain extract` para generar domain rules iniciales desde código existente. Usar `/forge domain list` para ver cobertura actual.

### Commands — Acciones repetibles
Archivos en `.claude/commands/nombre.md`. Invocables via `/nombre`.
- Usar `$ARGUMENTS` para recibir parámetros
- Documentar Steps claros y secuenciales
- Referenciar variables de entorno con defaults: `${VAR:-default}`

### Skills — Capacidades reutilizables
Archivos en `.claude/skills/nombre/SKILL.md` con frontmatter:
```yaml
---
name: skill-name
description: Qué hace y cuándo usarlo
---
```
Auto-discovery: se cargan automáticamente sin restart.

---

## 3. Subagentes — Especialización

### Cuándo usar subagentes
- Exploración de codebase (proteger contexto principal)
- Búsquedas amplias (>3 queries)
- Tareas independientes paralelizables
- Auditorías read-only

### Patrón Architect-Implementer
| Rol | Tools | Uso |
|-----|-------|-----|
| Explore | Read, Grep, Glob | Explorar codebase |
| Plan | Read, Grep, Glob | Diseñar approach |
| Implementer | Write, Edit, Bash | Código + tests |
| Auditor | Read, Grep, Glob | Solo lectura |

### Agentes disponibles (claude-kit)

| Agente | Rol | Permisos | Color |
|--------|-----|----------|-------|
| `researcher` | Exploración, búsquedas, contexto | Read-only | Cyan |
| `architect` | Diseño, tradeoffs, ADRs | Read-only | Purple |
| `implementer` | Código, tests, verificación | Read-write | Green |
| `code-reviewer` | Review por severidad | Read-only | Yellow |
| `security-auditor` | Vulnerabilidades, secrets, CVEs | Read-only | Red |
| `test-runner` | Tests, coverage, diagnóstico | Read-write | Blue |

### Cadenas típicas
- **Feature nueva**: researcher → architect → implementer → test-runner → code-reviewer
- **Bug fix**: researcher → implementer → code-reviewer
- **Pre-deploy**: security-auditor → code-reviewer
- **Refactor cross-component**: Agent Team (lead + 3-4 teammates)

### Reglas
- Invocar con `Agent(subagent_type="<name>", ...)` — NUNCA via bash
- Una tarea por subagente
- Intermediate tool calls NO vuelven al padre — solo el mensaje final
- Dar contexto suficiente al spawn (no asumir que hereda)
- Subagents no pueden invocar otros subagents — encadenar desde el thread principal
- Agent Teams: solo para refactors ≥3 archivos independientes, requiere plan previo

### Agent Teams (experimental)
Activar: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- Lead coordina, NO implementa
- Max 3-4 teammates (rendimientos decrecientes)
- Cada teammate = sesión completa (~5x tokens)
- Verificar que no editen los mismos archivos

### Selección de modelo

Usar el modelo correcto por tipo de tarea — definido en `template/rules/model-routing.md`:

- **haiku**: búsquedas, ejecución de tests, transforms repetitivos, lookups cortos
- **sonnet**: implementación, debugging, code review, documentación
- **opus**: decisiones arquitectónicas, auditorías de seguridad, tareas ambiguas de alto impacto

Escalar cuando: múltiples approaches válidos con consecuencias reales, riesgo en producción/seguridad, o approach poco claro después de 2 intentos.

Los agentes tienen modelos explícitos por defecto. Overridear solo cuando la tarea lo justifica.

---

## 4. Ciclo de vida del proyecto

### Workflow integrado
```
CONTEXTO → PLANIFICACIÓN → EJECUCIÓN → VALIDACIÓN → REFINAMIENTO → DOCUMENTACIÓN
```

1. **Contexto**: CLAUDE.md + rules + memory
2. **Planificación**: Plan Mode para >3 archivos. Pedir plan antes de código.
3. **Ejecución**: Iteraciones pequeñas. Un feature/fix a la vez.
4. **Validación**: Tests + lint + review
5. **Refinamiento**: Mejorar prompt antes de editar código
6. **Documentación**: Actualizar CLAUDE.md con cambios

### Plan Mode
- Activar para tareas >3 archivos o cambio arquitectónico
- Pasos discretos: entrada → acción → verificación
- Si algo se tuerce → parar, revisar, re-planificar

### Gestión de contexto
- Configurar `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75` para compactar al 75% — le da más espacio al hook post-compact
- Después de completar una tarea significativa, actualizar `.claude/session/last-compact.md` proactivamente
- El ciclo PostCompact → session-restore recupera contexto automáticamente; no depender exclusivamente de eso
- Usar subagentes para exploración intensiva en tokens para preservar el thread principal

### Error tracking evolutivo
- CLAUDE_ERRORS.md: registro por proyecto
- Errores recurrentes (3+ veces) → promover a regla en CLAUDE.md o rules/
- Auto-memory para errores cross-proyecto

---

## 5. Prompting efectivo

### Instrucciones específicas
MAL: "Construí una app de trading"
BIEN: "API REST en FastAPI: POST /orders (body: symbol, quantity, side), GET /positions, auth via X-API-Key, tests con pytest"

### Pedir plan antes de código
"Antes de escribir código, describí: qué archivos vas a crear/modificar, qué cambios específicos, riesgos. Esperá mi OK."

### Iteración incremental
Paso 1: modelo → revisar → Paso 2: endpoint → revisar → Paso 3: tests

### Control de scope
"Solo modificá los archivos estrictamente necesarios. No refactorices ni mejores nada que no pedí."

### Dar errores completos
Pegar stack trace completo + código relevante + contexto de cuándo ocurre.

---

## 6. Seguridad

### Checklist pre-deploy
- [ ] Inputs del usuario sanitizados
- [ ] Sin credenciales hardcodeadas (usar .env)
- [ ] Errores no exponen info sensible al usuario
- [ ] Queries parametrizadas (no string interpolation)
- [ ] Rate limiting en endpoints públicos
- [ ] Autenticación en endpoints que lo requieran
- [ ] HTTPS en producción
- [ ] .env en .gitignore
- [ ] Dependencies sin vulnerabilidades conocidas
- [ ] Logs no contienen datos sensibles

### settings.json security
- deny list: .env, *.key, *.pem, *credentials*
- Hook block-destructive siempre activo
- No Bash(*) — permisos explícitos
