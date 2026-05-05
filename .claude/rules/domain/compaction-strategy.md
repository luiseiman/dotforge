---
globs: "**/CLAUDE.md,**/rules/_common.md,**/rules/memory.md,**/agents/*.md,**/skills/loop/**,**/skills/schedule/**"
description: "Evidence-based compaction policy: when to compact manually vs auto, cache economy, /clear vs /compact"
domain: claude-code-engineering
last_verified: 2026-05-05
---

# Compaction Strategy (evidence-based)

## Operational threshold: 80%

Compactá manualmente al **80%** del context window, no antes ni después:

- **<70%**: el thread reciente todavía es útil, summary perdería detalle
- **70-80%**: zona OK para seguir, pero monitorear
- **80%**: **trigger operacional** (Daniel San hook, Avthar advice, X consensus)
- **>90%**: ya hay degradación medible (Chroma research, Liu et al.)
- **96.7%**: default auto-compact de Claude Code — **demasiado tarde**, perdés momentum

Para 1M context (Sonnet 4.6) → 800K tokens. Para 200K (Haiku) → 160K.

## /compact vs /clear vs subagent

| Situación | Acción |
|---|---|
| Cambio de tarea grande, mismo proyecto | `/forge compact-task` (preserva decisions, files, TODOs) |
| Tarea totalmente nueva, sin relación | `/clear` (reset total) |
| Tarea >10min con cambio de contexto | Subagent fresco (NO compact) |
| Cambio de proyecto | Nueva sesión, no compact |

## Anti-patterns confirmados por practitioners

- **Esperar al auto-compact** (96.7%): Avthar — "can hurt performance" mid-task
- **Compactar al 50%**: pérdida de thread reciente, summary acumula degradación al recompactar
- **`/compact` sin instrucciones**: defaults pueden descartar info que vos sabés que importa
- **Sesión >8h sin compactar**: el context rot es lineal-acelerado (Chroma)

## /compact con instructions custom

Siempre pasar hint:
```
/compact preserve: active task, files modified, decisions, pending TODOs, behaviors disabled, last commit. drop: tool output verbose, intermediate searches.
```

dotforge wrappers: `/forge compact-task` (con hint estandarizado) y `/forge context-status` (reporte sin compactar).

## Cache economy (lo que NO mide la academia)

Compactar **mata el cache**. Tradeoff real:
- Cache reads: 0.1× costo input
- Cache writes: 1.25× (5min TTL) o 2× (1h TTL)

Cada compactación = nuevo cache write. Métrica de salud > size del context: **cache hit rate**.

- `>80%` cache hits = sano
- `<60%` cache hits = compactación thrashing (compactás demasiado seguido)

Si tenés `<60%` cache hit rate, problema NO es context size — es frecuencia de compactación. Subí el threshold a 85% o usá subagentes.

## Subagentes para aislar contexto (Boris Cherny pattern)

Tareas con cambio de contexto neto (architecture → implementation, code review, security audit) → spawn subagent con context fresco. **No esperar a que el contexto principal se llene.**

## Re-anchoring de instrucciones críticas

Cada 20-25K tokens nuevos, re-inyectar instrucciones que el modelo debe sostener (ej. "preservar la convención X", "no tocar el módulo Y"). Mitiga "lost in the middle" (Liu et al.).

Implementación práctica: hooks `UserPromptSubmit` que inyectan recordatorios condicionales, o `additionalContext` en SubagentStart.

## Fuentes

- Liu et al. 2023 — "Lost in the Middle" (Stanford, ACL 2024). 30%+ accuracy loss en medio del contexto
- Chroma Research 2024 — "Context Rot" benchmark sobre 18 modelos. Degradación medible desde 50K tokens
- Greg Kamradt — Needle in Haystack benchmark
- Boris Cherny (Anthropic, X) — Plan acceptance auto-clears context
- Daniel San (X) — Hook al 80%, auto-compact OFF en producción
- Avthar (X) — `/compact` proactivo > auto-compact mid-task
- Paweł Huryn (X) — Cache economy domina decisión
