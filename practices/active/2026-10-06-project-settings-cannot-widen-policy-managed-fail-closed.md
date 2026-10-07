---
id: practice-2026-10-06-project-settings-cannot-widen-policy-managed-fail-closed
title: Project/local settings can no longer widen policy; managed settings fail closed; new managed keys (v2.1.252–v2.1.290)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [settings, managed-settings, sandbox, permissions, security, sync]
tested_in: []
incorporated_in: [".claude/rules/domain/permission-managed-settings.md", ".claude/rules/domain/sandboxing.md", ".claude/rules/domain/auth.md", "skills/sync-template/SKILL.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
Project/local scope restrictions:
- `sandbox.excludedCommands` ignored when managed/`--settings` set `allowUnsandboxedCommands:false` or `allowManagedDomainsOnly:true`; project cannot widen or disable an admin-required sandbox (v2.1.282/285/290). `excludedCommands` glob must match every part of a compound command (v2.1.277).
- Project `env` no longer sets `CLAUDE_CONFIG_DIR`, `CLAUDE_CODE_TMPDIR`, `TMPDIR/TMP/TEMP` (v2.1.252), `CLAUDE_CODE_ENABLE_TELEMETRY`, `OTEL_LOG_*`, `CLAUDE_CODE_DISABLE_ATTACHMENTS`, Chrome enable.
- `ANTHROPIC_CUSTOM_HEADERS` setting credential/tenant/routing headers needs approval (v2.1.252). Remote Control auto-start cannot be enabled by repo-local settings (v2.1.222).
- `sandbox.ripgrep`, `bwrapPath`/`socatPath`, `credentials.*` honored only from user/managed/`--settings`.
Managed fail-closed (v2.1.259–285): unparseable managed source → refuse to start; invalid nested value in `sandbox|permissions|autoMode|worktree|attribution` fails closed, rest applies; unreadable `allowedHttpHookUrls`/`httpHookAllowedEnvVars`/`allowedChannelPlugins` admit nothing; OS-denied managed file → warn and start without it (v2.1.285); `managedSourcesBehavior:"merge"` takes `awsPairs`/`ripgrep` whole; managed `claudeMd` no longer triggers approval (v2.1.260); server-delivered settings merge env per key with local managed file (v2.1.229).
New managed keys: `allowedProviders`, `deniedModels`, `availableModelsMatch:"exact"`, `managedMcpServers`, `allowClaudeInChromeWithManagedMcp`, `gatewayInternalNetworks`, `modelPricing`, `forceLoginMethod:"gateway"` + `forceLoginGatewayUrl`, `policyHelper.timeoutMs`, `strictPluginOnlyCustomization`, managed `skillOverrides` keyed on bundled alias, `maxEffortLevel` (lowest cap wins, v2.1.267), `enableArtifact`/`disableArtifact` (false from any scope wins), `modelPicker` (whole-value, user/managed only).

## Evidence
`template/settings.json.tmpl` env is only `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS` + `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` → no breakage today. `permission-managed-settings.md` names none of the new keys; `auth.md:65` documents `forceLoginMethod` as `claudeai|console` only.

## Impact on dotforge
- `.claude/rules/domain/permission-managed-settings.md`: scope-restriction section + fail-closed section + key list
- `.claude/rules/domain/sandboxing.md`: which keys are user/managed-only
- `.claude/rules/domain/auth.md`: `forceLoginMethod: gateway`
- `skills/sync-template/SKILL.md`: `/forge sync` must never write `defaultMode: auto|bypassPermissions`, `sandbox.credentials`, `sandbox.ripgrep`, telemetry env into project scope — they are silently ignored

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.5.0 (/forge update, security block).
