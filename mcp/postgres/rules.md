---
globs: "**/*.sql,**/migrations/**,**/models/**,**/db/**"
---

# PostgreSQL MCP Rules

## Server posture
The official postgres MCP server is read-only — it only executes SELECT queries.
Use it for schema exploration and data inspection, not for mutations.

## Safe operations (call freely)
- `list_tables`: enumerate schema
- `describe_table`: inspect columns, types, constraints
- `query`: SELECT statements only — the server enforces this

## Query hygiene
- Always add LIMIT when querying unknown table sizes (default: LIMIT 100)
- Use explicit column lists in SELECT — avoid `SELECT *` on wide tables
- When exploring foreign keys or relationships, use `describe_table` first

## Mutations belong elsewhere
For INSERT, UPDATE, DELETE, or DDL:
- Use the Supabase MCP template if on Supabase (see mcp/supabase/)
- Use local psql / migration tooling for schema changes
- Never ask the user to "just run this in psql" without showing the full statement first

## Environment awareness
- Development DB: standard inspection workflow
- Staging/production DB: always state which environment you are connecting to before any query
- If DATABASE_URL points to production: treat even read operations as sensitive (may contain PII)
