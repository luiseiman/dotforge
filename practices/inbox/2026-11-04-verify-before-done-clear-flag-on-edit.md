---
id: practice-2026-11-04-verify-before-done-clear-flag-on-edit
title: `clear_flag` action for behaviors v3 so an Edit/Write after the test run invalidates `verification_done` (test → edit → push currently passes the gate)
source: "/forge scout — top-starred Claude Code config repos (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [behaviors, verify, compiler, schema]
tested_in: []
incorporated_in: []
replaced_by: null
effectiveness: null
error_type: null
---

## Description
`verify-before-done` grants the push on any prior test command and only consumes the flag at `git push`; no later edit revokes it, so test → edit → push ships unverified code. `docs/v3/SCHEMA.md` has only `evaluate | set_flag | check_flag`. CCDK solves the equivalent with a per-session manifest of touched files (PostToolUse) and a Stop advisory restricted to those files. The minimal dotforge fix is a fourth action `clear_flag` and a third trigger in `verify-before-done` on `Edit|Write|MultiEdit` that clears `verification_done`.

## Evidence
`behaviors/verify-before-done/behavior.yaml` (2 triggers), `docs/v3/SCHEMA.md:113` (3 actions). CCDK `hooks/track-file-touch.sh`, `hooks/snapshot-baseline.sh`, `hooks/review-on-stop.sh`.

## Impact on dotforge
- `docs/v3/SCHEMA.md` + `docs/v3/SPEC.md`: `clear_flag` action (no counter, no level, removes flag)
- `scripts/compiler/compile.sh`: emit `forge_flag_clear` branch; `scripts/runtime/lib.sh` already has flag primitives — verify a clear helper exists
- `behaviors/verify-before-done/behavior.yaml`: third trigger; new scenario `scenario_edit_after_test_revokes`
- Touches the compiler → production posture (propagates to every project with behaviors); recompile downstream via `/forge sync`

## Decision
Pending — captured from the 2026-11-04 scout (23 repos). Items 1–2 of the same scout shipped as v4.8.1, item 4 as v4.9.0; item 3 (expanded deny lists) was explicitly declined by the user.
