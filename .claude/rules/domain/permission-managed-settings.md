---
globs: "**/managed-settings.json,**/managed-settings.d/*.json,**/.mcp.json,**/settings.json"
description: "Enterprise managed settings, MCP server governance, dynamic hook-mutated permissions"
domain: claude-code-engineering
last_verified: 2026-10-06
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

**Security note on `updatedInput` (v2.1.110+)**: when a hook returns `updatedInput` to mutate a tool call, the modified input is re-checked against `permissions.deny` before execution. A hook cannot use `updatedInput` to smuggle an otherwise-denied payload past static deny rules. Before v2.1.110 the recheck was missing.
