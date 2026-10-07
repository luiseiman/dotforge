---
id: practice-2026-06-04-cancel-must-persist-terminal-state
title: A cancel operation must persist terminal state, not just set a cooperative flag
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [async, state-machine, reliability, api-design]
tested_in: TradingBot
incorporated_in: ["stacks/trading/rules/trading.md"]
replaced_by: null
---

## Description
When a "cancel" action relies solely on setting a cooperative flag that a background loop/watcher checks at its next iteration, it silently fails if that watcher is dead, orphaned, or never resumed (e.g. after a restart). The entity stays stuck in a non-terminal status forever and keeps showing in dashboards. A cancel endpoint must ALSO persist the terminal status directly, so it works regardless of whether a live worker honours the flag. The cooperative flag still matters for a live worker to exit cleanly without corrupting in-flight work — but it's not sufficient on its own.

## Evidence
`POST /api/ratio/{id}/cancel` in TradingBot only set `_cancel_flags[op_id]=True`. For a naked leg whose break-even watcher had died, the flag was never processed; the op stayed in `retrying_missing_leg` indefinitely and had to be fixed by hand in the DB. Fix: `cancel()` now also calls `finalize_operation(status=CANCELLED)`, so it terminates the op whether or not the watcher is alive.

## Impact on dotforge
- Candidate for a backend/reliability rule: "cancel/stop operations persist the terminal state directly; never depend only on a cooperative flag a possibly-dead worker must observe."

## Decision
Pending
