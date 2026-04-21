---
id: channels-native-push-integration
source: watch:code.claude.com/docs/en/channels
status: active
captured: 2026-04-21
tags: [integrations, channels, medium-priority, v2.1.83]
tested_in: []
incorporated_in: ['3.3.0']
---

# Channels — native push-event integration (Telegram/Discord/iMessage/webhooks)

## Observation

v2.1.83 introduced **Channels**: MCP servers that push events from Telegram, Discord, iMessage, or custom webhooks into a Claude Code session. CLI: `--channels plugin:<name>@<marketplace>`. Enterprise allowlist: `allowedChannelPlugins`.

`--dangerously-load-development-channels` accepts local development channels not on the official allowlist.

## Why it matters for dotforge

We ship the OpenClaw integration (`integrations/openclaw/`) as a cross-tool bridge for messaging. Channels is the first-party equivalent — worth documenting as an alternative with clearer enterprise governance (managed allowlist).

## Required update

1. `integrations/` — add `channels/README.md` or a note in existing integrations docs pointing to Channels as the native route.
2. `domain/permission-model.md` already documents `allowedChannelPlugins` briefly — could reference Channels as the consumer.
3. Possibly a new capture-practice for using Channels with a specific project (e.g., trading alerts).

## Affected files

- `integrations/` (new doc or update)
- `.claude/rules/domain/permission-model.md` (cross-reference)
