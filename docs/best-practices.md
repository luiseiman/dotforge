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
