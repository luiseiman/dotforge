---
id: practice-2026-10-06-model-defaults-opus55-sonnet55-fable51
title: Default models are now Opus 5.5, Sonnet 5.5, Fable 5.1 with 1M context everywhere (v2.1.219–v2.1.284)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [models, model-routing, context-window, cost, breaking-change]
tested_in: []
incorporated_in: [".claude/rules/domain/model-ids.md", ".claude/rules/domain/context-window-optimization.md", ".claude/rules/domain/compaction-strategy.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
- v2.1.219: Opus 5 (`claude-opus-5`) default Opus, 1M context, fast mode $10/$50 per MTok. Opus 4.7 removed from fast mode.
- v2.1.280: Opus 5.5 (`claude-opus-5-5`) default Opus, $4/$20. Pro and Team Standard default model changed from Sonnet to Opus.
- v2.1.284: Sonnet 5.5 (`claude-sonnet-5-5`) default Sonnet, 1M, $2/$10. Sonnet 5 auto-compact window is the full 1M (compacts ~967K, not 934K).
- v2.1.257: Fable 5.1 (`claude-fable-5-1`) default Fable, 1M, $10/$50.
- Opus 4.7+, Sonnet 5+, Fable get 1M by default on Bedrock/Vertex/Foundry/gateways/custom `ANTHROPIC_BASE_URL`. `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` holds every native-1M model to 200K (v2.1.223). Unknown model IDs get auto-compact cap; `CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1` restores old behavior.
- `ANTHROPIC_DEFAULT_MODEL` sets the model new sessions start on (v2.1.236). `modelPicker` setting controls `/model` rows (v2.1.243, user/managed/`--settings` only). `modelPricing` managed multiplier up to 10x. `/effort` saves a per-model default (v2.1.252). Explore inherits an unrecognized custom model instead of switching to Opus (v2.1.284).

## Evidence
`model-ids.md:12-14` lists opus=`claude-opus-4-8`, sonnet=`claude-sonnet-4-6`, fable=`claude-fable-5`. Fast-mode section cites 4.7/4.8. `context-window-optimization.md:22-23` table lists Opus 4.6 / Sonnet 4.6 only. `compaction-strategy.md` 1M → 800K threshold math assumes Sonnet 4.6. `model-routing.md` has no Opus 5 / Sonnet 5.

## Impact on dotforge
- `.claude/rules/domain/model-ids.md`: full table rewrite + fast mode + effort + Explore sections
- `.claude/rules/domain/context-window-optimization.md`: table + env vars
- `.claude/rules/domain/compaction-strategy.md`: threshold numbers
- `.claude/rules/model-routing.md`: tier → model mapping
- `agents/*.md`: verify `model:` aliases still resolve as intended

## Decision
Accepted 2026-10-06 — incorporated in dotforge v4.4.0 (/forge update, breaking batch).
