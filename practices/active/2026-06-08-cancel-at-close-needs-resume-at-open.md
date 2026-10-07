---
id: practice-2026-06-08-cancel-at-close-needs-resume-at-open
title: Cancelling in-flight work at a close boundary requires resuming it at the open boundary
source: "own experience"
source_type: experience
discovered: 2026-06-08
status: active
tags: [reliability, lifecycle, state-machine, scheduling, deploy]
tested_in: TradingBot
incorporated_in: ["stacks/trading/rules/trading.md"]
replaced_by: null
---

## Description
When a periodic process cancels unfinished in-flight work at a "close"/shutdown boundary (to avoid leaving things running), it MUST have a matching "open"/start boundary that resumes that work — otherwise the unfinished items are abandoned and accumulate indefinitely. This is doubly broken when the cancel persists a *terminal* status, because the recovery path (which only resumes non-terminal states) will never pick them up again. The fix: at close, *pause* (stop the worker without persisting terminal — keep a resumable status); at open, *resume* (relaunch the workers for pending/retrying items). Define the stop condition explicitly (e.g. "chase until done, or until the user cancels").

## Evidence
TradingBot's `_on_market_close` called `ratio_manager.cancel()` on every active op, which persisted `CANCELLED`. `recover_in_flight_operations` only resumes `pending/retrying/running`, never `cancelled`. So any arbitrage leg not covered before the 17:05 close was abandoned forever — and piled up day after day into a panel full of stale "imbalances" (weeks of accumulation). Fix: `pause_all_for_close()` async-cancels the watcher tasks WITHOUT persisting terminal (the break-even loop is designed to be async-cancelled and resumed), and `_on_market_open` now calls `recover_in_flight_operations()` to relaunch them. Operator policy made explicit: chase a pending leg until covered, or until the user cancels it manually.

## Impact on dotforge
- Candidate for a reliability/lifecycle rule: "any close/shutdown that cancels in-flight work needs a symmetric open/start that resumes it; pause (non-terminal) at close, resume at open; never persist terminal status for work you intend to retry."
- Relates to the existing crash-recovery practice (reconstruct from source of truth) — same family: don't lose in-flight work at boundaries.

## Decision
Pending
