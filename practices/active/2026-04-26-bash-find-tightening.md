---
id: practice-2026-04-26-bash-find-tightening
title: Bash(find:*) allow rules no longer auto-approve -exec/-delete (v2.1.113)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [permissions, security, upstream, breaking]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
Permission tightening in v2.1.113: a `Bash(find:*)` allow rule no longer auto-approves `find` invocations that include `-exec` or `-delete`. Those flags now drop back to the regular permission flow. Same release also tightened deny-rule matching against `env`/`sudo`/`watch`/`ionice`/`setsid` wrappers, and treated `/private/{etc,var,tmp,home}` on macOS as dangerous removal targets under `Bash(rm:*)`.

## Evidence
CHANGELOG v2.1.113:
- "Security: `Bash(find:*)` allow rules no longer auto-approve `find -exec`/`-delete`"
- "Security: Bash deny rules now match commands wrapped in `env`/`sudo`/`watch`/`ionice`/`setsid` and similar exec wrappers"
- "Security: on macOS, `/private/{etc,var,tmp,home}` paths are now treated as dangerous removal targets under `Bash(rm:*)` allow rules"

dotforge stacks should be audited: any `Bash(find:*)` allow that was relying on auto-approval of `find -delete` for cleanup will now prompt.

## Impact on dotforge
- Audit `template/settings.json.tmpl`, `global/settings.json.tmpl`, `stacks/*/settings.json.partial` for `Bash(find:*)` or `Bash(rm:*)` rules
- `.claude/rules/domain/permission-model.md` — add a "tightened auto-approvals" subsection summarizing v2.1.113 changes
- `template/hooks/block-destructive.sh` — verify it still catches what it claims; less critical now that the kernel-side check is stricter

## Decision
Pending
