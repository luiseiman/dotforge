---
name: capture-practice
description: Captura un insight o práctica descubierta durante el trabajo y la registra en claude-kit practices/inbox.
---

# Capturar Práctica

Registrar un insight, patrón, o lección aprendida en el inbox de claude-kit.

## Input
$ARGUMENTS contiene la descripción del insight. Puede ser:
- Texto libre: "ruff check --fix es mejor que ruff check porque corrige automáticamente"
- Referencia a algo que acaba de pasar: "el hook de lint debería ignorar archivos en migrations/"

## Paso 1: Parsear el insight

Extraer:
- **Qué**: la práctica o patrón descubierto
- **Por qué**: evidencia o contexto (proyecto actual, error que lo motivó)
- **Impacto**: qué archivos de claude-kit podrían cambiar
- **Tags**: categorización (hooks, rules, prompting, security, stack-specific, etc.)

## Paso 2: Validar duplicados

Antes de crear, verificar que no exista una práctica similar:
1. Buscar en `$CLAUDE_KIT_DIR/practices/active/` por título o tags similares
2. Buscar en `$CLAUDE_KIT_DIR/practices/inbox/` por título similar
3. Si hay duplicado → informar al usuario y preguntar si quiere actualizar la existente o crear nueva

## Paso 3: Generar archivo

Crear archivo en `$CLAUDE_KIT_DIR/practices/inbox/` con formato:

```yaml
---
id: practice-{{YYYY-MM-DD}}-{{slug}}
title: {{título corto}}
source: "experiencia propia"
source_type: experience
discovered: {{YYYY-MM-DD}}
status: inbox
tags: [{{tags}}]
tested_in: {{proyecto actual o null}}
incorporated_in: []
replaced_by: null
---

## Descripción
{{qué dice la práctica}}

## Evidencia
{{por qué funciona, contexto del descubrimiento}}

## Impacto en claude-kit
{{qué archivos habría que modificar}}

## Decisión
Pendiente
```

Nombre del archivo: `{{YYYY-MM-DD}}-{{slug}}.md`

## Paso 4: Confirmar

Mostrar:
```
✅ Práctica capturada: {{título}}
📁 practices/inbox/{{archivo}}
🏷️ Tags: {{tags}}

Próximo paso: /forge update evalúa prácticas pendientes del inbox.
```
