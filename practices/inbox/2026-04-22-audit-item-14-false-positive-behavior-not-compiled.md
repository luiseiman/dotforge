---
id: audit-item-14-false-positive-behavior-not-compiled
source: live-session
status: inbox
captured: 2026-04-22
tags: [audit, scoring, v3-behavior, false-positive, item-14, high-priority]
tested_in: [tradingview]
incorporated_in: []
---

# Audit item 14 (Behaviors v3) is a false positive — counts declaration, not enforcement

## Observation

During a `/forge audit` on the `tradingview` project we scored **item 14 = 1** because `behaviors/index.yaml` listed four core behaviors with `enabled: true`, matching the checklist criterion literally:

> 1: At least one v3 behavior enabled via `behaviors/index.yaml`, compiled hooks under `.claude/hooks/generated/`, or behavior hook references in `settings.json`

But the project had **no compiled hook** under `.claude/hooks/generated/` and **no behavior hook reference** in `settings.json`. Only the YAML declaration. We probed the live behavior afterwards:

```
$ ls .claude/hooks/generated 2>/dev/null
(does not exist)
$ grep -l "verify-before-done" .claude/hooks/*.sh
(no matches)
```

The behavior was inert. A `git push` without prior tests would have passed silently. The audit point was awarded for intent, not enforcement. Total score would have been 9.7/10 while the project's actual v3 coverage was effectively 0.

## Root cause

The checklist uses `OR` across three evidence sources:
1. Entries in `behaviors/index.yaml` with `enabled: true`
2. Compiled hooks under `.claude/hooks/generated/`
3. Behavior hook references in `settings.json`

Source 1 alone does not imply sources 2 or 3. Declaring a behavior in `index.yaml` is cheap and does not generate any enforceable artifact unless `scripts/compiler/compile.sh` runs. A fresh bootstrap creates the index file but **does not** invoke the compiler, so every freshly bootstrapped project auto-passes item 14 with zero real enforcement.

## Proposed fix

Change item 14 from `OR` to `AND` between declaration and runtime evidence. New text:

> **1: At least one v3 behavior is enabled in `behaviors/index.yaml` AND has either a compiled hook under `.claude/hooks/generated/` or a direct reference in `settings.json` `hooks` section.**
>
> **Verification:** For each entry in `behaviors/index.yaml` with `enabled: true`, verify at least one of:
> - A generated hook file exists matching `.claude/hooks/generated/<id>__*.sh` and is executable.
> - `.claude/settings.json` `hooks` section contains a command path matching `<id>` or its behavior.yaml `matcher` event.
>
> If `index.yaml` has enabled behaviors but no artifact is found for any of them, score 0 with a warning.

## Affected files

- `audit/checklist.md` (rewrite item 14)
- `audit/scoring.md` (optionally add a footnote about the AND requirement)
- `audit/score.sh` (extend verification if it automates this item)

## Workaround used in the session

Compiled the behavior manually by writing `.claude/hooks/verify-before-done.sh` from the YAML policy and wiring it into `settings.json` `PreToolUse(Bash)`. Verified with an 8-scenario lifecycle test (nudge → warning → block-message; flag set by pytest/ruff; flag consumed by push). Commit `05c3516` in `luiseiman/tradingview`.

## Secondary observation

The bootstrap flow does not run the behavior compiler. Either:
- `forge-bootstrap` should invoke `scripts/compiler/compile.sh` after generating `behaviors/index.yaml`, or
- The audit should fail louder when index.yaml exists but no compiled artifact does (turning this false-positive into a hard signal).

Prefer the first — make the bootstrap produce an enforcing configuration by default.
