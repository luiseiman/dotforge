# Patrones de Prompting para Claude Code

## 1. Fórmula base universal

```
## ROL
Sos un [rol] con [X años] de experiencia en [dominio].

## CONTEXTO
[Situación actual del proyecto/problema]

## TAREA
[Qué necesitás exactamente]

## CONSTRAINTS
- No [restricción 1]
- No [restricción 2]

## OUTPUT FORMAT
[Cómo querés la respuesta]

## EJEMPLO
[1-2 ejemplos del formato esperado]
```

---

## 2. Ultrathink (por @DataChaz)

Prepend para problemas complejos:

```
Think step by step. Before answering:
1. ANALYZE: List all explicit and implicit requirements
2. EXPLORE: Consider at least 3 different approaches
3. EVALUATE: Compare trade-offs of each
4. DECIDE: Choose the best and explain WHY
5. IMPLEMENT: Only then provide the solution
```

Uso: diseño arquitectónico, decisiones con trade-offs, debugging complejo.

---

## 3. Chain of Thought forzado

```
Antes de responder, completá explícitamente:
PASO 1: Todos los requisitos (explícitos e implícitos)
PASO 2: Al menos 2 alternativas
PASO 3: Trade-offs de cada una
PASO 4: Tu decisión y por qué
PASO 5: Recién entonces la solución
```

---

## 4. Prompts negativos (restricciones)

```
RESTRICCIONES:
- NO uses librerías externas sin justificación
- NO refactorices código que no pedí
- NO agregues features no solicitadas
- NO hagas suposiciones — preguntá primero
- NO cambies nombres de archivos/funciones existentes
```

---

## 5. Few-shot (mostrar formato)

Dar 1-2 ejemplos del output esperado ANTES de pedir el resultado. Claude replicará estructura y nivel de detalle.

---

## 6. Auto-revisión crítica

Después de una respuesta:
```
Revisá tu respuesta anterior:
1. ¿Qué tiene de incorrecto?
2. ¿Qué casos edge no consideraste?
3. ¿Qué mejorarías?
Dame la versión mejorada.
```

---

## 7. Roleplay para feedback duro

```
Actuá como un senior engineer con 15 años de experiencia que da feedback muy directo.
Revisá este código y decime exactamente qué está mal y cómo lo harías vos.
```

---

## 8. Refactoring estructurado

```
Refactorizá en este orden de prioridad:
1. Correctitud (todos los casos)
2. Legibilidad (sin comentarios innecesarios)
3. Performance (solo si hay problema real)
4. Elegancia (idiomático en [lenguaje])
Mostrá ANTES y DESPUÉS con explicación de cada cambio.
```

---

## 9. Contexto inicial para vibe coding

```
- Stack: [tecnologías exactas]
- Audiencia: [quién lo usa]
- Objetivo: [qué construís en 2 oraciones]
- Constraints: [limitaciones reales]
- Tiempo: [para priorizar scope]
```

---

## 10. Esqueleto primero

```
Primero creá solo la estructura de carpetas + archivos vacíos + CLAUDE.md.
Sin implementación. Esperá mi OK antes de implementar.
```

---

## Templates listos

### Nuevo proyecto
```
Stack: [tecnologías]
El proyecto hace: [2 oraciones]
Antes de escribir código:
1. Sugerí estructura de carpetas
2. Listá dependencias principales
3. Explicá decisiones arquitectónicas
Esperá mi OK antes de crear archivos.
```

### Debug
```
Error en [lenguaje/framework]:
ERROR: [stack trace completo]
CÓDIGO: [código relevante]
CONTEXTO: Ocurre cuando [situación]. Ya intenté: [qué probé]
Analizá paso a paso y dame la solución.
```

### Code review
```
Code review como senior para producción:
1. Bugs y casos edge
2. Problemas de seguridad
3. Performance
4. Legibilidad
5. Best practices de [lenguaje]
Para cada problema: issue + impacto + fix.
Al final código corregido completo.
CÓDIGO: [tu código]
```
