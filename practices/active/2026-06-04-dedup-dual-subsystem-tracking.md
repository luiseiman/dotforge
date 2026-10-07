---
id: practice-2026-06-04-dedup-dual-subsystem-tracking
title: Aggregated views must dedup obligations tracked by two subsystems
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [data-modeling, ui, correctness, accounting]
tested_in: TradingBot
incorporated_in: ["stacks/trading/rules/trading.md"]
replaced_by: null
---

## Description
When two subsystems independently record the same underlying obligation/event, a view that aggregates both sources will double-count unless it explicitly subtracts the overlap by a shared key. Compute one source up front, build a per-key quantity map, and deduct it from the other before summing/emitting.

## Evidence
TradingBot's `/api/imbalances` summed the carry-forward residual AND the ratio engine's naked legs. The same incomplete plazo_arb leg (TXAR 32 units) was recorded in both, so it showed once inside the residual's 742 and again as a `ratio_naked` 32 — inflating exposure to 774 vs the real 742. Fix: compute `ratio_naked` items first, subtract their per-ticker qty from the residual naked qty before emitting.

## Impact on dotforge
- Candidate for a data-modeling/correctness rule: "when two subsystems can record the same event, the aggregate view dedups by key; never sum overlapping sources."

## Decision
Pending
