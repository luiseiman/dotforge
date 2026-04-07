---
id: practice-2026-04-06-mcp-tool-result-persistence
title: "MCP tool result size override via _meta"
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-04-06
status: inbox
tags: [mcp, performance, settings]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Descripción
Since v2.1.91, MCP tools can override the max result size limit per-call by including `_meta["anthropic/maxResultSizeChars"]` in the tool result, up to 500K characters. Previously the cap was fixed and smaller results were truncated silently.

## Evidencia
Official changelog v2.1.91 (April 2, 2026): "Added MCP tool result persistence override via `_meta["anthropic/maxResultSizeChars"]` (up to 500K)".

## Impacto en claude-kit
- `docs/best-practices.md` — add note under MCP section
- Any MCP server templates in `integrations/` or `mcp/` that deal with large payloads (DB query results, file reads) should document this override

## Decisión
Pendiente
