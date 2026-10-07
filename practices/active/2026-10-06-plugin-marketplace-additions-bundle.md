---
id: practice-2026-10-06-plugin-marketplace-additions-bundle
title: Plugin/marketplace additions — marketplace aliases, owner wildcards, archive/command sources, headersHelper, synced plugins (v2.1.221–v2.1.285)
source: "/forge watch — CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [plugins, marketplace, managed-settings, distribution]
tested_in: []
incorporated_in: [".claude/rules/domain/plugin-distribution.md", ".claude/rules/domain/agent-orchestration.md"]
replaced_by: null
effectiveness: informational
error_type: null
---

## Description
- Managed aliases: `additionalMarketplaces` ≡ `extraKnownMarketplaces`, `allowedMarketplaces` ≡ `strictKnownMarketplaces` (v2.1.232). Owner wildcards `"owner/*"` in `strictKnownMarketplaces` / `blockedMarketplaces` (v2.1.238). Malformed entries fail closed (v2.1.277). GitLab marketplace sources + bare `gitlab.com` URLs (v2.1.233).
- Sources: `archive` (zip over HTTPS, optional SHA-256 pin) and `command` (v2.1.229); `headersHelper` on url marketplace/catalog entry, runs only after confirm on install/update (v2.1.224); npm sources fetched with `npm pack --ignore-scripts` (v2.1.275); `--accept-command <sha256>` (v2.1.271); `claude plugin configure`, `install --config` (v2.1.285); `--plugin-dir` accepts a folder of plugins (v2.1.265).
- `plugin@synced` plugins from claude.ai (v2.1.239); skills synced from claude.ai hardened — no `!` commands or `@` expansion (v2.1.228). Plugins accept `"."` as `skills` path (v2.1.221); `claude plugin validate` checks bare `.claude/skills` dir (v2.1.233), `--json`, MCP checks, `gatingHooks`.
- Plugins loaded via `allowed-tools` no longer pre-approve their own tools under `allowManagedPermissionRulesOnly` unless source is official or vouched by managed settings (v2.1.282/284). Plugin names `claude-ai`/`anthropic-skills` reserved in v2.1.282 then reverted v2.1.283. Plugin subagents ignore `hooks`, `mcpServers`, `permissionMode`.
- Skills: `disable-model-invocation` now refuses model invocation with "ask the user to run it" (v2.1.222); argument substitution no longer re-expands values (v2.1.233). `disableBundledSkills` + `skillOverrides` managed by alias.

## Evidence
`plugin-distribution.md` covers marketplace governance up to `pluginSuggestionMarketplaces` (v2.1.152) and plugin-from-`.claude/skills/` (v2.1.157). 0 hits for `additionalMarketplaces`, `headersHelper`, `archive` source, `plugin@synced`.

## Impact on dotforge
- `.claude/rules/domain/plugin-distribution.md`: sources, aliases, wildcards, validate flags, synced plugins
- `.claude/rules/domain/permission-managed-settings.md`: `allowManagedPermissionRulesOnly` + plugin `allowed-tools` interaction
- `skills/plugin-generator/SKILL.md`: emit `defaultEnabled`, run `claude plugin validate --json` as final step, document that plugin subagents cannot carry `hooks`/`mcpServers`/`permissionMode`
- `.claude/rules/domain/agent-orchestration.md` § model self-invocation: `disable-model-invocation` now hard-enforced

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.6.0 (/forge update, catalogue block).
