---
globs: "**/managed-settings.json,**/managed-settings.d/*.json,**/.mcp.json,**/settings.json"
description: "Enterprise managed settings, MCP server governance, dynamic hook-mutated permissions"
domain: claude-code-engineering
last_verified: 2026-05-05
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

## MCP server config

- `enableAllProjectMcpServers` — auto-approve every project MCP server. Use sparingly
- `enabledMcpjsonServers` / `disabledMcpjsonServers` — per-server allow/deny
- `allowedMcpServers` / `deniedMcpServers` — managed-scope versions
- `allowManagedMcpServersOnly` — managed-only MCP source
- `alwaysLoad: true` (per-server, v2.1.121+) — tools skip tool-search deferral and stay always available. Costs context for fewer tool-search invocations. Use only when MCP tools are needed every turn
- `workspace` reserved as MCP server name since v2.1.128 — projects with that name skipped with warning
- MCP tools default to `passthrough` (always ask)

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
