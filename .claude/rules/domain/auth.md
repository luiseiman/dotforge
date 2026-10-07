---
globs: "**/settings.json,**/CLAUDE.md,**/.env*,**/scripts/**/*.sh,**/.github/workflows/*.yml"
description: "Auth model — API key vs Claude.ai vs OAuth vs setup-token; precedence rules"
domain: claude-code-engineering
last_verified: 2026-10-07
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

## Federation env vars

- **`ANTHROPIC_WORKSPACE_ID`** (v2.1.141+) — scopes a token to a specific workspace when the user's federation rule covers more than one. Without it, the minted token falls into the federation rule's default workspace, which is indeterministic in multi-workspace enterprise tenants. Required when SAML/OIDC federation maps a single principal to >1 workspace

## Bedrock region resolution (v2.1.172+)

Amazon Bedrock now reads the AWS region from `~/.aws` config files (same precedence as the AWS CLI: env vars → `~/.aws/credentials` profile → `~/.aws/config` profile → `default`). Pre-v2.1.172 required setting `AWS_REGION` explicitly even when `~/.aws/config` already had it. Removes a common "works in CLI, not in Claude Code" config drift for Bedrock users — verify the active profile resolves to the intended region with `aws configure list` before debugging missing-model issues.

## Enterprise enforcement fix (v2.1.147)

The managed-settings `forceLoginOrgUUID` (restrict login to specific org UUIDs) and `forceLoginMethod` (`claudeai` | `console` | `gateway` — the gateway value, paired with `forceLoginGatewayUrl`, arrived in v2.1.261/266 for the self-hosted Claude apps gateway) were enforced **only against Claude.ai login sessions** before v2.1.147. **Third-party-provider** (Bedrock, Vertex, Foundry, Mantle) and **API-key** (`ANTHROPIC_API_KEY`) sessions bypassed both restrictions silently.

Post-fix: both managed-settings apply to all session types. Pre-v2.1.147 enterprise audits may have a false sense of coverage — re-verify on a current Claude Code build. Mantle was first mentioned in v2.1.161 changelog as one of the third-party providers; scope (cloud reseller vs new Anthropic-deployed surface) not yet documented in detail upstream.

## Cross-references

- `permission-model.md` — settings cascade (Managed > Local > Project > User)
- `permission-managed-settings.md` — `forceLoginOrgUUID`, `forceLoginMethod`, managed-mcp.json
- `cli-flags.md` — `claude auth (login|logout|status)`, `claude setup-token`, `--remote-control`
- `sandboxing.md` — `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` strips creds from subprocess env
