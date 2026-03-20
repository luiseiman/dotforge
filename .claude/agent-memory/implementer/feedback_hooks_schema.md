---
name: hooks-settings-schema
description: Claude Code settings.json hooks require object format with type+command, not plain strings
type: feedback
---

Hooks in `.claude/settings.json` must be objects with `type` and `command` fields, not plain strings.

**Wrong:** `"hooks": ["bash .claude/hooks/block-destructive.sh"]`
**Right:** `"hooks": [{"type": "command", "command": "bash .claude/hooks/block-destructive.sh"}]`

**Why:** Claude Code validates settings.json against a strict JSON schema. Plain strings fail validation.
**How to apply:** Always use object format when writing hook entries in any project's settings.json.
