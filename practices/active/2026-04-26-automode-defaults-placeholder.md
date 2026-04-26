---
id: practice-2026-04-26-automode-defaults-placeholder
title: autoMode.allow|soft_deny|environment supports "$defaults" placeholder (v2.1.118)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [auto-mode, settings, permissions, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
`autoMode.allow`, `autoMode.soft_deny`, and `autoMode.environment` arrays in `settings.json` now accept a literal `"$defaults"` entry. Including it merges your custom rules with the built-in classifier list instead of replacing it. Available since v2.1.118.

## Evidence
CHANGELOG v2.1.118: "Auto mode: include `\"$defaults\"` in `autoMode.allow`, `autoMode.soft_deny`, or `autoMode.environment` to add custom rules alongside the built-in list instead of replacing it".

Before v2.1.118 these arrays were all-or-nothing — defining any custom rule meant losing the built-in classifier surface. The placeholder removes that trade-off and changes the recommended pattern.

## Impact on dotforge
- `.claude/rules/domain/auto-mode.md` — add `$defaults` pattern; clarify that custom-only arrays override defaults
- `template/settings.json.tmpl` — if/when dotforge ships any default `autoMode.*` overrides, prepend `"$defaults"`
- `docs/best-practices.md` — capture the pattern for stacks that want to extend auto mode

## Decision
Pending
