---
name: scout-repos
description: Revisa repos curados en practices/sources.yml, compara sus configuraciones .claude/ contra la plantilla claude-kit, y reporta patterns interesantes.
---

# Scout Repos

Review curated repos for Claude Code configuration patterns worth adopting.

## Paso 1: Load sources

Read `~/Documents/GitHub/claude-kit/practices/sources.yml`.
For each source, note the `focus` areas to prioritize during review.

## Paso 2: Fetch and analyze each repo

For each source repo:
1. Use web search or `gh` CLI to explore the repo's Claude Code configuration:
   - `.claude/settings.json` — permissions, hooks, deny patterns
   - `.claude/rules/` — contextual rules, globs patterns
   - `.claude/commands/` — custom commands
   - `.claude/agents/` — agent definitions
   - `CLAUDE.md` — project configuration
2. Focus on the `focus` areas defined in sources.yml
3. Extract patterns that differ from or improve upon claude-kit's current template

## Paso 3: Compare against claude-kit

For each discovered pattern:
1. Check if claude-kit already has it (search template/, stacks/, global/)
2. Classify:
   - **Novel**: not in claude-kit at all → high interest
   - **Variant**: similar but different approach → medium interest
   - **Already covered**: claude-kit has it → skip
   - **Incompatible**: conflicts with claude-kit philosophy → skip with note

## Paso 4: Report

```
═══ SCOUT REPOS ═══
Fecha: {{YYYY-MM-DD}}
Repos analizados: {{N}}/{{total}}

── PATTERNS ENCONTRADOS ──
{{repo}} ({{focus areas}})
  🆕 {{pattern}} — {{descripción}}
     Impacto: {{qué archivos de claude-kit cambiarían}}

── RESUMEN ──
Novel: {{N}} | Variantes: {{N}} | Ya cubiertos: {{N}}

── SIGUIENTE PASO ──
Para incorporar: /forge capture "{{descripción}}" para cada pattern novel.
```

## Constraints

- DO NOT auto-incorporate patterns. Only report.
- DO NOT modify any claude-kit files. This is read-only.
- If a repo is private or inaccessible, skip it and note in the report.
- Respect rate limits — if using GitHub API, don't fetch more than necessary.
