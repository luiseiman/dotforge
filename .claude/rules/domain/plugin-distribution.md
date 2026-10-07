---
globs: "**/.claude-plugin/**,**/plugin.json,**/install.sh,**/.mcp.json"
description: "Plugin distribution: persistent state, seed dirs, marketplace policy, reserved names"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Plugin Distribution

## Persistent state — `${CLAUDE_PLUGIN_DATA}` (v2.1.126+)

- Plugin-scoped directory for state that must survive plugin updates/reinstalls
- Available in hooks, skills, commands as the env var `${CLAUDE_PLUGIN_DATA}`
- Use for: accumulated metrics, last-processed IDs, capture inboxes, manifests of managed projects
- NEVER store secrets here — sandbox env-scrub does NOT cover plugin data dirs
- Distinct from `${CLAUDE_PLUGIN_ROOT}` (read-only plugin install dir)

For dotforge specifically: candidates to migrate are `practices/metrics.yml` (counters), `.forge/manifest.json` (registry), and post-session captures that currently land in `practices/inbox/` (which dirties git status). Migration is a multi-commit project — pilot one (e.g. `inbox/`) before others.

## Multi-seed distribution — `CLAUDE_CODE_PLUGIN_SEED_DIR`

- Accepts multiple directories separated by platform delimiter (`:` Unix, `;` Windows)
- Layered overlay pattern: `seed1` (base) `:` `seed2` (corporate) `:` `seed3` (personal)
- Use for: enterprise overlays on top of public template, personal preferences on top of team config
- Later seeds override earlier ones for files with the same path

## Marketplace governance (managed settings)

- `strictKnownMarketplaces` — allowlist of marketplace sources (github/git/url/npm/file/directory/hostPattern). `allowedMarketplaces` is an alias (v2.1.232); owner wildcards `"owner/*"` accepted (v2.1.238); malformed entries fail closed (v2.1.277); GitLab sources and bare `gitlab.com` URLs supported (v2.1.233)
- `blockedMarketplaces` — denylist; same aliases/wildcards. `additionalMarketplaces` ≡ `extraKnownMarketplaces`
- Plugins loaded via `allowed-tools` no longer pre-approve their own tools under `allowManagedPermissionRulesOnly` unless the source is official or vouched for by managed settings (v2.1.282/284)
- `allowedChannelPlugins` — restricts which plugins can listen on `--channels`
- `allowManagedPermissionRulesOnly` — locks projects to managed-only permission rules
- `pluginTrustMessage` — custom warning shown on plugin trust prompts
- `pluginSuggestionMarketplaces` (v2.1.152+) — admins allowlist org marketplaces whose plugins may be suggested via the harness's context-aware tip prompts. Without it, all configured marketplaces are eligible to surface suggestions

## Plugin sources (v2.1.221–v2.1.285)

- `archive` source: zip over HTTPS with optional SHA-256 pin; `command` source (v2.1.229) — both for self-hosted distribution without a git marketplace
- `headersHelper` on a url marketplace/catalog entry runs only after you confirm on install or update (v2.1.224); helpers from project/plugin files run without inherited credential env vars (v2.1.248). npm sources are fetched with `npm pack --ignore-scripts` (v2.1.275). `--accept-command <sha256>` pins a command source (v2.1.271)
- `plugin@synced` plugins come from claude.ai (v2.1.239); skills synced from claude.ai are hardened — no `!` shell commands or `@` expansion (v2.1.228)
- Plugins accept `"."` as a `skills` path (v2.1.221). Plugin subagents ignore `hooks`, `mcpServers`, `permissionMode` in their frontmatter — those capabilities are not distributable via plugin
- `claude plugin configure <name>` / `install --config` (v2.1.285) set plugin options; `claude plugin validate --json` checks a bare `.claude/skills` dir (v2.1.233), MCP entries, `gatingHooks`, unquoted `${CLAUDE_PLUGIN_ROOT}` (v2.1.281)
- `claude plugin eval` (v2.1.263–269): runs a plugin against a test-case suite, scores results, compares to a no-plugin baseline (`eval init` drafts cases + graders; JSON/HTML report; needs git ≥2.31). Native equivalent of dotforge's `benchmark` skill — see `native-vs-dotforge-boundary.md`

