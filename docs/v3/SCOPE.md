# Alcance de dotforge v3.0

## En scope para v3.0

Cinco piezas inseparables:

1. **Schema formal de behaviors**
   - Declarativo, acotado, versionado
   - Separación policy / rendering
   - DSL mínima cerrada

2. **Runtime state mínimo**
   - `.forge/runtime/state.json`
   - Contadores por sesión y por behavior
   - mkdir-based locking para concurrencia (ver RUNTIME.md §7)
   - TTL 24h sobre último acceso

3. **Enforcement escalonado de 5 niveles**
   - silent, nudge, warning, soft_block, hard_block
   - JSON output para blocks (no exit codes custom)
   - Override solo en soft_block

4. **Catálogo curado**
   - Core: search-first, verify-before-done, no-destructive-git, respect-todo-state
   - Opinionated: plan-before-code, objection-format
   - Experimental: vacío en 3.0 (categoría reservada)

5. **UX de control y escape**
   - `/forge behavior on|off|status|strict|relaxed`
   - Scopes: `--session | --project | --agent`
   - Status muestra contadores reales, violaciones por behavior, overrides

## Fuera de scope para v3.0 (diferido explícitamente)

### Diferido a 3.1 (6-8 semanas post-release)

- Prompt-based hooks (`type: prompt` en behaviors)
- Context aggregation cross-hook rica
- Export de behaviors a `.cursorrules`, `AGENTS.md`, `.windsurfrules`
- Scope contador `task` funcional
- Recomendador automático (`/forge behavior recommend`)

### Diferido a 3.2 (3-4 meses post-release)

- Signed behaviors + hash verification (post-CVE Feb 2026)
- Verification contra transcripts de sesión
- llm_self_examine como estrategia de recovery
- OPA/Rego compile path (enterprise opcional)

### Diferido sin fecha

- Policy engine unificado
- Behavior marketplace público
- Telemetría cross-proyecto anónima

## Entregables de Fase 0 (cierre de spec)

Exactamente 5 documentos:

1. `docs/v3/SPEC.md` — semántica formal de niveles (tabla canónica)
2. `docs/v3/SCHEMA.md` — shape completo de `behavior.yaml v1`
3. `docs/v3/RUNTIME.md` — formato de `state.json`, TTL, concurrencia
4. `docs/v3/AUDIT.md` — formato `overrides.log` y métricas expuestas
5. `docs/v3/COMPILER.md` — reglas mínimas de compilación behavior → hook

Criterio de aceptación de Fase 0: otro ingeniero podría implementar
Fase 1 sin preguntas.

## Entregables de Fase 1 (2-3 semanas post-spec)

- Runtime funcionando con mkdir-based lock y TTL
- Compilador `behaviors/<id>.yaml → .claude/hooks/<id>.sh`
- `search-first` funcional end-to-end (nudge → warning → soft_block)
- Override registry funcionando en los 3 lugares
- `/forge behavior on|off|status|strict|relaxed` con scopes básicos

## Entregables de Fase 2 (2-3 semanas)

- Catálogo core: 4 behaviors (search-first, verify-before-done,
  no-destructive-git, respect-todo-state)
- Catálogo opinionated: 2 behaviors (plan-before-code, objection-format)
- `/forge behavior list|describe`
- Integración con `/forge audit`: dimensión "behaviors coverage"
- Tests por behavior en `behaviors/<id>/tests/`

## Entregables de Fase 3 (1-2 semanas — release)

- README reescrito (diferencial en primeras 40 líneas)
- CHANGELOG v3.0
- Migration guide desde 2.9 (opt-in, no rompe 2.9)
- Benchmark real corrido en SOMA o InviSight
- GIF demo de search-first escalando
- Post técnico: "de configs a comportamiento"
- Tag v3.0.0
- Update de submission al marketplace Anthropic

## Métricas de éxito

No son stars ni downloads. Son:

- **Semana 1:** 3+ issues no-triviales abiertos por externos
- **Mes 1:** 1 behavior externo contribuido por no-Luis
- **Mes 2:** mención técnica no tuya sobre "behavior governance"
- **Mes 3:** 1 proyecto serio usando dotforge como dep activa

Si a mes 3 no ocurrió ninguna de las cuatro: problema es distribución,
no producto. Pivot a content marketing técnico.
