---
globs: "**/*.md,**/*.sh,**/*.yml,**/*.json,**/*.tmpl,**/*.py,**/*.ts,**/*.tsx,**/*.swift"
---

# Reglas de código

Reglas técnicas por proyecto. Las reglas de comportamiento (comunicación, planificación, autonomía) están en el CLAUDE.md global y no se repiten acá.

## Git
- Commits atómicos: un cambio lógico por commit
- Mensajes en imperativo, primera línea <72 chars
- No commitear .env, secrets, keys, credenciales
- No force push a main/master sin confirmación explícita
- Branch naming: feature/, fix/, refactor/, chore/

## Naming
- Variables/funciones descriptivas, no abreviaciones crípticas
- Constantes en UPPER_SNAKE_CASE
- No single-letter variables excepto iteradores (i, j, k) y lambdas

## Testing
- Funcionalidad nueva → test obligatorio
- Nombres de test descriptivos: test_<qué>_<condición>_<resultado_esperado>
- No mockear lo que se puede testear de verdad

## Errores
- Nunca catch vacío — siempre log o re-raise
- No exponer stack traces al usuario final

## Seguridad
- Inputs del usuario: sanitizar siempre
- Sin credenciales hardcodeadas — usar variables de entorno
- Queries parametrizadas (no string interpolation)
- Rate limiting en endpoints públicos

## Scope
- Solo modificar archivos estrictamente necesarios
- No agregar features no solicitadas

## Prompt Language
- All Claude-consumed content (rules, agent prompts, skill steps, system prompts) MUST be in English
- User-facing content (docs, CLAUDE.md project descriptions, changelog) may be in Spanish
- Prompts must be compact: high information density, no filler words, no hedging
- One instruction per line, imperative mood, no "please" or "you should consider"
- If a rule can be expressed in fewer words without losing meaning, rewrite it shorter

## Practice Capture
After completing a task, check if any of these signals are present:
- A workaround was needed because the obvious approach failed
- A bug required more than one fix attempt to resolve
- An architectural or config decision involved real trade-offs
- A tool, flag, or API behavior was non-obvious or surprising
- A rule in CLAUDE.md or a stack rule was missing and would have prevented the problem

If ANY signal is present, suggest at the end of your response:
```
💡 This looks generalizable. Run `/cap "<one-line summary>"` to capture it.
```
Do NOT suggest for: trivial tasks, routine edits, tasks where the first approach worked cleanly.
Threshold: if you had to reason about it or backtrack, suggest it. If not, stay silent.
