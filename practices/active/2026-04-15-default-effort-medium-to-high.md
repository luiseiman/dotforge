---
id: default-effort-medium-to-high
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-04-15
tags: [model-routing, effort, drift, medium-priority]
tested_in: []
incorporated_in: [v3.1.0]
---

# Default effort changed: medium → high (v2.1.94, 2026-04-07)

## Observation

Claude Code v2.1.94 changed the default effort level from `medium` to `high` globally.
dotforge's `model-routing.md` and `rule-effectiveness.md` describe effort tiers but
do not state the new default, and skill/agent frontmatter examples assume medium.

## Implication

- Skills/agents without explicit `effort:` now run at `high` by default — more tokens,
  deeper reasoning, slower turns.
- Cost analysis in any benchmark previously assuming `medium` baseline is now skewed.
- Agents tuned for `haiku`/`sonnet` should explicitly set `effort: low` or `medium` if
  they don't want the new high default.

## Action

1. Document the new default in `domain/model-ids.md` and `model-routing.md`
2. Audit `agents/*.md` and `skills/*/SKILL.md` — flag any that should pin lower effort
3. Consider whether dotforge's reference agents should explicitly set effort to keep
   benchmark consistency

## Affected files
- `.claude/rules/domain/model-ids.md`
- `.claude/rules/model-routing.md`
- `agents/researcher.md`, `agents/test-runner.md` (likely candidates for `effort: low`)
