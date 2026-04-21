---
id: model-invokes-slash-commands
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-04-17
tags: [capability, skills, slash-commands, high-priority, v2.1.108]
tested_in: []
incorporated_in: ['3.2.0']
---

# Model can now invoke built-in slash commands

## Observation

v2.1.108: Claude (the model) can directly invoke built-in slash commands as part of its tool use loop. Previously slash commands were user-only. This is a material capability change.

## Why it matters for dotforge

Several dotforge skills are exposed as slash commands (`/forge audit`, `/forge capture`, `/cap`, etc.). A model that can self-invoke these can:

1. Decide to run `/forge audit` unprompted when it notices config drift
2. Capture insights via `/cap` automatically instead of asking the user
3. Trigger `/btw` or other meta-commands on its own

This changes the dynamics of our skill design:
- Skills that were "user-invocable safety valves" (like `/forge reset`, `/forge unregister`) now need to be more explicitly gated
- `user-invocable: true` frontmatter becomes ambiguous — does it restrict model invocation too?
- Our rules/skills written pre-v2.1.108 assumed only the user would trigger them

## Required update

1. Audit all slash commands in `global/commands/` and `skills/*/` for:
   - Whether model self-invocation is desirable
   - Whether they need a new `disable-model-invocation: true` frontmatter (see related practice on the `disable-model-invocation` skill frontmatter field in v2.1.110)

2. Add a section to `domain/rule-effectiveness.md` frontmatter fields table:
   | `disable-model-invocation` | boolean | Skill can only be invoked by the user, not the model |

3. Consider adding to `domain/agent-orchestration.md` a note about self-invocation vs delegation patterns

## Affected files

- `.claude/rules/domain/rule-effectiveness.md`
- `.claude/rules/domain/agent-orchestration.md`
- Audit of `global/commands/*.md` + `skills/*/SKILL.md`

## Related

- `disable-model-invocation: true` frontmatter (v2.1.110 fix reference) — needs
  its own practice or rolled into this one
