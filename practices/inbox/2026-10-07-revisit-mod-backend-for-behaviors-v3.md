---
id: practice-2026-10-07-revisit-mod-backend-for-behaviors-v3
title: Revisit a `--target mod` compiler backend for behaviors v3 once Claude Mods have 2+ months of stability
source: "/forge update 2026-10-07 — native-first decision B, deferred"
source_type: process
discovered: 2026-10-07
status: inbox
tags: [behaviors, v3, mods, compiler, native-first, deferred]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
Claude Mods (v2.1.287+) can express everything behaviors v3 does, more simply: per-session counters in a module `Map` keyed by `$.session.id()`, `tool.call`/`tool.check` middleware returning `{deny}` or `next(e)`, `$.ui.ask` for a real user override (replaces the tool_input-hash reinvocation trick), result rewrite or `prompt.submit` context for nudges, `$.command.register` for `/forge-behavior off`, `$.store` for persistence across reloads. A `--target mod` backend of `scripts/compiler/compile.sh` would emit `register.js` + per-behavior JSON instead of bash hooks.

Deferred on 2026-10-07 because: the API was 5 days old; mods do NOT load under `--safe-mode`, `disableAllHooks`, `allowManagedModsOnly`/`allowManagedHooksOnly`, WSL Desktop sessions, CLI <2.1.287, or after 3 hooks-worker crashes (bash settings hooks keep running in all but `disableAllHooks`); module state is lost on reload; and demand is unproven (0 overrides, 4/12 projects adopted behaviors). Native-first principle: validate delta demand before expanding native-dependent surface.

## Evidence
Explore agent report 2026-10-07 (capability matrix, Part 3) against code.claude.com/docs/en/plugins/mods + CHANGELOG 2.1.287–2.1.292. v4.7.0 already fixed the real v3 defect (nudges never reached the model) in the bash backend, so there is no urgency.

## Impact on dotforge
- Trigger to re-evaluate: `/forge watch` shows Mods API unchanged for ≥2 months (≈ v2.1.330+), or a project asks for `$.ui.ask`-style overrides, or a managed environment forbids bash hooks but allows mods.
- If adopted: `scripts/compiler/compile.sh --target mod`, `scripts/runtime/` JS twin, keep bash as fallback for the environments above; retire `.forge/runtime/state.json` only when every adopter is on the mod backend.
- Python-regex → JS `RegExp` translation in conditions must reject unsupported inline flags.

## Decision
Pending — revisit at the next `/forge watch` after 2026-12-01.
