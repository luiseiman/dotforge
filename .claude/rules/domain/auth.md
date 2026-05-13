---
globs: "**/settings.json,**/CLAUDE.md,**/.env*,**/scripts/**/*.sh,**/.github/workflows/*.yml"
description: "Auth model — API key vs Claude.ai vs OAuth vs setup-token; precedence rules"
domain: claude-code-engineering
last_verified: 2026-05-13
---

# Auth Model

## Auth sources (in priority order)

1. **`ANTHROPIC_API_KEY`** / `apiKeyHelper` / `ANTHROPIC_AUTH_TOKEN` env — direct API key
2. **`CLAUDE_CODE_OAUTH_TOKEN`** env — long-lived OAuth token from `claude setup-token` (CI canonical path)
3. **Claude.ai login** — persistent OAuth, stored in `~/.claude/.credentials.json`
4. **Anthropic Console login** — `claude auth login --console`, billing via Console

When multiple are present, Claude Code chooses by source (1 > 2 > 3 > 4). The first one found is used; others are ignored for *requests*, but their **presence still affects feature gating** (see below).

## API key presence disables feature set (v2.1.139+)

Setting any of `ANTHROPIC_API_KEY`, `apiKeyHelper`, or `ANTHROPIC_AUTH_TOKEN` disables these features **even when a Claude.ai login also exists**:

- Remote Control (`--remote-control`, `--rc`, `claude remote-control`)
- `/schedule` (Routines on Anthropic-managed infrastructure)
- claude.ai MCP connectors
- Notification preferences (push, mobile)

Rationale: prevents auth ambiguity when two credential sources are present. Choose one path:

- **API key path**: headless, `-p`, SDK, CI without Claude.ai dependency. Lose Remote Control + Routines + cloud connectors.
- **Claude.ai login path**: full feature surface. Unset the API key env vars.

In CI specifically, prefer `claude setup-token` over `ANTHROPIC_API_KEY` if you need Routines or `/schedule` for scheduled CI workflows.

## CI authentication canonical path

```bash
# One-time, locally:
claude setup-token              # prints token; copy to CI secrets as CLAUDE_CODE_OAUTH_TOKEN

# In CI:
export CLAUDE_CODE_OAUTH_TOKEN="$CI_SECRET"
claude -p "review my diff"      # uses the OAuth token, no API key needed
```

Requires a Claude subscription. Tokens are long-lived but rotate periodically — store the rotation procedure in your CI runbook.

## Anti-patterns

- Setting `ANTHROPIC_API_KEY` in `~/.bashrc` "in case Claude needs it" — silently disables Remote Control for every interactive session
- CI scripts that fall back to a billing-API key when the OAuth token is missing — they bypass the user's subscription quota
- Sharing one OAuth token across CI and a human's dev machine — token revocation kills both
- Committing `apiKeyHelper` script paths that resolve to a developer's home directory — breaks on other machines and in CI

## Cross-references

- `permission-model.md` — settings cascade (Managed > Local > Project > User)
- `cli-flags.md` — `claude auth (login|logout|status)`, `claude setup-token`, `--remote-control`
- `sandboxing.md` — `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` strips creds from subprocess env
