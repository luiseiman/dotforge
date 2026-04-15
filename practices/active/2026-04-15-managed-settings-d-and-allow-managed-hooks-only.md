---
id: managed-settings-d-and-allow-managed-hooks-only
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-04-15
tags: [permissions, settings, enterprise, domain-knowledge, new-feature]
tested_in: []
incorporated_in: [v3.1.0]
---

# managed-settings.d/ drop-in + allowManagedHooksOnly policy

## Observation

Two enterprise-oriented features added in v2.1.83 and v2.1.84, never covered in
dotforge:

### 1. `managed-settings.d/` drop-in directory (v2.1.83)

In addition to the single `managed-settings.json`, Claude Code now reads any
`*.json` files inside `managed-settings.d/` and merges them. Lets ops teams
ship multiple modular policy files (one per topic) instead of one giant file.

### 2. `allowManagedHooksOnly` (v2.1.84)

A managed-settings flag that **blocks all user/project/plugin hooks** — only
hooks declared in managed settings (or in plugins force-enabled by managed
settings) are allowed to run. Hardens enterprise rollouts where users should
not be able to inject arbitrary scripts into their PreToolUse pipeline.

### 3. `allowedChannelPlugins` (v2.1.84)

Restricts which plugins can be activated via `--channels`. Complementary
control to limit attack surface.

### 4. `forceRemoteSettingsRefresh` (v2.1.92)

Already partially noted in `auto-mode.md` — but it deserves cross-reference
from `permission-model.md` and the audit checklist (item #2).

## Why it matters for dotforge

dotforge's `permission-model.md` documents the static cascade
(Managed > Local > Project > Global) but does not mention:
- the `.d/` drop-in pattern
- enterprise hook lockdown
- channel plugin restriction

This matters for projects that get audited by an org with managed settings —
they need to know the hooks they ship in `.claude/` may be ignored, and that
their score should reflect this.

## Action

1. Add a "Enterprise managed settings" section to `domain/permission-model.md`
2. Update audit checklist item #4 (block-destructive hook): note that under
   `allowManagedHooksOnly` the project hook is inert, and the score should
   reflect runtime applicability, not just file presence
3. Document `managed-settings.d/` in the same section

## Affected files
- `.claude/rules/domain/permission-model.md`
- `audit/checklist.md` (item #4 caveat)
- Possibly `audit/scoring.md`
