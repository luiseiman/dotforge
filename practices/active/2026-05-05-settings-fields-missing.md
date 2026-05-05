---
id: settings-fields-missing
source: watch:code.claude.com/docs/en/settings
status: active
captured: 2026-05-05
tags: [settings, drift, enterprise, medium-priority]
tested_in: []
incorporated_in: ['3.6.0']
---

# settings.json fields missing from domain rules

## Observation

A walk through the official settings.json schema surfaces fields not documented anywhere in `.claude/rules/domain/`:

**Generally relevant**:
- `availableModels` — restrict selectable models (subset of all)
- `effortLevel` — persist effort across sessions (vs session-only `--effort` flag)
- `defaultShell` — bash | powershell at the settings level (cross-platform)
- `viewMode` — default | verbose | focus (transcript view)
- `pluginTrustMessage` — custom warning shown on plugin trust prompts
- `enableWeakerNestedSandbox` — Docker-friendly relaxed sandbox

**Managed-only (enterprise)**:
- `allowManagedPermissionRulesOnly` — locks projects to managed permission rules
- `network.allowManagedDomainsOnly` — managed-domain-only outbound
- `filesystem.allowManagedReadPathsOnly` — managed-read-only filesystem
- `strictKnownMarketplaces` — managed marketplace allowlist (exact match, supports github/git/url/npm/file/directory/hostPattern)
- `blockedMarketplaces` — managed denylist

## Why it matters

- `availableModels` / `effortLevel`: relevant for any team standardizing on a model/effort baseline (e.g., "this project uses Sonnet at high, no Opus").
- Managed-only fields: critical for any enterprise that wants to deploy dotforge across an org with controlled marketplace and permission policy. Currently `domain/permission-model.md` covers `allowedMcpServers`/`deniedMcpServers` but stops there.

## Required update

1. `domain/rule-effectiveness.md` or new `domain/settings-fields.md` — document the generally-relevant fields with one-line each.
2. `domain/permission-model.md` Enterprise managed settings section — add the five managed-only fields with use case.

## Affected files

- `.claude/rules/domain/rule-effectiveness.md` (or new file)
- `.claude/rules/domain/permission-model.md`
