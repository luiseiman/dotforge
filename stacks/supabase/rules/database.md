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

## Common errors
- Forgetting RLS → data exposed publicly
- Foreign key without ON DELETE → orphaned records
- Trigger referencing a non-existent function → silently broken migration
