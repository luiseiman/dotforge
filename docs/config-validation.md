# Config Validation System

Sistema de 4 capas para medir y mejorar la efectividad de la configuración de Claude Code.

## Problema

dotforge valida **presencia** de configuración (audit score 0-10) pero no **efectividad**. No hay forma de saber si una regla mejora el output de Claude o solo consume tokens del contexto.

## Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                    Config Validation                     │
├──────────────┬──────────────┬──────────────┬────────────┤
│   Fase 0     │   Fase 1     │   Fase 2     │  Fase 3-4  │
│  Structural  │  Behavioral  │   Coverage   │ Practices  │
│              │              │              │ + Benchmark│
├──────────────┼──────────────┼──────────────┼────────────┤
│ test-config  │ session      │ rule-        │ metrics.yml│
│ .sh          │ -report.sh   │ effectiveness│ benchmark  │
│              │ counters     │ SKILL.md     │ SKILL.md   │
│ Coherence    │ JSON metrics │ Inert rule   │ Binary     │
│ checks       │ per session  │ detection    │ recurrence │
└──────────────┴──────────────┴──────────────┴────────────┘
```

## Fase 0: Config Self-Validation

**Archivo:** `tests/test-config.sh`

Valida coherencia interna de la configuración generada:
- Hooks referenciados en settings.json existen y son ejecutables
- Rules tienen frontmatter `globs:` o `paths:` válido (con `alwaysApply: false` para lazy loading)
- Globs matchean al menos 1 archivo real
- settings.json es JSON válido
- deny list cubre mínimo: .env, *.key, *.pem
- No hay reglas contradictorias

**Uso:** `bash tests/test-config.sh` (se ejecuta en el directorio del proyecto)

## Fase 1: Métricas de sesión

**Archivos:** `template/hooks/session-report.sh`, `block-destructive.sh`, `lint-on-save.sh`

### Flujo de datos

```
block-destructive.sh ──→ /tmp/claude-destructive-blocks-{hash}
lint-on-save.sh ──────→ /tmp/claude-lint-blocks-{hash}
                              │
session-report.sh ◄───────────┘
       │
       ▼
~/.claude/metrics/{slug}/{date}.json
```

### Counter files

Los hooks `block-destructive.sh` y `lint-on-save.sh` escriben una línea por bloqueo a archivos en `/tmp/` usando un hash md5 del directorio del proyecto como identificador. `session-report.sh` (Stop hook) lee, cuenta, y elimina estos archivos.

### JSON metrics schema

```json
{
  "project": "my-api",
  "date": "2026-03-20",
  "sessions": 1,
  "errors_added": 0,
  "hook_blocks": 1,
  "lint_blocks": 3,
  "files_touched": 12,
  "rules_matched": 9,
  "rules_total": 12,
  "rule_coverage": 0.75,
  "commits": 4
}
```

Múltiples sesiones en el mismo día se acumulan incrementalmente.

### Rule coverage

`session-report.sh` cruza los archivos tocados (git diff) contra los globs/paths de frontmatter de cada regla en `.claude/rules/`. `rule_coverage = rules_matched / rules_total`.

### SESSION_REPORT.md (opt-in)

Setear `FORGE_SESSION_REPORT=true` para generar también un reporte markdown legible en la raíz del proyecto. Incluye las mismas métricas en formato humano.

## Fase 2: Detección de reglas inertes

**Archivo:** `skills/rule-effectiveness/SKILL.md`

**Comando:** `/forge rule-check`

Cruza globs de reglas contra historial de git para clasificar cada regla:

| Clasificación | Match rate | Acción |
|---------------|-----------|--------|
| **Activa** | > 50% | Mantener |
| **Ocasional** | 10-50% | Evaluar costo en tokens |
| **Inerte** | < 10% | Candidata a eliminar |

También calcula **file coverage**: % de archivos tocados que caen bajo al menos una regla, e identifica directorios sin cobertura.

## Fase 3: Tracking de efectividad de prácticas

**Archivos:** `practices/metrics.yml`, `skills/update-practices/SKILL.md`

Modelo binario de recurrencia: ¿el error que motivó la práctica volvió a pasar?

### Ciclo de vida

```
Práctica activada
  → metrics.yml: status: monitoring, recurrence_checks: 0
  → cada /forge audit: check CLAUDE_ERRORS.md por recurrencia
  → 5 checks sin recurrencia → status: validated
  → error recurre → status: failed (práctica necesita revisión)
```

### Campos en frontmatter de prácticas

```yaml
effectiveness: validated | monitoring | failed | not-applicable
error_type: null | syntax | logic | integration | config | security
```

Prácticas que no apuntan a un error específico (mejoras generales) se marcan `not-applicable`.

## Fase 4: Benchmark comparativo

**Archivos:** `skills/benchmark/SKILL.md`, `tests/benchmark-tasks/*.yml`

**Comando:** `/forge benchmark`

Ejecuta la misma tarea estándar en dos worktrees aislados:
1. **Full config** — configuración completa del proyecto
2. **Minimal config** — solo CLAUDE.md + settings.json básico

Compara: archivos creados, tests passing, lint issues, errores.

### Tareas disponibles

| Stack | Tarea | ID |
|-------|-------|----|
| python-fastapi | Add GET /health endpoint with test | python-fastapi-health |
| react-vite-ts | Add ErrorBoundary component with test | react-vite-ts-error-boundary |
| swift-swiftui | Add HealthCheck view with unit test | swift-swiftui-health-check |
| node-express | Add GET /health endpoint with test | node-express-health |
| go-api | Add GET /health endpoint with test | go-api-health |
| generic | Add CONTRIBUTING.md | generic-readme-update |

**Costo:** 2 ejecuciones de Claude por benchmark. Siempre opt-in.

## Comandos relacionados

| Comando | Qué hace |
|---------|----------|
| `/forge audit` | Score estructural (presencia) + coherence check |
| `/forge rule-check` | Efectividad de reglas (Fase 2) |
| `/forge insights` | Métricas de sesión + análisis retroactivo |
| `/forge benchmark` | Comparación full vs minimal config |

## Para usuarios nuevos (sin baseline)

1. `/forge bootstrap` instala config + hooks de métricas desde el día 1
2. Métricas se acumulan orgánicamente desde la primera sesión
3. `/forge rule-check` da valor inmediato (usa git log histórico)
4. `/forge insights` reconstruye pseudo-histórico desde CLAUDE_ERRORS.md + git log
5. Después de ~10 sesiones, las tendencias son confiables

## Para usuarios existentes que actualizan

1. `/forge sync` instala los nuevos hooks de métricas
2. `/forge rule-check` funciona inmediatamente con git log histórico
3. `/forge insights` usa análisis retroactivo hasta que las métricas se acumulen
4. Datos retroactivos marcados como "⚠ Inferred from git history"
