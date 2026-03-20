---
title: "Claude Code tiene sistema formal de plugins"
date: 2026-03-19
source_type: upstream
status: deprecated
reason: "Not applicable — claude-kit is single-user. Revisit if distributing to teams."
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

## Relevancia para claude-kit

claude-kit hace manualmente (bootstrap, sync, symlinks) lo que los plugins formalizan
en un paquete instalable vía `/plugin`. Si se quisiera distribuir claude-kit a un equipo,
el formato plugin sería el camino.

## Decisión

**No migrar ahora.** claude-kit es para un solo usuario. Los plugins resuelven
distribución a equipos, que no es el caso actual. Migrar cuando:
- Se comparta claude-kit con otros devs
- El plugin system madure (aún en evolución)
- Se necesite instalación vía marketplace

## Referencias

- https://github.com/anthropics/claude-code/blob/main/plugins/README.md
- https://code.claude.com/docs/en/sub-agents
