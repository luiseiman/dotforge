---
name: watch-upstream
description: Busca actualizaciones en docs oficiales de Anthropic/Claude Code y reporta deltas contra la configuración actual de claude-kit.
---

# Watch Upstream

Search for updates in official Anthropic/Claude Code documentation and report deltas against current claude-kit configuration.

## Paso 1: Search for recent changes

Use web search to find recent updates in these areas:
1. Claude Code changelog and release notes (https://docs.anthropic.com/en/docs/claude-code)
2. Claude Code hooks, settings, permissions changes
3. New Claude Code features (agents, skills, commands, MCP)
4. Claude API changes that affect Claude Code behavior

Search queries:
- `Claude Code changelog site:docs.anthropic.com`
- `Claude Code new features site:anthropic.com`
- `Claude Code hooks settings site:github.com/anthropics`

## Paso 2: Extract relevant changes

For each finding, classify:

| Category | Relevance to claude-kit |
|----------|------------------------|
| New hook types | May need new hooks in template/ |
| New settings fields | May need updates to settings.json.tmpl |
| Permission changes | May affect allow/deny lists |
| New agent capabilities | May affect agents/ definitions |
| Deprecated features | May need removal from template/ |
| New CLI commands | May need new skills/ |

Ignore: pricing changes, model updates (unless affecting tool use), marketing content.

## Paso 3: Compare against current template

For each relevant finding:
1. Check if claude-kit already covers it (search template/, stacks/, global/)
2. If not covered, note the gap with specific files that would need changes
3. If partially covered, note what's missing

## Paso 4: Report

```
═══ WATCH UPSTREAM ═══
Fecha: {{YYYY-MM-DD}}
Fuentes consultadas: {{N}}

── CAMBIOS DETECTADOS ──
{{🆕|⚠️|📝}} {{título}} ({{fecha del cambio}})
   Relevancia: {{categoría}}
   Estado claude-kit: {{cubierto|parcial|no cubierto}}
   Acción: {{qué habría que cambiar}}

── RESUMEN ──
Cubiertos: {{N}} | Parciales: {{N}} | No cubiertos: {{N}}

── SIGUIENTE PASO ──
Para incorporar cambios: /forge capture "{{descripción}}" para cada hallazgo relevante.
```

## Constraints

- DO NOT auto-incorporate changes. Only report.
- DO NOT modify any claude-kit files. This is read-only + web search.
- If web search fails or returns no results, report that clearly instead of guessing.
