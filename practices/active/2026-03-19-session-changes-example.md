---
id: practice-2026-03-19-session-changes-example
title: "Session changes detected via post-session hook"
source: "post-session hook — real project"
source_type: experience
discovered: 2026-03-19
status: active
tags: [auto-detected, settings, hooks, rules]
tested_in: example-project
incorporated_in: [template/settings.json.tmpl, stacks/react-vite-ts/hooks/lint-ts.sh, stacks/python-fastapi/rules/backend.md, stacks/python-fastapi/rules/tests.md, stacks/react-vite-ts/rules/frontend.md, template/hooks/lint-on-save.sh]
replaced_by: null
effectiveness: not-applicable
error_type: null
---

## Description
10 modified files detected in `.claude/` of a real project during a session. This practice demonstrates the full pipeline: hook detection → inbox → evaluation → incorporation.

## Modified files
.claude/hooks/block-destructive.sh
.claude/hooks/lint-python.sh
.claude/hooks/lint-ts.sh
.claude/rules/agents.md
.claude/rules/backend.md
.claude/rules/frontend.md
.claude/rules/strategies.md
.claude/rules/tests.md
.claude/settings.json
.claude/settings.local.json

## Evaluation
Reviewed 2026-03-19. Extracted 6 generalizable practices:
1. Granular git permissions in settings.json (no wildcards)
2. Recursive globs in deny list (**/.env vs .env)
3. Defense-in-depth deny entries
4. tsc --noEmit as complementary hook to eslint
5. Factory pattern + dedicated tests.md for Python
6. WebSocket/proxy patterns in frontend rules

Incorporated in: template/settings.json.tmpl, stacks/react-vite-ts/hooks/lint-ts.sh,
stacks/python-fastapi/rules/backend.md, stacks/python-fastapi/rules/tests.md (new),
stacks/react-vite-ts/rules/frontend.md, template/hooks/lint-on-save.sh

Discarded: rules/strategies.md (100% domain-specific), agents.md simplified (subset with no new value)
