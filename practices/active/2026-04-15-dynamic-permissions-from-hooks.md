---
id: dynamic-permissions-from-hooks
source: watch:code.claude.com/docs/en/hooks
status: active
captured: 2026-04-15
tags: [hooks, permissions, domain-knowledge, new-feature]
tested_in: []
incorporated_in: [v3.1.0]
---

# New hook output API: dynamic permission mutation

## Observation

Hooks can now mutate the runtime permission state via JSON output. Documented in
the official hooks reference, never covered in dotforge.

`PermissionRequest` and `PreToolUse` hooks may emit:

```json
{
  "hookSpecificOutput": {
    "decision": {
      "behavior": "allow|deny",
      "updatedInput": { ... },
      "updatedPermissions": [
        { "type": "addRules",        "rules": ["Bash(make *)"] },
        { "type": "replaceRules",    "rules": [...] },
        { "type": "removeRules",     "rules": [...] },
        { "type": "setMode",         "mode": "auto|default|plan|acceptEdits" },
        { "type": "addDirectories",  "directories": ["/tmp/build"] },
        { "type": "removeDirectories","directories": [...] }
      ]
    }
  }
}
```

## Why it matters for dotforge

This is a powerful primitive for v3 behaviors:
- A behavior can self-elevate its allowlist for the duration of a session
- A safety hook can downgrade a session to `plan` mode after detecting a risk
- Working-directory whitelisting becomes runtime-mutable, not just static

Currently dotforge's permission model rule (`domain/permission-model.md`) describes
the **static** cascade. It does not mention this API.

## Action

1. Add a section to `domain/permission-model.md`: "Dynamic mutation from hooks"
2. Add a section to `domain/hook-events.md` covering the PermissionRequest output
   shape
3. Consider whether v3 behaviors should expose a `permission_mutation` action type
   in the YAML schema (would complement existing `evaluate`, `set_flag`, `check_flag`)

## Affected files
- `.claude/rules/domain/permission-model.md`
- `.claude/rules/domain/hook-events.md`
- `docs/v3/SCHEMA.md` (if behavior schema gets a new action type)
