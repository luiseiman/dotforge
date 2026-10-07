---
id: practice-2026-10-06-maxeffortlevel-and-frontmatter-effort-honored
title: "maxEffortLevel caps effort; frontmatter effort/model now honored on pinned-default models (v2.1.252–v2.1.280)"
source: "/forge watch — CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [effort, models, agents, cost, settings]
tested_in: []
incorporated_in: ["agents/security-auditor.md", ".claude/rules/domain/rule-effectiveness.md", ".claude/rules/domain/model-ids.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
- `maxEffortLevel` (v2.1.267): top-level or per-model under `modelSettings`; caps effort on every provider; lowest cap from any scope (incl. `--settings`) wins over a higher managed cap.
- v2.1.259/267: `effort:` and `model:` frontmatter on commands, skills, subagents were silently **ignored** on pinned-default models (Opus 4.7/4.8, Fable 5) and `model:` on commands/skills — now honored. In auto mode a frontmatter `model:` the classifier doesn't support keeps the session model.
- v2.1.280: launch-default effort hold no longer overrides `effortLevel`, per-model level, or `-p`/SDK effort. `--effort` lifts the hold for the session; `s` in `/effort` picker sets session-only. `/effort` saves per-model default (v2.1.252). Opus 5 at xhigh/max with thinking off sends `high` (v2.1.251); error message names `/effort high` as fix (v2.1.243).

## Evidence
`agents/security-auditor.md` has `effort: max`, `agents/architect.md` `effort: high` — these are now live and `security-auditor` cost rises accordingly. `rule-effectiveness.md:13-14` table lists `effort`/`model` fields without the "was ignored" history. 0 hits for `maxEffortLevel`.

## Impact on dotforge
- `agents/security-auditor.md`: reconsider `max` → `xhigh` (per `model-ids.md` guidance)
- `.claude/rules/domain/model-ids.md`: effort section + `maxEffortLevel`
- `.claude/rules/domain/rule-effectiveness.md`: frontmatter table footnote
- `global/settings.json.tmpl`: optional `maxEffortLevel` per tier (light/standard projects)
- `.claude/rules/domain/workflow-and-ultracode-policy.md`: tier → effort cap mapping

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.6.0 (/forge update, catalogue block).
