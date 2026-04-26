---
id: practice-2026-04-26-hook-type-mcp-tool
title: Hooks support type "mcp_tool" to invoke MCP tools directly (v2.1.118)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [hooks, mcp, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
Hook configuration now accepts `type: "mcp_tool"` in addition to the existing `command`, `http`, `prompt`, and `agent` types. The hook directly invokes a tool on a configured MCP server. Schema:

```json
{
  "type": "mcp_tool",
  "server": "my_server",
  "tool": "security_scan",
  "input": { "file_path": "${tool_input.file_path}" }
}
```

`${tool_input.*}` substitution is supported. Available since v2.1.118.

## Evidence
CHANGELOG v2.1.118: "Hooks can now invoke MCP tools directly via `type: \"mcp_tool\"`".
code.claude.com/docs/en/hooks documents the field schema and substitution syntax.

This unlocks patterns dotforge previously had to build via shell wrappers — e.g., a Supabase-stack PostToolUse hook that calls an MCP `execute_sql` lint instead of shelling out.

## Impact on dotforge
- `.claude/rules/domain/hook-architecture.md` — list `mcp_tool` as a fifth hook type with the schema
- `stacks/supabase/`, `stacks/redis/` — candidates for MCP-tool-typed hooks once the pattern is proven
- `audit/checklist.md` — eventually consider a "uses mcp_tool hook for X" recommended item

## Decision
Pending
