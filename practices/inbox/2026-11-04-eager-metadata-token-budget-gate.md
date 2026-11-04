---
id: practice-2026-11-04-eager-metadata-token-budget-gate
title: CI gate on eager-loaded metadata: fail when rules + skill/agent/command descriptions exceed a token budget
source: "/forge scout — affaan-m/ECC v2.2.3 (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [ci, context, rules, skills, ecc]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
ECC measured its own cost: 314 skill descriptions ≈ 26K tokens listed in every session (Claude Code 2.1.296 estimate 25,982 for 302 skills), plus 3.9K agents + 3.5K commands — and against the native ~1%/8K-char skill-listing budget most descriptions are truncated, so the catalog either costs 26K tokens or loses auto-invocation. Their mitigation is a `lean@1` context profile (`manifests/context-profiles/lean@1.json`) with a **blocking 8K-token budget** checked in CI (`context-profiles:check`) — proposed, not yet default.

dotforge has the same disease in a different organ: 2,290 eager rule lines (~27K tokens) per session, 23/26 rules over its own 50-line limit, no gate. The pending "Refactor domain rules to lazy loading" worktree fixes the content; this practice adds the guard so it does not regrow.

## Evidence
ECC `docs/design/context-profile-delivery.tdd.md`, `manifests/context-profiles/lean@1.json`, `scripts/ci/check-context-profiles.js`. dotforge self-review 2026-10-07 (rules agent report).

## Impact on dotforge
- `tests/check-context-budget.sh`: sum lines/chars of `globs:` rules (template + .claude/rules) and of `description:` fields in `skills/*/SKILL.md`, `agents/*.md`, `global/commands/*.md`; fail over configurable budgets (start: rules ≤ 400 eager lines, descriptions ≤ 8K chars)
- Wire into `tests/run_all.sh` + CI; surface the numbers in `/forge audit` (new informational line, not scored)
- `rule-effectiveness.md`: reference the gate

## Decision
Pending
