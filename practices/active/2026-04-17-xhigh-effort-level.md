---
id: xhigh-effort-level
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-04-17
tags: [effort, model-routing, drift, high-priority, v2.1.111]
tested_in: []
incorporated_in: ['3.2.0']
---

# New effort level: `xhigh`

## Observation

v2.1.111 added `xhigh` effort level between `high` and `max`, exclusive to Opus 4.7. Access via `/effort`, `--effort` CLI flag, or model picker. Other models fall back to `high` when xhigh is requested.

## Required update

`domain/rule-effectiveness.md` frontmatter fields table lists effort values as `low, medium, high, max, integer`. Must be updated to include `xhigh`:

| Field | Values |
|-------|--------|
| `effort` | `low`, `medium`, `high`, `xhigh`, `max`, integer |

`domain/model-ids.md` default effort section (just added in v3.1.0) mentions `high` as default but doesn't catalog all tiers. Should include xhigh note.

## Affected files

- `.claude/rules/domain/rule-effectiveness.md`
- `.claude/rules/domain/model-ids.md`

## Impact

Skills/agents targeting high-reasoning Opus 4.7 tasks can now opt into xhigh for extra depth without jumping to `max` (which has bigger cost implications). Worth considering for `security-auditor` and `architect` agents on complex tasks.
