> **[English](#anatomy-of-a-good-claudemd)** | **[Español](#anatomía-de-un-buen-claudemd)**

# Anatomy of a good CLAUDE.md

## Principles

1. **Concise**: <100 lines. If it grows, modularize with rules/.
2. **Actionable**: every line must change Claude's behavior.
3. **Specific**: exact commands, real paths, concrete versions.
4. **Up to date**: reflect current state, not the past.

---

## Recommended structure

### 1. Build & Development (required)
```markdown
## Build & Development
- Build: `npm run build`
- Test: `npm run test`
- Lint: `npm run lint`
- Dev: `npm run dev`
```
Why first? It's what Claude needs most frequently.

### 2. Stack (required)
```markdown
## Stack
Python 3.12, FastAPI, Redis 7 Streams, React 19, TypeScript strict, Tailwind CSS
```
One line. No unnecessary explanations.

### 3. Architecture (recommended)
```markdown
## Architecture
/api → REST endpoints (thin, logic in /services)
/services → business logic
/models → types and validation
/tests → pytest (unit + integration)
```
Folder map + responsibility of each one.

### 4. Conventions (recommended)
```markdown
## Conventions
- snake_case for functions, PascalCase for classes
- Type hints on public functions
- Tests required for new functionality
- Error handling: never empty catch
```
Only what's not obvious from the language/framework.

### 5. Working rules (optional but useful)
```markdown
## Working rules
- Plan Mode for >3 files
- Don't refactor what wasn't asked
- Tests must pass before reporting "done"
```

### 6. Error reference (optional)
```markdown
## Known errors
See CLAUDE_ERRORS.md
```

---

## Anti-patterns

| Do | Don't |
|----|-------|
| Exact commands | "Run tests" without command |
| Specific versions | "Modern Python" |
| Rules in .claude/rules/ | Everything in CLAUDE.md (200+ lines) |
| Update post-session | Leave outdated |
| One rule per concept | Paragraphs of explanation |

---

## Quality test

Before finalizing a CLAUDE.md:
1. Can a fresh Claude build the project reading only this file?
2. Would each line change Claude's behavior if removed?
3. Is anything duplicated with rules/ or README?
4. Do the commands work if I copy-paste them?

---

# Anatomía de un buen CLAUDE.md

## Principios

1. **Conciso**: <100 líneas. Si crece, modularizar con rules/.
2. **Actionable**: cada línea debe cambiar el comportamiento de Claude.
3. **Específico**: comandos exactos, paths reales, versiones concretas.
4. **Actualizado**: reflejar el estado actual, no el pasado.

---

## Estructura recomendada

### 1. Build & Development (obligatorio)
```markdown
## Build & Development
- Build: `npm run build`
- Test: `npm run test`
- Lint: `npm run lint`
- Dev: `npm run dev`
```
¿Por qué primero? Es lo que Claude necesita más frecuentemente.

### 2. Stack (obligatorio)
```markdown
## Stack
Python 3.12, FastAPI, Redis 7 Streams, React 19, TypeScript strict, Tailwind CSS
```
Una línea. Sin explicaciones innecesarias.

### 3. Arquitectura (recomendado)
```markdown
## Arquitectura
/api → endpoints REST (thin, lógica en /services)
/services → lógica de negocio
/models → tipos y validación
/tests → pytest (unit + integration)
```
Mapa de carpetas + responsabilidad de cada una.

### 4. Convenciones (recomendado)
```markdown
## Convenciones
- snake_case para funciones, PascalCase para clases
- Type hints en funciones públicas
- Tests obligatorios para funcionalidad nueva
- Error handling: nunca catch vacío
```
Solo lo que no es obvio del lenguaje/framework.

### 5. Reglas de trabajo (opcional pero útil)
```markdown
## Reglas de trabajo
- Plan Mode para >3 archivos
- No refactorizar lo que no se pidió
- Tests deben pasar antes de reportar "listo"
```

### 6. Referencia a errores (opcional)
```markdown
## Errores conocidos
Ver CLAUDE_ERRORS.md
```

---

## Anti-patrones

| Hacer | No hacer |
|-------|----------|
| Comandos exactos | "Ejecutar tests" sin comando |
| Versiones específicas | "Python moderno" |
| Rules en .claude/rules/ | Todo en CLAUDE.md (200+ líneas) |
| Actualizar post-sesión | Dejar desactualizado |
| Una regla por concepto | Párrafos de explicación |

---

## Test de calidad

Antes de dar por terminado un CLAUDE.md:
1. ¿Un Claude nuevo puede buildear el proyecto leyendo solo este archivo?
2. ¿Cada línea cambiaría el comportamiento de Claude si se borrara?
3. ¿Hay algo duplicado con rules/ o README?
4. ¿Los comandos funcionan si los copio y pego?
