---
id: practice-2026-04-06-force-remote-settings-refresh
title: "forceRemoteSettingsRefresh — fail-closed policy for managed CLIs"
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-04-06
status: inbox
tags: [settings, enterprise, policy, security]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Descripción
v2.1.92 added `forceRemoteSettingsRefresh` policy setting. When enabled, Claude Code refuses to start if it cannot fetch the remote settings (fail-closed). Intended for enterprise/managed deployments where centralized policy enforcement is required.

## Evidencia
Official changelog v2.1.92 (April 4, 2026): "Added `forceRemoteSettingsRefresh` policy setting for fail-closed remote settings fetching."

## Impacto en claude-kit
- Relevant only for team/enterprise dotforge profiles
- `stacks/` or a future `profiles/enterprise.json` could include this flag
- Low priority for individual developer setups

## Decisión
Pendiente
