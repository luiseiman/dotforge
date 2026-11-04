---
id: practice-2026-11-04-protect-guardrail-config-behavior
title: Behavior `protect-guardrail-config`: soft_block edits to `.claude/settings*.json`, `.claude/hooks/**`, `hooks.json`, `.mcp.json`, plugin manifests, and `claude config|mcp|plugin` commands; ConfigChange hook as second layer
source: "/forge scout — top-starred Claude Code config repos (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [behaviors, security, config, hooks]
tested_in: []
incorporated_in: []
replaced_by: null
effectiveness: null
error_type: null
---

## Description
karanb192 `config-guard` blocks the agent from rewriting its own guardrails (settings, hooks, MCP config, plugin manifests) and the CLI commands that do the same — the vector of CVE-2026-25725. dotforge already ships `protect-lint-config` (v4.8.0) on the same engine: same shape, different file regex, plus `Bash` matcher for `claude config set|mcp add|plugin install`. A `ConfigChange` hook (blockable with exit 2 except `policy_settings`) can be the second layer that catches edits made outside the Edit/Write tools.

## Evidence
karanb192/claude-code-hooks `plugins/config-guard/README.md:5,46`, `plugins/config-watch/config-watch.js:13-24`. Hooks reference: ConfigChange matchers `user_settings|project_settings|local_settings|policy_settings|skills`, exit 2 blocks (verified 2026-11-04).

## Impact on dotforge
- New `behaviors/protect-guardrail-config/behavior.yaml` (opt-in until an arm eval per `docs/v3/EVAL-METHOD.md`), 3 scenarios, compiled hook
- `template/hooks/config-change-guard.sh` wired on `ConfigChange` with matcher `project_settings|local_settings`
- Production-tier projects (TRADINGBOT, cotiza, SOMA) are the first adopters

## Decision
Pending — captured from the 2026-11-04 scout (23 repos). Items 1–2 of the same scout shipped as v4.8.1, item 4 as v4.9.0; item 3 (expanded deny lists) was explicitly declined by the user.
