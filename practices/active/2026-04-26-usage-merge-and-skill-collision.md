---
id: practice-2026-04-26-usage-merge-and-skill-collision
title: /cost+/stats merged into /usage; built-in /less-permission-prompts collides with dotforge skill
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [slash-commands, skills, naming, upstream, breaking-docs]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
Two related upstream slash-command changes that affect dotforge documentation and skills:

1. **`/cost` and `/stats` were merged into `/usage`** in v2.1.118. Both names remain as typing shortcuts that open the relevant tab inside `/usage`.
2. **Built-in `/less-permission-prompts` skill** shipped in v2.1.111 — scans transcripts for common read-only Bash and MCP calls and proposes an allowlist for `.claude/settings.json`. dotforge already ships `skills/fewer-permission-prompts/` with the same purpose. Slash command priority (per `domain/agent-orchestration.md`) means the dotforge skill can shadow the built-in or vice versa depending on install path.

## Evidence
CHANGELOG v2.1.118: "Merged `/cost` and `/stats` into `/usage` — both remain as typing shortcuts that open the relevant tab".
CHANGELOG v2.1.111: "Added `/less-permission-prompts` skill — scans transcripts for common read-only Bash and MCP tool calls and proposes a prioritized allowlist for `.claude/settings.json`".

`docs/claude-vs-forge.md` lines 116–120 / 293–297 still list `/cost` and `/stats` as separate commands.

## Impact on dotforge
- `docs/claude-vs-forge.md` — collapse `/cost`/`/stats` rows into `/usage`
- `skills/fewer-permission-prompts/SKILL.md` — decide: deprecate, rename to avoid shadow, or keep with explicit positioning vs. built-in (different output? broader surface?)
- `.claude/rules/domain/agent-orchestration.md` — possibly add a note that newer Claude Code versions ship competing built-ins

## Decision
Pending
