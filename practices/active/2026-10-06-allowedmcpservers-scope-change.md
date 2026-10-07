---
id: practice-2026-10-06-allowedmcpservers-scope-change
title: allowedMcpServers now governs only user-added servers; managed-mcp.json servers load regardless (v2.1.259, v2.1.271)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [mcp, managed-settings, permissions, breaking-change, security]
tested_in: []
incorporated_in: [".claude/rules/domain/permission-managed-settings.md"]
replaced_by: null
effectiveness: monitoring
error_type: security
---

## Description
- v2.1.259: `allowedMcpServers` governs only servers users add. A literal `managed-mcp.json` server your allowlist used to filter out **now loads on upgrade** — use `deniedMcpServers` to keep it off.
- v2.1.271: unreadable `managed-mcp.json` keeps exclusive MCP control and warns (fail-closed).
- v2.1.273: fix for `allowManagedMcpServersOnly`, `deniedMcpServers`, `disableClaudeAiConnectors` being ignored when server-managed settings are also present.
- v2.1.285: `alwaysLoad: false` defers all of a server's tools behind tool search; `_meta['anthropic/alwaysLoad']=false` per tool. `"type":"sdk"` entries skipped (v2.1.274). Server name `widgets` reserved in cloud/self-hosted (v2.1.287).
- v2.1.248: project `.mcp.json` `headersHelper` and inline MCP servers in project/`--add-dir` agent files require trust dialog (also under `-p`); helpers run without inherited credential env vars.

## Evidence
`permission-managed-settings.md:30-33` describes `allowedMcpServers` / `deniedMcpServers` as symmetric "managed-scope versions". `:35` only documents `alwaysLoad: true`. `plugin-distribution.md:38` only reserves `workspace`.

## Impact on dotforge
- `.claude/rules/domain/permission-managed-settings.md` § MCP server config: rewrite allow/deny semantics, add fail-closed + trust notes
- `.claude/rules/domain/plugin-distribution.md`: reserved names
- `mcp/*/` templates: verify none rely on allowlist-only filtering

## Decision
Accepted 2026-10-06 — incorporated in dotforge v4.4.0 (/forge update, breaking batch).
