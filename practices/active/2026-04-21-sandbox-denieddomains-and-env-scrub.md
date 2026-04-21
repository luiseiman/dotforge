---
id: sandbox-denieddomains-and-env-scrub
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-04-21
tags: [security, sandbox, medium-priority, v2.1.83, v2.1.113]
tested_in: []
incorporated_in: ['3.3.0']
---

# `sandbox.network.deniedDomains` + `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`

## Observation

Two security additions to the sandbox model that our `domain/sandboxing.md` doesn't cover:

1. **`sandbox.network.deniedDomains`** (v2.1.113) — blocks specific domains even when wildcards in `allowedDomains` would match. Inverts the allowlist-only logic.
2. **`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`** (v2.1.83, hardened v2.1.98/v2.1.113) — strips Anthropic/cloud provider credentials from env before subprocess exec. Complements Linux PID-namespace subprocess isolation (v2.1.98).

## Why it matters for dotforge

Our `domain/sandboxing.md` Network section only describes `allowedDomains` — missing the denial override, which is the right tool when you trust a wildcard (`*.example.com`) except for a known-bad host.

Env-scrub is especially relevant for projects with cloud credentials in environment (InviSight, cotiza-api-cloud, trading bots). Worth documenting as a one-line setting to enable.

## Required update

Add to `domain/sandboxing.md` Network section:
```
- `network.deniedDomains`: overrides `allowedDomains` wildcards for specific hosts (v2.1.113+)
- `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1`: strips Anthropic/cloud provider credentials from subprocess env before exec (v2.1.83+, hardened v2.1.113)
- Linux subprocess isolation: PID-namespace sandboxing on Linux (v2.1.98+)
```

## Affected files

- `.claude/rules/domain/sandboxing.md`
