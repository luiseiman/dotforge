---
globs: "**/*trade*,**/*position*,**/*portfolio*,**/*thesis*,**/*earnings*,**/*screen*,**/*catalyst*"
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
