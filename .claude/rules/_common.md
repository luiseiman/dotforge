# Reglas universales

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
- Test falla → corregir antes de reportar
- Nombres de test descriptivos: test_<qué>_<condición>_<resultado_esperado>
- No mockear lo que se puede testear de verdad

## Errores
- Nunca catch vacío — siempre log o re-raise
- No exponer stack traces al usuario final
- Errores en producción → registrar en CLAUDE_ERRORS.md

## Seguridad
- Inputs del usuario: sanitizar siempre
- Sin credenciales hardcodeadas — usar variables de entorno
- Queries parametrizadas (no string interpolation)
- Rate limiting en endpoints públicos

## Scope
- Solo modificar archivos estrictamente necesarios
- No refactorizar lo que no se pidió
- No agregar features no solicitadas
- Tres líneas repetidas > abstracción prematura
