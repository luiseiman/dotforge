---
id: practice-2026-05-13-automode-hard-deny
title: autoMode.hard_deny — third tier blocking unconditionally (v2.1.136)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [auto-mode, settings, permissions, security, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
`autoMode.hard_deny` is a new array in `settings.json` that lists classifier rules which block UNCONDITIONALLY — independent of user intent or `autoMode.allow` exceptions. Sits as a third tier alongside `allow` and `soft_deny`:

- `allow` — auto-approve when rule matches
- `soft_deny` — block, but classifier may grant pass if user intent justifies
- `hard_deny` — block always, no override path

```json
{
  "autoMode": {
    "hard_deny": ["Bash(rm -rf /*)", "Bash(curl *|sh)"],
    "allow": ["$defaults", "Bash(make build:*)"],
    "soft_deny": ["$defaults"]
  }
}
```

## Evidence
CHANGELOG v2.1.136: "Added `settings.autoMode.hard_deny` for auto mode classifier rules that block unconditionally regardless of user intent or allow exceptions".

Important security primitive for projects where certain commands must NEVER auto-approve, even when the classifier finds them benign in context (e.g., a curl pipe to sh that the model rationalizes as "installing a known package").

## Impact on dotforge
- `.claude/rules/domain/auto-mode.md` — add `hard_deny` to the autoMode section alongside `allow`/`soft_deny`/`environment`; show example with `$defaults` interop
- `template/settings.json.tmpl` — consider whether to ship a default `hard_deny` list for known-bad patterns (curl|sh, base64 decode pipe, eval of env vars)
- `audit/checklist.md` — possible new check: "hard_deny configured for projects in auto mode handling secrets"

## Decision
Pending
