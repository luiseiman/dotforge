---
id: practice-2026-05-13-apikey-disables-remote-features
title: API key set disables Remote Control + /schedule + claude.ai MCP + notifications (v2.1.139)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [auth, security, breaking-behavior, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
When ANY of `ANTHROPIC_API_KEY`, `apiKeyHelper`, or `ANTHROPIC_AUTH_TOKEN` is set, the following features become DISABLED even when a Claude.ai login is also present:

- Remote Control (`--remote-control`, `--rc`, `claude remote-control`)
- `/schedule` (Routines on Anthropic-managed infrastructure)
- claude.ai MCP connectors
- Notification preferences

The user must unset the API key to use any of these features. Change is intentional: prevents auth confusion when two credential sources are present.

## Evidence
CHANGELOG v2.1.139: "Remote Control, `/schedule`, claude.ai MCP connectors, and notification preferences are now disabled when `ANTHROPIC_API_KEY` / `apiKeyHelper` / `ANTHROPIC_AUTH_TOKEN` is set, even if a Claude.ai login also exists. Unset the API key to use these features".

Affects CI/headless setups that have an API key in env for `claude -p` workflows but also a Claude.ai cookie in the same machine. Silent feature loss without explicit warning.

## Impact on dotforge
- `.claude/rules/domain/cli-flags.md` — document the precedence as a sidebar
- `.claude/rules/domain/auth.md` — does not exist yet; candidate to create with auth model documentation (API key vs Claude.ai vs OAuth vs setup-token; precedence rules)
- `docs/best-practices.md` — CI section should warn about this if dotforge ships CI guidance
- `audit/checklist.md` — possible "auth coherence" item: project documents which auth source it expects

## Decision
Pending
