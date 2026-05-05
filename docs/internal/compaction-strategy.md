# Compaction Strategy — Operational Guide

**Política basada en evidencia académica (Liu, Chroma, Kamradt) + práctica de campo (Boris Cherny, Daniel San, Avthar, Paweł Huryn).**

> Status: **canonical** desde v3.7.1. Reemplaza la guía implícita "esperar al auto-compact" que dotforge tenía hasta v3.7.0.

## TL;DR

| Threshold | Acción |
|---|---|
| < 70% | Trabajar normal |
| 70-80% | Monitorear; planificar compact al próximo task break |
| **80%** | **`/forge compact-task` AHORA** (evidencia-based) |
| > 90% | Urgente. Hook `pre-compact-warning.sh` te alertará |
| 96.7% | Auto-compact dispara. Llegaste tarde. |

## Flow chart operacional

```
┌───────────────────────────┐
│ SessionStart              │
│ session-startup.sh        │
│  → brief con drift/edits  │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ Plan tarea grande         │
│ /plan o describir scope   │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ Trabajo: edits/bash/read  │◄────┐
│ Hooks corren transparente │     │
└─────────────┬─────────────┘     │
              │                   │
              ▼                   │
┌───────────────────────────┐     │
│ pre-compact-warning.sh    │     │
│ (UserPromptSubmit)        │     │
└─────────────┬─────────────┘     │
              │                   │
        ¿>80% context?            │
       /          \                │
      no           sí              │
      │            ▼               │
      │   ┌──────────────────┐    │
      │   │ Tomar decisión:   │    │
      │   │ A) compact-task   │    │
      │   │ B) /clear         │    │
      │   │ C) subagent       │    │
      │   └────────┬─────────┘    │
      │            │              │
      │      ┌─────┴─────┐        │
      │      │  /forge    │        │
      │      │  compact-  │        │
      │      │  task      │        │
      │      └─────┬─────┘        │
      │            │              │
      │   ┌────────▼─────────┐    │
      │   │ post-compact.sh  │    │
      │   │ + compact-filter │    │
      │   │ → last-compact   │    │
      │   └────────┬─────────┘    │
      │            │              │
      └────────────┴──────────────┘
              │
              ▼
┌───────────────────────────┐
│ Stop / Session end        │
│ session-report.sh         │
└───────────────────────────┘
```

## Decisión: `/compact` vs `/clear` vs subagent

| Situación | Comando | Por qué |
|---|---|---|
| Cambio de tarea grande, mismo proyecto, querés mantener contexto resumido | `/forge compact-task` | Preserva decisions y archivos modificados con summary filtrado |
| Tarea totalmente nueva, sin relación con lo anterior | `/clear` | Reset total. Más rápido y limpio que compact |
| Tarea de 10-15min con cambio de contexto neto (architecture → impl) | Spawn subagent | Context fresco, parent contexto intacto |
| Cambio de proyecto | Nueva sesión Claude Code | Sin overhead de compact |
| Sesión >8h continua | `/forge compact-task` aunque no llegues a 80% | Profilaxis contra summary-of-summary degradación |

## El patrón recomendado (Boris Cherny + dotforge)

1. **SessionStart**: leés el brief automático (`session-startup.sh`)
2. **Plan**: `/plan` o describir scope. Plan acceptance limpia contexto automáticamente
3. **Subagentes para tareas grandes**: cada uno tiene context fresco
4. **Compactación al 80%** entre tareas, no mid-task
5. **`/clear` cuando cambias completamente** de dominio

## Anti-patterns confirmados

| Anti-pattern | Por qué |
|---|---|
| Esperar al auto-compact (96.7%) | Avthar (X): "can hurt performance mid-task". Anthropic optimizó el summary, pero llegás con calidad ya degradada |
| Compactar al 50% | Pérdida de thread reciente. Recompactaciones acumulan degradación (summary del summary del summary) |
| `/compact` sin instrucciones | Defaults pueden descartar lo que vos sabés que importa |
| Sesión >8h sin compactar | Context rot es lineal-acelerado (Chroma). Calidad cae aunque no llegues al límite |
| Compactar y NO usar subagent para la siguiente tarea grande | Volvés a llenar contexto en horas |

## Cache economy — la dimensión que ignora la academia

Compactar **invalida el prefix cache**. Cada compactación = nuevo cache write (1.25× costo si TTL 5min, 2× si 1h).

**Métrica de salud > size del context**: cache hit rate.

```
Cache hit rate > 80%  →  sano
Cache hit rate 60-80% →  OK, no abusar de /compact
Cache hit rate < 60%  →  problema: compactando demasiado seguido
```

Si `<60%`: subí threshold a 85% o usá subagentes en vez de compactar.

**Bug histórico** (Paweł Huryn, X, marzo 2026): cache rota → users vieron 20× cost inflation porque cada turno reprocesaba toda la conversación. Métrica de cache es defensa contra este tipo de bugs.

## Re-anchoring (mitigación de "lost in the middle")

Liu et al. demostraron: contenido en el medio del contexto se atiende peor. Mitigación práctica:

- Cada **20-25K tokens nuevos**, re-inyectar instrucciones críticas
- Implementación: hook `UserPromptSubmit` que detecta milestones (cada N turnos) e inyecta `additionalContext` con recordatorios
- Para subagentes: `SubagentStart` hook con `additionalContext` desde el principio

dotforge no implementa re-anchoring automático todavía — pendiente para v3.8+.

## Configuración por proyecto

| Tipo de proyecto | Auto-compact | Threshold warning | Subagentes |
|---|---|---|---|
| Light (<10 files, sesiones <2h) | ON | 80% | Opcional |
| Standard (50-200 files, sesiones 2-6h) | ON | 80% | Para tareas >10min |
| Heavy (>200 files, sesiones 6h+) | **OFF** | 75% | Mandatorio para tareas grandes |

Override por proyecto vía env vars en `settings.json`:

```json
{
  "env": {
    "CLAUDE_CONTEXT_LIMIT": "1000000",
    "CLAUDE_COMPACT_WARN_PCT": "75",
    "CLAUDE_COMPACT_URGENT_PCT": "85"
  }
}
```

## Fuentes (canónicas)

### Académicas
- [Liu et al. 2023 — Lost in the Middle](https://arxiv.org/abs/2307.03172) — Stanford, ACL 2024. 30%+ accuracy loss en medio del contexto
- [Chroma Research — Context Rot](https://www.trychroma.com/research/context-rot) — Benchmark sobre 18 modelos frontier
- [Greg Kamradt — Needle in Haystack](https://github.com/gkamradt/LLMTest_NeedleInAHaystack) — GPT-4 degrada >73K tokens

### Práctica de campo
- [Boris Cherny on X](https://x.com/bcherny/status/2012663636465254662) — Plan acceptance auto-clears context
- [Daniel San on X](https://x.com/dani_avila7/status/2008653214472614369) — Hook al 80%, auto-compact OFF en producción
- [Avthar on X](https://x.com/avthars/status/1988678651160982012) — `/compact` proactivo > auto-compact mid-task
- [Paweł Huryn on X](https://x.com/PawelHuryn/status/2044684066427998576) — Cache economics

### Anthropic oficial
- [Effective Context Engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Sept 2025. 54% mejor performance con contexto curado
- [Prompt Caching Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) — TTL 5min vs 1h, costos
