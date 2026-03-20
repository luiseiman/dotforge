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
Rules with `globs:` frontmatter auto-load by file path.

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
- `globs:` frontmatter for auto-load by file path
- One rule per domain (backend, frontend, infra, testing)
- Include "Gotchas" at the top of each rule
- Keep <50 lines per rule

### Hooks — Automation
Available events: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`

Essential hooks:
1. **block-destructive** (PreToolUse:Bash) — block rm -rf, DROP, force push
2. **lint-on-save** (PostToolUse:Write|Edit) — auto lint per stack

Exit codes: 0 = ok, 1 = error (warning), 2 = block (stop operation)

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
Las rules con frontmatter `globs:` se cargan automáticamente por path.

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
- Frontmatter `globs:` para auto-load por path de archivo
- Una rule por dominio (backend, frontend, infra, testing)
- Incluir "Gotchas" al inicio de cada rule
- Mantener <50 líneas por rule

### Hooks — Automatización
Eventos disponibles: `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`

Hooks esenciales:
1. **block-destructive** (PreToolUse:Bash) — bloquear rm -rf, DROP, force push
2. **lint-on-save** (PostToolUse:Write|Edit) — lint automático por stack

Exit codes: 0 = ok, 1 = error (warning), 2 = block (detener operación)

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
