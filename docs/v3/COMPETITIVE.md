# Mapa competitivo y diferenciales de dotforge v3.0

## Competencia directa verificada

### obey (Lexxes-Projects)

- Natural language → rule storage → hook auto-generado
- 17 hooks de lifecycle
- 3 scopes: global, stack-specific, project-local
- Blocking activo via PreToolUse
- Audit trail
- Completion checklists via Stop hook

**Solape con 3.0 original:** casi total.
**Nuestro diferencial ante obey:** catálogo curado, integración con el
resto del lifecycle de dotforge (audit, practices, registry, export),
enforcement escalonado de 5 niveles vs hard-block binario, seguridad
first-class.

### hookify (oficial Anthropic)

- Plugin oficial
- Markdown rules → hooks activos
- Archivo por regla, sin restart

**Solape:** parcial, patrón similar.
**Riesgo:** si Anthropic publica behavior spec oficial en 6 meses, dotforge
debe alinearse. Schema debe ser lo más cercano posible a estándares
obvios.

### tdd-guard (nizos, 1.7k stars)

- TDD enforcement vertical
- Context aggregation cross-hook via archivos compartidos
- Quick commands ON/OFF via UserPromptSubmit
- Multi-language

**Solape:** ninguno (vertical específico).
**Lecciones aplicables:**
- Context aggregation cross-hook: diferir a 3.1 pero diseñar schema
  compatible desde 3.0
- Quick commands ON/OFF: incluir en 3.0 (`/forge behavior off`, scope)

### Otros proyectos referenciables

- **claude-code-workflow-orchestration:** soft enforcement con nudges
  escalonados (silent → hint → warning → strong). Fuente del modelo de
  5 niveles.
- **claude-code-lsp-enforcement-kit:** state tracking persistente por
  cwd, multi-tier por tipo de agent. Fuente del campo `applies_to.agents`.
- **AgentSpec (ICSE '26):** DSL académica para runtime enforcement.
  Referencia formal citable en README.
- **AgentBound:** arquitectura manifest + enforcement engine. Modelo
  interno, no user-facing.

## Diferenciales defendibles de dotforge 3.0

1. **Catálogo curado con governance** — obey/hookify te piden escribir
   reglas. dotforge trae behaviors probados, auditables, versionados.

2. **Integración con lifecycle existente** — los behaviors entran al
   pipeline `inbox → evaluating → active → deprecated`, al `/forge audit`,
   al registry cross-proyecto. Nadie más tiene esto.

3. **Enforcement escalonado 5 niveles con UX de escape** — obey es
   hard-block binario. dotforge permite configurar silent/nudge/warning/
   soft/hard por behavior, con override auditado en soft y comandos de
   escape por scope.

4. **Separación policy vs rendering** — un behavior declara comportamiento
   esperado separado del texto que se inyecta en CLAUDE.md. Habilita
   multi-platform export nativo (diferido a 3.1 pero diseñado desde 3.0).

5. **Seguridad first-class (diferida a 3.2 pero planeada)** — post-CVE
   Feb 2026, signed behaviors + hash verification + sandbox es
   requisito enterprise. Competidores no lo tienen.

## Riesgos competitivos

- **obey consolida narrativa mientras construís:** mitigación es Fase 1
  rápida con search-first funcional + GIF público.
- **Anthropic publica behavior spec oficial:** mitigación es schema
  conservador alineado con patterns obvios + campo `schema_version`.
- **dotforge sigue en 4 stars:** problema es distribución, no producto.
  Post técnico + benchmark real + update marketplace Anthropic en Fase 3.

## Mapa de features diferido a 3.1/3.2

| Feature | Competidor que ya lo hace | Target dotforge |
|---------|---------------------------|-----------------|
| Prompt-based hooks | Anthropic oficial | 3.1 |
| Multi-platform export de rules | Ninguno directo | 3.1 |
| Context aggregation | tdd-guard | 3.1 |
| Natural language input | obey, rule2hook | 3.1 |
| Signed behaviors | Ninguno | 3.2 |
| Transcript verification | Ninguno | 3.2 |
| OPA/Rego compile | yaml-opa-llm-guardrails | 3.2 opcional |
