---
id: practice-2026-11-04-placebo-controlled-behavior-evals
title: Validate behaviors with placebo-controlled evals before shipping them on
source: "/forge scout — affaan-m/ECC v2.2.3 (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [behaviors, v3, evaluation, methodology, ecc]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
ECC `docs/gateguard/question-effectiveness.md` evaluates its GateGuard hook with four arms — off, gate, placebo (a denial that asks irrelevant questions), minus-target (gate without the key question) — hypotheses written before the run, hidden graders, cost per arm reported. Result: its 72-session pilot showed ~45% more turns and no measurable quality gain, contradicting the "+2.25" in the skill description. The method is the valuable part, not the verdict.

dotforge disabled `search-first` in v3.6.1 for false positives on anecdote, keeps `verify-before-done` on because it "worked once live", and defers a `--target mod` backend on demand estimates. None of these decisions has an arm-controlled measurement. `claude plugin eval` (v2.1.269+) now provides the harness (multi-run, graders, with/without baseline) if behaviors are packaged as a plugin via `/forge plugin`.

## Evidence
ECC `docs/gateguard/question-effectiveness.md`, `docs/gateguard/*pilot*`. dotforge `native-vs-dotforge-boundary.md` SPLIT verdict relies on an override count (0), not on outcome quality.

## Impact on dotforge
- `docs/v3/EVAL-METHOD.md`: arms (off / behavior / placebo-block / behavior-without-escalation), pre-registered hypotheses, cost reporting
- `/forge plugin` → `claude plugin eval` pipeline for `verify-before-done` and `search-first` (re-enable candidate) with 5+ runs per arm
- `behaviors/<id>/behavior.yaml` `metadata.evidence:` field linking the eval report; `/forge behavior describe` shows it

## Decision
Pending
