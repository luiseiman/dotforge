---
id: practice-2026-06-04-postgres-check-before-rls
title: A CHECK-constraint error (23514) does not mean an INSERT passed RLS
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [postgres, rls, debugging, supabase]
tested_in: TradingBot
incorporated_in: ["stacks/supabase/rules/database.md"]
replaced_by: null
---

## Description
In Postgres, table CHECK constraints are evaluated before the RLS `WITH CHECK` policy on an INSERT. So a `23514` (check_violation) error does NOT imply the row passed row-level security — it failed the constraint first, before RLS was ever reached. Do not infer that a role has write permission just because you saw a constraint error instead of a `42501`.

## Evidence
While diagnosing TradingBot writes, a `23514` on `bot_reconciliation_log` (invalid `target_kind`) was misread as "the bot passes RLS here, so the key must be service_role." That was wrong: the key was `anon`, and the row simply died on the CHECK before RLS evaluated. Once the constraint was fixed, the same insert would have hit `42501`. The false inference cost a detour before the real cause (anon key) was found.

## Impact on dotforge
- Add a debugging note to a Postgres/Supabase rules file: error-code ordering (constraint → RLS), and "don't infer permissions from which error fired first."

## Decision
Pending
