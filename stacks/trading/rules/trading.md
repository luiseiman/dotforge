---
globs: "**/*trade*,**/*position*,**/*portfolio*,**/*thesis*,**/*earnings*,**/*screen*,**/*catalyst*"
domain: trading
last_verified: 2026-03-25
---

# Trading & Investment Analysis Rules

## Markets Coverage
- AR: BYMA (acciones, CEDEARs, bonos soberanos/corporativos, ONs), crypto (BTC/ETH/stables), FX (CCL, MEP, blue, oficial)
- US: equities, options (calls/puts, spreads, Greeks), ETFs

## Data Integrity
- NEVER use training data for prices, earnings, or market data — always fetch current data via API or web search
- Verify dates on all financial data: if >24h old for prices or >3 months for earnings, search again
- Cite sources with dates on every data point
- Distinguish between confirmed data and estimates/projections

## Position Tracking
- Every position needs: ticker, entry price, current price, size, thesis, stop-loss
- Track P&L in both local currency and USD where applicable
- CEDEARs: track ratio, underlying price, CCL implicit, and premium/discount vs ADR
- Bonds: track TIR, duration, paridad, and spread vs benchmark

## Thesis Discipline
- A thesis must be falsifiable — define what would invalidate it
- Track confirming AND disconfirming evidence equally
- Review all theses at least quarterly
- If thesis breaks, exit — don't rationalize holding

## Risk
- Position sizing: never >5% of portfolio in single name without explicit confirmation
- Options: always state max loss before entering
- Leverage: explicit risk/reward before using margin
- CCL/MEP arbitrage: track settlement dates and regulatory risk

## Output Format
- Tables for positions and comparisons
- Sparklines or trend indicators for time series
- Color coding: green (on track), yellow (watch), red (broken thesis)
- Always show last updated timestamp on any data table

## Reliability (in-flight operations)
- Cancel operations must persist terminal state directly, not only set a cooperative flag a watcher checks — a dead/orphaned watcher leaves work stuck in non-terminal status forever
- Close/shutdown that cancels in-flight work needs a symmetric open/start that resumes it. Pause (non-terminal) at close; resume at open. Never persist terminal for work you intend to retry — the recovery path skips terminal states
- Recovery from crash/restart must reconstruct real state from the external source of truth (broker fills, exchange positions) before declaring loss. Every deploy is a restart — the resume path runs often, not rarely
- Guard resumes with source-of-truth checks so over-estimated remainders cannot double-act (e.g. `_already_filled_buy_qty`)
- Never auto-destroy state that only *looks* like phantom drift — a residual that contradicts the consolidated net may be a legitimate forward/pending leg. Log the drift; require executed cover or explicit user dismiss to close

## Correctness
- Pin down a metric's semantics before comparing across sources or acting. A label ("SHORT", "exposure", "P&L") is not a definition — a pending arb leg is not a net directional position
- When two subsystems can record the same underlying obligation/event, an aggregate view MUST dedup by shared key. Compute one source first, build a per-key quantity map, deduct it from the other before summing
