---
id: psr-gate-baseline-adrs
source: tradingview-session
status: active
captured: 2026-04-27
tags: [backtesting, statistics, adr, multiple-testing, deflated-sharpe]
tested_in: [tradingview]
incorporated_in: ['3.4.1']
---

# Aplicar PSR(benchmark) > 0.95 como gate antes de declarar baseline en cualquier ADR

## Observation

In the `tradingview` repo, an ADR (2026-04-23) declared "Dual Momentum
SPY/QQQ/BIL 12m" as the official baseline of the passive-US sleeve based on
walk-forward OOS Sharpe 1.08 vs QQQ B&H 1.04 (delta = +0.04) and Calmar 2.78
vs 1.66.

A look-ahead bug was later found in `app/swing.py::run_dual_momentum_pair`.
After fixing it, the OOS metrics deflated to Sharpe 1.06 vs 1.04. The
backtest in-sample (22y) was unaffected.

We then implemented the **Probabilistic Sharpe Ratio** (Bailey & López de
Prado 2012) and computed `PSR(benchmark = QQQ B&H)` for all 9 strategies
tested in the repo:

| Strategy            | SR_y  | PSR(QQQ) |
|---------------------|-------|----------|
| Dual Mom 12m (best) | 0.89  | **0.70** |
| RMA top-3           | 0.75  | 0.48     |
| Vol target QQQ      | 0.72  | 0.42     |
| QQQ + SMA200        | 0.70  | 0.38     |

**Not a single strategy** in the repo passed `PSR(QQQ) > 0.95`. The "best"
strategy gave us a 70% probability of having a true Sharpe > QQQ — meaning
30% probability of being worse than B&H. That's not a baseline; that's a
coin-flip with extra steps.

## Lesson

Sharpe-ratio deltas of +0.02 to +0.04 (typical "the strategy beats benchmark"
deltas in retail backtests) are **statistically indistinguishable from noise**
when n is in the order of thousands of daily observations. The naked eye sees
a ranking; the math sees a wash.

A baseline ADR is a strong claim — it commits the project to operate the
strategy with discipline, write rebalancing code, monitor it. Making that
commitment based on a 70% confidence is bad epistemics.

## Suggested action

Add to the project rule (template-level, applicable to any backtesting
project):

> Before any ADR declares a strategy "baseline" or "winner" over another
> strategy, compute `PSR(benchmark)` per Bailey & López de Prado 2012:
>
> 1. PSR(benchmark) = Pr(true Sharpe > Sharpe of benchmark)
> 2. Threshold: PSR(benchmark) > 0.95 to claim significance
> 3. If PSR < 0.95, the ADR may still document the strategy as an
>    alternative, but cannot call it a "baseline" or claim it "supersedes"
>    another option
>
> When testing > 5 strategies in the same project, also report DSR (Deflated
> Sharpe Ratio) using the empirical variance across the trial Sharpe ratios.
> DSR > 0.95 is the harder gate when multiple-testing is a concern.
>
> Implementation reference: `app/metrics.py` (stdlib-only, no scipy needed
> via `statistics.NormalDist`).

## Implementation cost

- Math is ~50 lines (PSR + expected_max_sharpe + DSR), stdlib-only.
- Tests: ~150 lines covering reference values, monotonicity, edge cases.
- One report script that takes the strategy equity curves and produces a
  table.

Total: ~3 hours for any new repo. Lifetime savings: avoiding multi-month
commitments to baselines that were never significant to begin with.

## Generalization

This is a research-quality rule applicable to any quant trading repo, but
the deeper principle generalizes:

> When ranking N options based on a noisy metric, compute the probability
> that the top-ranked option is genuinely better than alternatives. If that
> probability < threshold, the ranking is decoration — don't anchor decisions
> on it.

References:
- Bailey, D. H. & López de Prado, M. (2012). *The Sharpe Ratio Efficient Frontier.*
- Bailey, D. H. & López de Prado, M. (2014). *The Deflated Sharpe Ratio:
  Correcting for Selection Bias, Backtest Overfitting and Non-Normality.*
- Lo, A. (2002). *The Statistics of Sharpe Ratios.*
