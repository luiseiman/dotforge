# MCP Server Templates

Templates for configuring MCP servers in Claude Code projects. Each template provides:

- **`config.json`** — mergeable `mcpServers` entry for `~/.claude/settings.json`
- **`permissions.json`** — `allow`/`deny` tool list to merge into `.claude/settings.json`
- **`rules.md`** — Claude-consumed usage rules, installed to `.claude/rules/mcp-<name>.md`

## Architecture

MCP configuration splits across two layers:

| Layer | File | Purpose |
|-------|------|---------|
| Global (`~/.claude/`) | `mcpServers` entry | Connection config, credentials |
| Project (`.claude/`) | `rules/mcp-<name>.md` | Usage rules per project context |

The same GitHub MCP server can have different rules in a read-only analytics project vs an active development project.

## Installation

### Via /forge bootstrap (automatic)

During bootstrap, `/forge bootstrap` detects configured `mcpServers` in `~/.claude/settings.json` and suggests installing matching rule templates. Accept to copy `rules.md` to `.claude/rules/mcp-<name>.md` and merge `permissions.json` into `.claude/settings.json`.

### Manual installation

**Step 1 — Register the MCP server (global, one-time per machine):**
```bash
# Copy the mcpServers entry from config.json into ~/.claude/settings.json
# under the "mcpServers" key. Replace ${ENV_VAR} placeholders with real values
# or set the env vars in your shell profile.
```

**Step 2 — Install project rules:**
```bash
cp mcp/<server>/rules.md .claude/rules/mcp-<server>.md
```

**Step 3 — Merge permissions:**
```bash
# Add the allow/deny entries from permissions.json into .claude/settings.json
# under permissions.allow and permissions.deny
```

## Available templates

| Server | Package | Use case |
|--------|---------|---------|
| `github` | `@modelcontextprotocol/server-github` | Issues, PRs, code search |
| `postgres` | `@modelcontextprotocol/server-postgres` | Direct DB access (read-heavy) |
| `supabase` | `@supabase/mcp-server-supabase` | Supabase projects, migrations, branches |
| `redis` | `mcp-server-redis` (community) | Key inspection, stream monitoring |
| `slack` | `@modelcontextprotocol/server-slack` | Messages, channels, search |

## Composing multiple servers

Each template is independent. Install any combination. Rule files don't conflict — each loads via its own globs frontmatter.

When using multiple MCP servers in the same session, apply the most restrictive permission that makes sense for the task. If migrating a database via Supabase MCP while reading a GitHub issue for context, the Supabase rules (confirm before execute_sql) take precedence for data operations.

## Versioning

Each `config.json` includes a `_verified_with` field indicating the package version against which tool names were validated. When `/forge watch` detects a new major version of an MCP server package, re-verify tool names — they can change between versions.
