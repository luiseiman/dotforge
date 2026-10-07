---
id: practice-2026-06-04-verify-source-of-truth-before-cleaning-drift
title: Verify the real source of truth before deleting state that looks like phantom drift
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [correctness, data-integrity, reconciliation, trading]
tested_in: TradingBot
incorporated_in: ["stacks/trading/rules/trading.md"]
replaced_by: null
---

## Description
State that appears to be "phantom drift" because it contradicts an aggregated/consolidated view is not necessarily wrong. Before auto-deleting or dismissing it, verify against the real source of truth. A record that contradicts a consolidated net position may be a legitimate forward/pending leg the net simply does not expose (different settlement, off-balance obligation). Don't let an automated reconciler destroy state it judges "phantom" — gate destruction behind a real-world confirmation or an explicit human decision.

## Evidence
TradingBot's reconciler auto-dismissed residual imbalances whose sign contradicted the broker's consolidated net position, deleting real pending covers (TXAR). The "short" residual was the un-executed forward (24hs) leg of a plazo_arb, which the consolidated net (in CI) does not show — not phantom at all. Before removing EDN/GD30 from the panel we queried the broker's actual position to confirm there was no real exposure being hidden. Fix: the reconciler now only logs the drift; nothing auto-deletes — closing requires an executed cover or an explicit user dismiss.

## Impact on dotforge
- Candidate for a data-integrity rule: "never auto-destroy state that merely looks like drift; confirm against the source of truth or require explicit human action."

## Decision
Pending
