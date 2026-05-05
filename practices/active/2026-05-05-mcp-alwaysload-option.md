---
id: mcp-alwaysload-option
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-05-05
tags: [mcp, permissions, performance, medium-priority, v2.1.121]
tested_in: []
incorporated_in: ['3.6.0']
---

# `alwaysLoad: true` MCP server option (v2.1.121) — bypass tool-search deferral

## Observation

v2.1.121 added `alwaysLoad: true` to MCP server config. When set, all tools from that server skip the tool-search deferral mechanism and are always available in the prompt.

Tradeoff: faster access, more context spent. The default deferral was added precisely because MCP servers can ship dozens of tools that bloat the prompt.

## Why it matters for dotforge

Projects that use specific MCP servers heavily (Atlassian for jira-nbch, Supabase for InviSight-iOS) can opt-in to skip the search overhead when those tools are needed every session.

`domain/permission-model.md` covers `enableAllProjectMcpServers`, `allowedMcpServers`, etc. but does NOT document `alwaysLoad`. Worth a sentence.

## Required update

`domain/permission-model.md` MCP section — add:
```
- `alwaysLoad: true` (per-server, v2.1.121+): all tools from that server skip
  tool-search deferral and stay available in the prompt. Use only when MCP
  tools are needed in every turn — costs context for fewer tool-search
  invocations.
```

## Affected files

- `.claude/rules/domain/permission-model.md`