## Claude Mods (v2.1.287+)

Plugins may ship **hooks modules** that hot-reload in-session and intercept `tool.check`, `turn.step`, `ui.render`, `prompt.submit`, `agent.spawn` — deeper than settings-level hooks (which only see tool calls through stdin/stdout). Built-in `plugin-authoring` skill documents the API; built-in `you-should-know` mod monitors sessions. Org-managed guards win over user-installed mods (v2.1.290). A native `tool.check` module overlaps dotforge's v3 compiled `PreToolUse` behaviors — decision pending in `native-vs-dotforge-boundary.md`.

## Reserved names

- `workspace` — reserved as MCP server name since v2.1.128; `widgets` reserved in cloud sessions and self-hosted runners (v2.1.287). Plugins/projects using these names skipped with warning at startup. Audit `.mcp.json` and `mcp/` configs in dotforge stacks before declaring server names. Plugin names `claude-ai` / `anthropic-skills` were reserved in v2.1.282 and un-reserved in v2.1.283 — avoid anyway

## Lifecycle hygiene

- `claude plugin prune` (v2.1.121+) — removes orphaned auto-installed dependencies
- `plugin uninstall --prune` — cascades dependency cleanup
- `--plugin-dir` accepts `.zip` archives (v2.1.128+) and a folder of plugins (v2.1.265+); `--plugin-url` fetches a zip for one session
- `/plugin list` (v2.1.163+) — list installed plugins from the running session without leaving the prompt. Pairs with `/plugin` (manage) and `claude plugin status` (CLI subcommand)
- `disableBundledSkills` setting / `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS=1` (v2.1.169+) — skip harness-shipped skills like `/deep-research` so a project-owned implementation takes over without name collision. Use when dotforge ships its own version of a Claude-bundled skill (e.g. project-customized research workflow)

## Plugin from `.claude/skills/` (v2.1.157+)

Plugins dropped in `.claude/skills/<name>/` **auto-load without marketplace registration**. Scaffold a new one with `claude plugin init <name>` (writes a minimal `plugin.json` + `SKILL.md` skeleton). Collapses the boundary between "skill" (project-local, no distribution) and "plugin" (distributable artifact) — even local-only experiments can be plugins now, because the marketplace metadata is no longer required to load them.

## Dormant by default — `defaultEnabled: false` (v2.1.154+)

Plugin manifests (and marketplace entries) can declare `"defaultEnabled": false`. When set, the plugin installs **dormant** — present on disk but inactive until the user explicitly runs `/plugin` or `claude plugin enable`. Dependencies of an explicitly-enabled plugin still auto-enable transitively. User settings persist across updates — flipping `defaultEnabled` later does not override a user's prior choice.

```json
{
  "name": "expensive-monitor",
  "defaultEnabled": false,
  "description": "Periodic poll of an external API — opt-in to control cost"
}
```

**When to use `defaultEnabled: false`:**

- Plugin has ambient cost (periodic hooks, large rule injections)
- Touches external services (MCP server connectors, cloud APIs)
- Opinionated behaviors the user may not want by default (strict verify modes, blocking governance)
- Production-tier policies that need explicit per-project opt-in

**When `defaultEnabled: true` (default behavior):**

- Core lifecycle skills users always need (init, audit, sync, capture)
- Read-only utilities with no ambient cost

dotforge `plugin-generator` skill should default new manifests to `defaultEnabled: true` for core lifecycle skills, `defaultEnabled: false` for opinionated or cost-bearing additions.

## When to plugin vs `.claude/`

| Need | Use |
|------|-----|
| One-project customization, quick experiment | `.claude/skills/<name>/` plugin scaffolded via `claude plugin init` — auto-loads, no marketplace |
| Shared with team, versioned, namespaced skills | Plugin via marketplace (github/git/url) |
| Enterprise governance (marketplace allowlist) | Plugin via managed settings + `pluginSuggestionMarketplaces` |
| State that must survive updates | Plugin + `${CLAUDE_PLUGIN_DATA}` |
