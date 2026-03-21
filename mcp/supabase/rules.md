---
globs: "supabase/**,**/*.sql,**/migrations/**"
---

# Supabase MCP Rules

## Read/write boundary
Read freely: list_projects, get_project, list_tables, list_migrations, get_logs.
Any operation that modifies schema or data requires showing the full operation and waiting for explicit confirmation.

## SQL execution
- Always show the complete SQL statement before calling `execute_sql`
- Never run INSERT/UPDATE/DELETE without stating the expected row count
- Never run DDL (CREATE TABLE, ALTER, DROP) without stating the migration name and impact
- Wrap multi-statement operations in a transaction when possible
- SELECT queries: safe, no confirmation needed

## Migrations
- Read `list_migrations` before creating a new one — check for conflicts
- State what the migration does and which tables are affected before calling `apply_migration`
- In production contexts: STOP. Tell the user to run the migration manually via the Supabase dashboard or CLI. Do not apply_migration to production.

## Branching
- Use `create_branch` only for non-trivial schema experiments (more than one migration)
- Before `merge_branch`, call `list_migrations` on the branch and show the diff to the user
- Never auto-merge — always present the change and wait for approval

## Environment classification
- Project name contains "prod", "production", "live": treat ALL write operations as high-risk
- Project name contains "staging", "stage": standard confirmation flow
- Project name contains "dev", "local", "test": standard confirmation flow
- When environment is unclear: ask before any write

## RLS and security
- When creating or modifying tables, always ask: "Should this table have Row Level Security enabled?"
- Never disable RLS on an existing table without explicit user instruction
- Review Edge Function code for secrets before deploying — never log tokens or keys
