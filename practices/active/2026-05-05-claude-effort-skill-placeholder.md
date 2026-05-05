---
id: claude-effort-skill-placeholder
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-05-05
tags: [skills, effort, design-pattern, medium-priority, v2.1.120]
tested_in: []
incorporated_in: ['3.6.0']
---

# `${CLAUDE_EFFORT}` skill placeholder (v2.1.120) — effort-aware skill content

## Observation

v2.1.120 added support for `${CLAUDE_EFFORT}` in skill content (markdown body, not just frontmatter). Resolves at runtime to the active effort tier (`low | medium | high | xhigh | max`).

## Why it matters for dotforge

Several dotforge skills change behavior based on depth needed:
- `skills/audit-project` could parameterize check depth (low: file presence; high: content + cross-checks)
- `skills/benchmark` could pin its A/B comparisons to current effort
- `skills/session-insights` could adjust how deep it walks history

Currently these skills don't reference effort at all. Adding `${CLAUDE_EFFORT}` lets the user say "give me a quick audit" (effort low) vs "thorough one" (effort high) without forking the skill.

## Required update

1. `domain/rule-effectiveness.md` — frontmatter table already lists `effort`; add to the body the `${CLAUDE_EFFORT}` runtime placeholder concept (skill content, not just frontmatter).
2. Pilot adoption in one skill (likely `audit-project` or `session-insights`) before retrofitting all.

## Affected files

- `.claude/rules/domain/rule-effectiveness.md`
- (pilot) `skills/audit-project/SKILL.md` or `skills/session-insights/SKILL.md`
