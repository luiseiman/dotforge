---
id: practice-2026-11-04-context-cost-monitor-hook
title: Runtime context/cost/loop monitor via additionalContext (warn at 35% left, critical at 25%; repeat-call detector)
source: "/forge scout — affaan-m/ECC v2.2.3 (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [hooks, context, compaction, cost, ecc]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
ECC `scripts/hooks/ecc-context-monitor.js` (PostToolUse) reads transcript token usage and session cost and injects `hookSpecificOutput.additionalContext` at two tiers — WARNING at 35% context remaining or $10, CRITICAL at 25% or $50 — plus a loop detector for repeated identical tool calls, with debounce state so it fires once per threshold. `suggest-compact.js` nudges at tool call 50 then every 25. Both use the model-visible channel (not `systemMessage`).

dotforge `compaction-strategy.md` prescribes manual compaction at 80% but nothing in runtime tells the model where it is; `pre-compact-warning.sh` (UserPromptSubmit) exists but check what it measures and whether it uses `additionalContext`.

## Evidence
ECC `scripts/hooks/ecc-context-monitor.js`, `suggest-compact.js`. Hooks reference: `additionalContext` is the only model-visible channel (dotforge v4.7.0 finding).

## Impact on dotforge
- `template/hooks/pre-compact-warning.sh`: emit `additionalContext` with %-left and the `/forge compact-task` hint at 80%/90%; add repeat-call detection keyed on tool_input hash (reuse `forge_tool_input_hash` from `scripts/runtime/lib.sh`)
- `compaction-strategy.md`: document the runtime signal
- Cost tier needs the SessionStart `estimated_cache_write_usd` / Stop payload fields (v2.1.251+) — verify availability before wiring

## Decision
Pending
