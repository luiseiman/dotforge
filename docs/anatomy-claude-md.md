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
