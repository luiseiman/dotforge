# MCP Detection Rules for /forge bootstrap

Signals used to detect which MCP templates to suggest during bootstrap.

## Detection sources

1. **`~/.claude/settings.json`** — check `mcpServers` keys
2. **`.claude/settings.json`** — check `mcpServers` keys (project-level)
3. **Dependency files** — secondary signals for suggesting MCP setup

## Server → template mapping

| mcpServers key contains | Template | Also suggest if |
|-------------------------|----------|----------------|
| `github` | `mcp/github/` | `gh` CLI used in session |
| `postgres` | `mcp/postgres/` | `DATABASE_URL` in env |
| `supabase` | `mcp/supabase/` | `supabase/` dir present OR `@supabase/*` in deps |
| `redis` | `mcp/redis/` | `redis` or `ioredis` in deps |
| `slack` | `mcp/slack/` | `SLACK_BOT_TOKEN` in env |

## Bootstrap prompt format

For each detected server without installed rules:

```
Found MCP server: <name> (<package>)
No usage rules installed for this project.
Install rules from claude-kit template? [Y/n]
  → Copies mcp/<name>/rules.md to .claude/rules/mcp-<name>.md
  → Merges mcp/<name>/permissions.json into .claude/settings.json
```

## Already installed check

Before suggesting, verify `.claude/rules/mcp-<name>.md` does not already exist.
If it exists, skip silently — don't overwrite customized rules.
