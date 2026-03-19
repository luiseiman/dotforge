# Code Review

Ejecutá un code review como senior engineer para producción.

## Argumentos
$ARGUMENTS: archivos o directorio a revisar. Si está vacío, revisar archivos modificados (git diff --name-only).

## Proceso

1. Identificar archivos a revisar:
   - Si se proporcionaron archivos específicos, usar esos
   - Si no, `git diff --name-only` para archivos modificados
   - Si no hay diff, preguntar qué revisar

2. Evaluar en este orden de prioridad:

### Bugs y casos edge (crítico)
- Null/undefined no manejados
- Off-by-one errors
- Race conditions en async
- Inputs no validados

### Seguridad (crítico)
- SQL injection, XSS, secrets hardcodeados, permisos excesivos

### Performance (si hay problema real)
- N+1 queries, loops innecesarios, memory leaks

### Legibilidad y mantenibilidad
- Nombres descriptivos, funciones <50 líneas, single responsibility

3. Para cada problema:
```
🔴|🟡|🟢 [ÁREA] archivo:línea
Issue: qué está mal
Impacto: qué puede pasar
Fix: cómo corregirlo
```

4. Al final, código corregido completo de los archivos con problemas.
