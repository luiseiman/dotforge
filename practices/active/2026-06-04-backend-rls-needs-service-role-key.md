---
id: practice-2026-06-04-backend-rls-needs-service-role-key
title: A backend behind RLS deny-all must use the service_role key, not anon
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [security, supabase, postgres, rls, stack-backend]
tested_in: TradingBot
incorporated_in: ["stacks/supabase/rules/database.md"]
replaced_by: null
---

## Description
A server-side service writing to Supabase/Postgres tables that have RLS enabled with zero policies (deny-all for `anon`/`authenticated`) MUST authenticate with the `service_role` key, which bypasses RLS. Never the `anon` key (that one is for public clients). The symptom may surface in a single place (e.g. one backfill INSERT failing `42501`) while the real scope is total: the backend is blind — every SELECT returns 0 rows (RLS filters them) and every write fails. Diagnose by decoding the JWT role: `payload.role` (base64-decode the middle segment). Fix is the key, not RLS — never add `anon` INSERT/SELECT policies to sensitive tables, that exposes them to anyone holding the public anon key.

## Evidence
TradingBot's VPS `.env` had `SUPABASE_KEY=<anon>`. The visible error was the IOL candle backfill failing with `new row violates row-level security policy (42501)`. Investigation showed all `bot_*` tables had RLS on + 0 policies, the bot read 0 rows and could not write anything — the panel was empty and no fills persisted. Swapping to the `service_role` key restored read+write immediately (verified: panel populated, test write OK, no RLS errors).

## Impact on dotforge
- Add to a Supabase/database rules file: "backend services use service_role, never anon; decode `payload.role` to verify." Candidate for `rules/database.md` or a stack-backend rule.
- Pairs with a security note: never grant `anon` policies on sensitive tables to "fix" a backend write failure.

## Decision
Pending
