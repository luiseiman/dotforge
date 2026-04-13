# Decisiones cerradas para dotforge v3.0

Este documento lista decisiones que NO se reabren en el plan de v3.0.
Cualquier objeción debe apuntar a implementación o a decisiones aún
abiertas, no a renegociar estas.

## Semántica de enforcement

Cinco niveles en escalación de severidad:

| Nivel | Mecanismo | Ve el agente | Override |
|-------|-----------|--------------|----------|
| silent | exit 0 | Nada | No aplica |
| nudge | exit 0 + stdout breve (1 línea) | Recordatorio neutral | No aplica |
| warning | exit 0 + stdout JSON `systemMessage` (2-4 líneas) | Advertencia clara: behavior, expectativa, corrección | No aplica |
| soft_block | JSON `permissionDecision: "deny"` + `override_allowed: true` | Bloqueo con instrucción de corrección u override | Sí, auditado |
| hard_block | JSON `permissionDecision: "deny"` + `override_allowed: false` | Bloqueo definitivo | No en 3.0 |

- Override permitido únicamente en soft_block.
- hard_block sin override en 3.0 por diseño. Sin esta regla, hard_block
  es soft_block con nombre más agresivo.

## Reglas de conteo

- Una tool call produce máximo una violación por behavior, aunque
  matchee múltiples triggers internos del mismo behavior.
- Contador por sesión y por behavior.
- Incrementa antes de calcular nivel efectivo.
- Escalación se resuelve sobre contador ya incrementado.

## Escalación

- Evaluada contra contador del behavior en la sesión actual.
- Thresholds definidos en campo `enforcement.escalation` del behavior.
- Nivel efectivo puede solo subir dentro de la sesión, no bajar.

## Auditoría de overrides

Triple escritura:

1. `.forge/audit/overrides.log` — append-only, permanente, nunca se borra
2. `.forge/runtime/state.json` — scope sesión, se purga con TTL
3. `registry` / insights agregados — métricas para `/forge audit`

Cada override registra: timestamp, session_id, behavior_id, action/tool,
reason corta si existe, contador acumulado al momento del override.

## Runtime

- Archivo único `.forge/runtime/state.json`
- Sesiones como keys por session_id
- TTL 24h sobre último acceso (no sobre creación)
- Locking atómico para concurrencia: mkdir-based (POSIX-portable, macOS-compatible). Caso real: multi-agente con VPS + local + Telegram

## Evaluación múltiple

- Orden de evaluación: declaración en `behaviors/index.yaml`
- Primer block (soft o hard) corta la cadena
- Niveles no-bloqueantes (silent, nudge, warning) se acumulan y se muestran todos
- silent siempre corre (registra telemetría)

## Schema

- Separación `policy` (qué esperamos) vs `rendering` (cómo se comunica)
- DSL declarativa acotada, no expresiones sandboxed
- Primitivos sobre `tool_input` y `session_state`
- Behavior que no se expresa con los primitivos no entra al catálogo 3.0
- Campo `scope` reservado con valores `session | task | project`,
  implementado solo `session` en 3.0
- Campo `schema_version` en todo behavior
- Campo `applies_to.agents` reservado en schema, implementación básica en 3.0

## Rollout

- Alpha privada corta: 1 semana, 3-5 usuarios técnicos
- Al menos uno con CLI local pura, al menos uno con flujo remoto
- 4 gates para abrir beta pública:
  1. search-first escala de nudge a soft_block correctamente
  2. Override auditado en los 3 lugares
  3. Status refleja contadores reales
  4. Telegram/VPS no deforma warning ni soft_block

## Posicionamiento

- v2.9 cierra etapa config-manager
- v3.0 abre etapa behavior-governance
- Evolutivo, no pivotal
- La base de 2.9 queda intacta
- Diferencial en governance + UX + integración, no en completitud de features
