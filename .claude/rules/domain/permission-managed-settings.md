---
globs: "**/managed-settings.json,**/managed-settings.d/*.json,**/.mcp.json,**/settings.json"
description: "Enterprise managed settings, MCP server governance, dynamic hook-mutated permissions"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Permission Model — Enterprise & MCP

Companion to `permission-model.md`. Covers managed-scope governance, MCP server config, and dynamic permission mutation by hooks.

## Enterprise managed settings (v2.1.83+)

- `managed-settings.d/` drop-in directory: every `*.json` inside merges with `managed-settings.json` — modular policy files
- `allowManagedHooksOnly: true` — blocks ALL user/project/plugin hooks. Only managed-scope hooks (and hooks from plugins force-enabled by managed settings) run. Under this policy `.claude/hooks/` is inert at runtime — audit scoring should reflect runtime applicability, not file presence
- `allowedChannelPlugins` — restricts which plugins activate via `--channels`
- `forceRemoteSettingsRefresh` — fail-closed: blocks startup until remote settings fetched (v2.1.92)
- `allowManagedPermissionRulesOnly` — locks projects to managed-scope permission rules; user/project/local rules ignored
- `network.allowManagedDomainsOnly` — managed `allowedDomains` is the only outbound-truth source
- `filesystem.allowManagedReadPathsOnly` — managed read paths are the only source
- `strictKnownMarketplaces` — managed allowlist of plugin marketplace sources (exact match; `github`, `git`, `url`, `npm`, `file`, `directory`, `hostPattern`)
- `blockedMarketplaces` — managed denylist; takes precedence over `extraKnownMarketplaces`
- `pluginTrustMessage` — custom warning shown on plugin trust prompts
- `forceLoginOrgUUID` / `forceLoginMethod` — restrict login to org UUIDs or to `claudeai`/`console`. **v2.1.147 fix**: now enforced against third-party-provider (Bedrock/Vertex/Foundry/Mantle) AND API-key sessions; before v2.1.147 those bypassed both restrictions silently. Re-verify enterprise audits done on older Claude Code builds. See `auth.md`
- `claudeMd` (managed) — embed org-wide CLAUDE.md content directly in `managed-settings.json` as a string instead of deploying a separate file at `/Library/Application Support/ClaudeCode/CLAUDE.md` (or Linux/Windows equivalents). Example: `"claudeMd": "Always run \`make lint\` before committing.\\nNever push directly to main."`. Honored only in managed/policy scope — setting it in user/project/local has no effect. Same precedence as a managed CLAUDE.md file
- `requiredMinimumVersion` / `requiredMaximumVersion` (v2.1.187+) — version-gating for managed deployments. Block session startup when Claude Code version falls outside the declared range. Use for enterprise rollouts pinned to validated versions, or to block known-bad builds. Format: semver-compatible string (e.g. `"2.1.187"`). Fail-closed: out-of-range startup is rejected with a clear error
- Keys added v2.1.257–v2.1.285: `allowedProviders`, `deniedModels`, `availableModelsMatch: "exact"`, `managedMcpServers`, `allowClaudeInChromeWithManagedMcp`, `gatewayInternalNetworks`, `modelPricing` (multiplier ≤10x), `forceLoginMethod: "gateway"` + `forceLoginGatewayUrl` (v2.1.266/261), `policyHelper.timeoutMs` (clamped), `strictPluginOnlyCustomization` (lock customization to plugins only), managed `skillOverrides` keyed on bundled-skill alias (v2.1.260), `maxEffortLevel` (lowest cap from any scope wins, v2.1.267), `modelPicker` (whole-value, highest of managed/`--settings`/user, v2.1.242), `enableArtifact`/`disableArtifact` (`false` from any scope wins, v2.1.242)
- `allowManagedPermissionRulesOnly` + plugins (v2.1.282/284): plugins loaded via `allowed-tools` no longer pre-approve their own tools unless the source is official or vouched for by managed settings

## Project/local scope cannot widen policy (v2.1.252–v2.1.290)

Keys silently ignored when set in `.claude/settings.json` or `settings.local.json` — only user, managed, or `--settings` take effect:
- `permissions.defaultMode: auto|bypassPermissions` (v2.1.257)
- `sandbox.excludedCommands` when managed/`--settings` set `allowUnsandboxedCommands:false` or `allowManagedDomainsOnly:true`; project cannot widen or disable an admin-required sandbox (v2.1.282/285/290). An `excludedCommands` glob must match every part of a compound command (v2.1.277)
- `sandbox.credentials.*`, `sandbox.ripgrep`, `bwrapPath`/`socatPath` (user/managed/`--settings` only)
- `env`: `CLAUDE_CONFIG_DIR`, `CLAUDE_CODE_TMPDIR`, `TMPDIR`/`TMP`/`TEMP` (v2.1.252), `CLAUDE_CODE_ENABLE_TELEMETRY`, `OTEL_LOG_*`, `CLAUDE_CODE_DISABLE_ATTACHMENTS`, Chrome enablement
- Remote Control auto-start (repo-local settings may still turn it off, v2.1.222); `modelPicker`; `instructionFiles` (AGENTS.md policy)
- `ANTHROPIC_CUSTOM_HEADERS` setting credential/tenant/routing headers needs approval from managed or project scope (v2.1.252)

