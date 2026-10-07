---
id: practice-2026-10-06-native-audit-tooling-cede-candidates
title: Native audit tooling (plugin eval, /skill-doctor, /doctor prompt-audit, /insights) overlaps dotforge skills — cede candidates (v2.1.261–v2.1.285)
source: "/forge watch — docs/en/whats-new + CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: evaluating
tags: [native-first, audit, skills, rule-effectiveness, benchmark, boundary]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
- `claude plugin eval` (v2.1.263–269): runs a plugin against a test-case suite, scores results, compares to no-plugin baseline; `claude plugin eval init` drafts cases + graders; JSON/HTML report; needs git ≥2.31.
- `/skill-doctor` (v2.1.261): per-skill context cost and usage frequency; flags unused skills.
- `/doctor prompt-audit [path]` (v2.1.283, via bundled `claude-api` skill): flags CLAUDE.md, rules, skills, agents, commands written for older models, stale paths, contradictions. `/checkup` alias.
- `/insights` now recommends auto mode. `claude plugin validate --json`, MCP checks in `validate`.
- `claude doctor` (CLI, read-only diagnostics incl. settings-file validation errors + Remote Control eligibility).

## Evidence
Per `native-vs-dotforge-boundary.md`: "If Claude Code resolves it natively, ADOPT the native solution." Overlaps: `rule-effectiveness` ↔ `/skill-doctor` + `prompt-audit`; `benchmark` ↔ `plugin eval` (baseline comparison is exactly the benchmark skill's premise); `session-insights` ↔ `/insights`; `audit-project` settings validation ↔ `claude doctor`. dotforge's delta remains cross-project aggregation (registry) and domain-rule glob coverage vs git history.

## Impact on dotforge
- `.claude/rules/domain/native-vs-dotforge-boundary.md`: add 4 items to CEDE or SPLIT with verdict
- `skills/rule-effectiveness/SKILL.md`: wrap `/skill-doctor` + `/doctor prompt-audit` output, keep only glob-vs-git coverage
- `skills/benchmark/SKILL.md`: migrate to `claude plugin eval` harness or retire
- `skills/session-insights/SKILL.md`: delegate pattern detection to `/insights`, keep registry feed
- `skills/audit-project/SKILL.md`: run `claude doctor` as item 0
- `global/commands/forge.md`: command table

## Decision
Pending
