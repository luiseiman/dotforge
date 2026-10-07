---
globs: "supabase/**,**/migrations/**"
---

# Supabase Rules

## Migrations
- One migration per logical change. Descriptive name: `YYYYMMDDHHMMSS_add_<entity>_table.sql`
- ALWAYS create a reversible migration (include DOWN even if unused)
- RLS (Row Level Security) REQUIRED on every table with user data
- After creating a table: verify RLS is enabled

## RLS Policies
- Default policy: DENY ALL. Create explicit policies.
- Descriptive policy names: `users_select_own`, `admin_all_access`
- Verify with `supabase db lint` after changes

## Edge Functions
- Deno runtime. Import maps in `supabase/functions/import_map.json`
- Explicit CORS headers in every function
- Verify JWT by default (--no-verify-jwt only with justification)

## Types
- Generate TS types: `supabase gen types typescript --project-id <id>`
- Regenerate after every migration

## Backend auth (server-side)
- Server-side services writing to RLS-enabled tables MUST use the `service_role` key (bypasses RLS). NEVER the `anon` key — that is for public clients
- Verify the JWT role in doubt: base64-decode the middle segment and check `payload.role`
- Symptom of wrong key: silent read failures (SELECT returns 0 rows because RLS filters them) + write failures with `42501`. Scope is total, not localized
- NEVER "fix" a backend write failure by granting `anon` INSERT/SELECT policies on sensitive tables — that exposes them to anyone holding the public anon key

## Error-code ordering (Postgres)
- CHECK constraints are evaluated BEFORE the RLS `WITH CHECK` policy on INSERT. A `23514` (check_violation) does NOT imply the row passed RLS — it failed the constraint first, before RLS was ever reached
- Don't infer write permission from which error fired first. Fix the constraint, then the same insert may still hit `42501`

## Common errors
- Forgetting RLS → data exposed publicly
- Foreign key without ON DELETE → orphaned records
- Trigger referencing a non-existent function → silently broken migration
