---
globs: "**/backtest*,**/strategy*,**/*adr*,**/decisions/**,**/metrics.py,**/sharpe*"
domain: trading
last_verified: 2026-04-27
---

# Backtesting ADR Gate — Statistical Significance Before Baseline Claims

## Rule

Before any ADR declares a strategy a "baseline", "winner", or "supersedes" another option, compute `PSR(benchmark)` per Bailey & López de Prado (2012) and gate the claim:

1. **PSR(benchmark) = Pr(true Sharpe > Sharpe of benchmark)**
2. **Threshold: PSR(benchmark) > 0.95** to claim significance
3. If **PSR < 0.95**, the ADR may document the strategy as an alternative — but cannot use the words *baseline*, *winner*, or *supersedes*

When testing **> 5 strategies** in the same project, also report **DSR (Deflated Sharpe Ratio)** using the empirical variance across the trial Sharpe ratios. DSR > 0.95 is the harder gate when multiple-testing is a concern.

## Why

Sharpe-ratio deltas of +0.02 to +0.04 (typical "the strategy beats benchmark" deltas in retail backtests with daily data) are statistically indistinguishable from noise when n is in the order of thousands of observations. The eye sees a ranking; the math sees a wash.

A baseline ADR is a strong claim — it commits the project to operate the strategy with discipline. Making that commitment based on 70% confidence is bad epistemics.

## Implementation

- Math: ~50 lines (PSR + expected_max_sharpe + DSR), stdlib-only via `statistics.NormalDist`. No scipy needed.
- Tests: ~150 lines covering reference values, monotonicity, edge cases.
- One report script that takes equity curves and produces a PSR/DSR table.
- Reference implementation: `app/metrics.py` in the originating repo.

## Generalization

The deeper principle applies beyond trading: when ranking N options based on a noisy metric, compute the probability that the top-ranked option is genuinely better than the alternatives. If that probability < threshold, the ranking is decoration — don't anchor decisions on it.

## References

- Bailey, D. H. & López de Prado, M. (2012). *The Sharpe Ratio Efficient Frontier.*
- Bailey, D. H. & López de Prado, M. (2014). *The Deflated Sharpe Ratio: Correcting for Selection Bias, Backtest Overfitting and Non-Normality.*
- Lo, A. (2002). *The Statistics of Sharpe Ratios.*
