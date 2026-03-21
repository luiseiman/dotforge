---
globs: "**/*.sql,**/migrations/**,**/models/**,**/db/**"
---

# PostgreSQL MCP Rules

## Server posture

The official `@modelcontextprotocol/server-postgres` exposes a `query` tool that executes
**arbitrary SQL** — SELECT, INSERT, UPDATE, DELETE, and DDL. It does NOT enforce read-only.
The permissions system cannot block specific SQL patterns — it only blocks tool calls by name.
SQL safety is entirely governed by these rules. Follow them without exception.

## Safe operations — call freely

- `list_tables`: enumerate schema
- `describe_table`: inspect columns, types, constraints, indexes
- `query` with SELECT: data inspection — no confirmation needed
- Always add `LIMIT` when querying unknown table sizes (default: `LIMIT 100`)
- Use explicit column lists — avoid `SELECT *` on wide tables
- When exploring foreign keys, use `describe_table` first

## DML — confirm before executing

Before any INSERT, UPDATE, or DELETE:
1. Show the complete SQL statement
2. State the expected row count (run a SELECT COUNT WHERE first if unknown)
3. State whether the operation is reversible (no transaction → not reversible)
4. Wait for explicit user confirmation

**Never run UPDATE or DELETE without a WHERE clause.** If no WHERE clause is intended,
say so explicitly and require double confirmation: "This will affect ALL rows in the table."

## DDL — hard stops

Never execute any of the following without the user typing the command explicitly
(not just saying "yes, go ahead"):

- `DROP TABLE` / `DROP TABLE IF EXISTS`
- `DROP DATABASE` / `DROP SCHEMA`
- `TRUNCATE` / `TRUNCATE TABLE`
- `ALTER TABLE ... DROP COLUMN`
- `ALTER TABLE ... DROP CONSTRAINT`

For these operations: stop, show the full statement, explain the irreversibility, and
instruct the user to run it manually via psql or their migration tool.

## Migrations

- Use SQL mutations through migration files, not through MCP `query` directly
- Exception: exploratory SELECT queries and development seed data are fine via MCP
- For schema changes in any non-local environment: stop and refer to migration tooling

## Environment awareness

Before any DML or DDL, identify the environment from DATABASE_URL:

- **Local / development** (`localhost`, `127.0.0.1`, `*.local`): standard confirmation flow
- **Staging** (`staging`, `stage`, `stg` in host or DB name): standard confirmation flow
- **Production** (`prod`, `production`, `live`, or any RDS/Cloud SQL endpoint without clear staging marker):
  - Treat even SELECT as sensitive (may contain PII)
  - DML: stop and refuse — tell the user to run manually
  - DDL: always refuse
  - State the environment explicitly before every query: "Connecting to **PRODUCTION**"

If DATABASE_URL is ambiguous (no clear env marker), ask before any write operation.

## Connection pooling

If DATABASE_URL uses PgBouncer or similar pooler:
- Avoid SET statements and advisory locks — they break under transaction pooling mode
- Avoid multi-statement transactions in a single `query` call under session pooling
- Prefer explicit single-statement queries
