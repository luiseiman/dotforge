# Behavior Evaluation Method (placebo-controlled)

How to decide whether a behavior earns `enabled: true` by default. Adopted from the
arm design in ECC's GateGuard pilot (`docs/gateguard/question-effectiveness.md`,
scouted 2026-11-04), whose own result — ~45% more turns, no quality gain — is the
reason this method exists: a block that *feels* protective can just be friction.

## Arms (run every arm on the same task set)

| Arm | What runs | Isolates |
|-----|-----------|----------|
| `off` | behavior disabled | baseline |
| `on` | behavior as shipped | total effect |
| `placebo` | same block/nudge timing, but the message is unrelated to the policy (e.g. "state the current date, then retry") | cost of *any* interruption |
| `minus-escalation` | behavior with every level forced to `nudge` | value of blocking vs advising |

A behavior ships on by default only if `on` beats `placebo` on quality **and** the
turn/cost overhead of `on` vs `off` is accepted explicitly in `metadata.evidence`.

## Protocol

1. **Pre-register** the hypothesis in `docs/v3/evals/<behavior>/<date>.md` before any run: metric, expected direction, minimum effect, task set, number of runs per arm (≥5).
2. **Task set**: 6–10 tasks with a verifiable outcome (tests pass, lint clean, file untouched, PR merges). Mix "the policy should fire" and "the policy must stay silent" tasks — false positives are measured, not assumed.
3. **Harness**: package the behavior with `/forge plugin` and run `claude plugin eval` (v2.1.269+: multi-run, graders, with/without delta, JSON + HTML report). Set `--max-budget-usd` per arm and record it.
4. **Graders**: deterministic where possible (`file_exists`, `tool_used`, test exit code). An LLM judge grades only the free-text outcome and never sees which arm produced it.
5. **Report**: per arm — pass rate, median turns, median cost, false-positive count (policy fired on a "stay silent" task), override count (soft_block reinvocations). Write the verdict into `behaviors/<id>/behavior.yaml` → `metadata.evidence` with the report path.
6. **Re-run** after any change to the behavior's conditions, escalation table or rendering, and after a Claude Code upstream change that alters hook semantics (see `docs/changelog.md` v4.7.0 — `systemMessage` was never model-visible).

## Current status

| Behavior | Evidence | Default |
|----------|----------|---------|
| `no-destructive-git` | deterministic regex, hard_block; no eval needed (safety invariant) | on |
| `verify-before-done` | anecdotal (one live soft_block resolved by running tests, 2026-06-04); **no arm eval** | on |
| `search-first` | disabled v3.6.1 on false positives — anecdotal; candidate for the first full eval | off |
| `protect-lint-config` | pattern adopted from ECC; no eval | off |
| `plan-before-code`, `objection-format` | none | off |

Do not promote `search-first` or `protect-lint-config` to on-by-default without a report.
