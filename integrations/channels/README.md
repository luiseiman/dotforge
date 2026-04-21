# Channels — native push integration

> Claude Code v2.1.83+ official push-event integration. First-party alternative to the OpenClaw bridge for routing external messages (Telegram, Discord, iMessage, custom webhooks) into a live session.

## What it is

**Channels** are MCP servers distributed as plugins whose notifications Claude listens for. A Telegram channel, for example, forwards incoming messages to your session in real time — Claude can reply via the same channel. Pairing and access are managed by the plugin's own skill (e.g. `/telegram:access`).

- CLI flag: `--channels plugin:<name>@<marketplace>` (space-separated list)
- Enterprise allowlist: `allowedChannelPlugins` in managed settings
- Development channels not on the official allowlist: `--dangerously-load-development-channels` (prompts for confirmation)

## Why it matters for dotforge

We ship `integrations/openclaw/` as our cross-tool messaging bridge. Channels is the first-party equivalent and the right choice when:

- The target platform already has an official Channel plugin
- You need enterprise governance (allowlisted plugins, managed hook policy)
- You want push notifications routed by Anthropic's runtime rather than a self-hosted bridge

Use **OpenClaw** when you need custom routing, non-standard platforms, or on-prem message handling.

## Permission model touchpoints

- `allowedChannelPlugins` (managed settings): team/enterprise allowlist — restricts which plugins activate via `--channels`. Documented in `.claude/rules/domain/permission-model.md` "Enterprise managed settings" section.
- Channel plugins are regular Claude Code plugins — same `hooks/`, `skills/`, `commands/` discovery rules apply.
- Sensitive actions (pair device, approve allowlist) MUST go through the plugin's user-facing skill, never the LLM directly. See the Telegram plugin's own security notes for the pattern.

## When to pick which

| Need | Use |
|------|-----|
| Official Telegram / Discord / iMessage push | Channels (first-party plugin) |
| Custom webhook → Claude | Channels (custom MCP channel plugin) or OpenClaw |
| Cross-platform messaging unified through one bridge | OpenClaw |
| Enterprise allowlisted messaging | Channels + `allowedChannelPlugins` |
| Air-gapped / on-prem-only messaging | OpenClaw (self-hosted) |

## References

- Official docs: https://code.claude.com/docs/en/channels
- Telegram plugin reference: `plugin:telegram`
- OpenClaw bridge: `integrations/openclaw/`