`/forge sync` must never write these into project scope — they are inert there and mislead audits.

## Fail-closed semantics (v2.1.259–v2.1.285)

- Unparseable managed source → Claude Code refuses to start
- Invalid nested value inside `sandbox`, `permissions`, `autoMode`, `worktree`, `attribution` → that value fails closed, the rest of the block still applies (v2.1.267)
- Unreadable `allowedHttpHookUrls`, `httpHookAllowedEnvVars`, `allowedChannelPlugins` → admit nothing
- Mistyped boolean lock key still applies; malformed `strictKnownMarketplaces` / `blockedMarketplaces` entries fail closed (v2.1.277)
- OS denies reading the managed file → warn and start without it (v2.1.285)
- `managedSourcesBehavior: "merge"` takes `sandbox.credentials.awsPairs` and `sandbox.ripgrep` whole, never element-wise (v2.1.257); server-delivered settings merge the `env` block per key with a local `managed-settings.json` (v2.1.229)
- Managed `claudeMd` no longer triggers the approval dialog (v2.1.260); approval does not re-appear on re-login when settings are unchanged (v2.1.234); `/status` shows a "Skipped sources" line (v2.1.243)

## MCP server config

- `enableAllProjectMcpServers` — auto-approve every project MCP server. Use sparingly
- `enabledMcpjsonServers` / `disabledMcpjsonServers` — per-server allow/deny
- `allowedMcpServers` — **since v2.1.259 governs only servers users add**; servers declared in `managed-mcp.json` load regardless. A managed server your allowlist used to filter out loads on upgrade — use `deniedMcpServers` to keep it off
- `deniedMcpServers` — managed denylist; the only reliable way to exclude a `managed-mcp.json` entry. v2.1.273 fix: `allowManagedMcpServersOnly`, `deniedMcpServers`, `disableClaudeAiConnectors` were ignored when server-managed settings were also present
- `managedMcpServers` (v2.1.283) — managed MCP server definitions inside settings. Unreadable `managed-mcp.json` keeps exclusive MCP control and warns — fail-closed (v2.1.271)
- `allowManagedMcpServersOnly` — managed-only MCP source
- `allowAllClaudeAiMcps` (v2.1.149+) — when true, loads ALL claude.ai cloud MCP connectors alongside `managed-mcp.json` entries. Use when the security team curates internal MCP servers but wants ad-hoc claude.ai-managed connectors (Linear, Slack, Notion) without enumerating each
- `alwaysLoad: true` (per-server, v2.1.121+) — tools skip tool-search deferral and stay always available. Costs context for fewer tool-search invocations. Use only when MCP tools are needed every turn
- `alwaysLoad: false` (v2.1.285) defers all of a server's tools behind tool search; per-tool `_meta['anthropic/alwaysLoad']=false` keeps one deferred. `"type":"sdk"` entries skipped (v2.1.274)
- Reserved MCP server names: `workspace` (v2.1.128), `widgets` in cloud sessions and self-hosted runners (v2.1.287) — skipped with warning
- MCP tools default to `passthrough` (always ask)
- Bedrock/Vertex/Foundry/telemetry-off installs use the v2 MCP client and 2026-07-28 protocol negotiation by default (v2.1.288); a server that stops connecting in URL-mode elicitation needs `"bareElicitationCapability": true` in its entry (v2.1.287)
- **`claude mcp list/get/add` secrets handling (v2.1.161 fix)**: pre-fix the CLI subcommands printed `${VAR}`-expanded values verbatim, leaking subprocess env into stdout (incident potential when piping `claude mcp list` to a log file or screenshare). Post-fix `${VAR}` is no longer expanded in CLI output — safer to dump configs for review. Audit any pre-v2.1.161 ops runbooks that included `claude mcp list` output.

## Dynamic permissions from hooks (v2.1.84+)

`PreToolUse` and `PermissionRequest` hooks can mutate runtime permission state via JSON output:

```json
{
  "hookSpecificOutput": {
    "decision": {
      "behavior": "allow|deny",
      "updatedInput": { "...": "..." },
      "updatedPermissions": [
        { "type": "addRules",          "rules": ["Bash(make *)"] },
        { "type": "replaceRules",      "rules": ["..."] },
        { "type": "removeRules",       "rules": ["..."] },
        { "type": "setMode",           "mode": "auto|default|plan|acceptEdits" },
        { "type": "addDirectories",    "directories": ["/tmp/build"] },
        { "type": "removeDirectories", "directories": ["..."] }
      ]
    }
  }
}
```

Use cases: a behavior self-elevates its allowlist for a session, a safety hook downgrades to `plan` mode after detecting risk, a build hook whitelists a temp directory. Static deny rules still enforce — a hook cannot remove a managed deny.

**Security note on `updatedInput` (v2.1.110+, widened v2.1.290)**: when a hook returns `updatedInput` to mutate a tool call, the modified input is re-checked against `permissions.deny` (v2.1.110) and, since v2.1.290, against every permission rule and built-in safety check. A hook cannot use `updatedInput` to smuggle an otherwise-denied payload past static rules. PreToolUse auto-allow hooks no longer bypass tool restrictions in background agent tasks (v2.1.222).
