---
id: practice-2026-06-04-metric-meaning-before-comparing
title: Confirm what a metric actually models before comparing it or acting on it
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [correctness, domain-modeling, analysis, trading]
tested_in: TradingBot
incorporated_in: ["stacks/trading/rules/trading.md"]
replaced_by: null
---

## Description
A panel/metric labeled "exposure" or "P&L" may not represent what the label suggests. Before comparing it to another source or making a decision, confirm the exact semantics of the number. Comparing two quantities that model different things produces false conclusions (and false alarms).

## Evidence
On TradingBot's imbalances panel, a `SHORT` row read as a directional position, so it was compared against the broker's net position and flagged as a contradiction. It was actually the pending leg of a plazo_arb arbitrage (sold one settlement, owes the buy in the other) — not a net directional short. The mismatch was an artifact of comparing two different concepts. Once the semantics were pinned down (pending arb leg vs net position), the "contradiction" dissolved and the right fix emerged.

## Impact on dotforge
- Candidate for an analysis/domain rule: "pin down a metric's semantics before comparing across sources or acting; a label is not a definition."

## Decision
Pending
