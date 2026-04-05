---
id: practice-2026-03-19-claude-code-plugin-system
title: "Claude Code tiene sistema formal de plugins"
date: 2026-03-19
source: upstream
source_type: upstream
status: deprecated
reason: "Not applicable — dotforge is single-user. Revisit if distributing to teams."
effectiveness: not-applicable
error_type: null
tags: [plugins, architecture, distribution]
---

## Contexto

Claude Code ahora tiene un sistema formal de plugins con estructura estándar:

```
plugin-name/
├── .claude-plugin/plugin.json
├── commands/
├── agents/
├── skills/
├── hooks/
└── .mcp.json
```

## Relevancia para dotforge

dotforge hace manualmente (bootstrap, sync, symlinks) lo que los plugins formalizan
en un paquete instalable vía `/plugin`. Si se quisiera distribuir dotforge a un equipo,
el formato plugin sería el camino.

## Decisión

**No migrar ahora.** dotforge es para un solo usuario. Los plugins resuelven
distribución a equipos, que no es el caso actual. Migrar cuando:
- Se comparta dotforge con otros devs
- El plugin system madure (aún en evolución)
- Se necesite instalación vía marketplace

## Referencias

- https://github.com/anthropics/claude-code/blob/main/plugins/README.md
- https://code.claude.com/docs/en/sub-agents
