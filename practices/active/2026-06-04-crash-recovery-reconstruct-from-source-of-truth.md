---
id: practice-2026-06-04-crash-recovery-reconstruct-from-source-of-truth
title: Crash/restart recovery must reconstruct real state from the external source of truth before abandoning
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [reliability, recovery, distributed-systems, deploy]
tested_in: TradingBot
incorporated_in: ["stacks/trading/rules/trading.md"]
replaced_by: null
---

## Description
When a process is interrupted mid-operation (deploy, crash, OOM) and resumes, do not blindly abandon in-flight work as "lost." Reconstruct the real state from the external source of truth (e.g. the broker's actual fills) to decide whether the work partially completed, then resume the safe completion path instead of orphaning exposure. Guard the resume with a broker-truth check so an over-estimated remainder cannot double-act. And remember: EVERY deploy is a restart — a recurring window of risk for half-finished operations, so this path runs often, not rarely.

## Evidence
TradingBot's `recover_in_flight_operations` marked any `running` op `FAILED_NAKED_ABANDONED` without querying the broker — leaving real naked legs orphaned. Since we deployed 4 times in one session, each rebuild was a restart that could strand a half-executed arb. Fix: inspect persisted leg fills; if the SELL filled but the BUY didn't, resume the break-even watcher (guarded by `_already_filled_buy_qty` so it never re-buys filled qty), abandoning only when nothing is recoverable.

## Impact on dotforge
- Candidate for a reliability rule: "recovery reconstructs from the source of truth before declaring loss; treat every deploy as a restart and design the in-flight resume path accordingly."

## Decision
Pending
