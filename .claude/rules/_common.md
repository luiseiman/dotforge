---
globs: "**/*.md,**/*.sh,**/*.yml,**/*.json,**/*.tmpl"
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
