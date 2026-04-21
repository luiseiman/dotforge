---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "OS-level bash sandboxing — filesystem and network isolation complementary to permission rules"
domain: claude-code-engineering
last_verified: 2026-04-21
---

# Sandboxing

OS-level isolation of bash subprocesses (macOS, Linux, WSL2 only — no Windows native). Default off. Configured via `sandbox.*` in `settings.json`. Complements permission rules, does not replace them.

## Core keys

- `enabled`: turn on. Default false
- `failIfUnavailable`: hard-fail startup if sandbox cannot start (managed-settings hard gate)
- `autoAllowBashIfSandboxed` (default true): auto-approve bash when sandboxed, trading prompts for kernel enforcement
- `excludedCommands`: run outside sandbox (e.g. `["docker *"]` when socket access is needed)
- `allowUnsandboxedCommands: false`: disables `dangerouslyDisableSandbox` escape hatch entirely

## Filesystem (kernel-enforced)

- `filesystem.allowWrite` / `denyWrite` / `denyRead` / `allowRead`
- Arrays MERGE across managed + project + user scopes. Also merge with `Edit(...)` and `Read(...)` permission rules
- Prefixes: `//abs`, `~/home`, `./project-rel`
- Applies to ALL subprocesses (kubectl, terraform, npm), not only Claude's file tools

## Network (kernel-enforced)

- `network.allowedDomains`: outbound allowlist with wildcards. Non-listed domains blocked without prompting
- `network.deniedDomains` (v2.1.113+): overrides `allowedDomains` wildcards for specific hosts — use when you trust `*.example.com` except `bad.example.com`
- `network.allowUnixSockets`, `allowLocalBinding`, `allowMachLookup` (macOS): granular exceptions
- `network.httpProxyPort` / `socksProxyPort`: BYO proxy
- `enableWeakerNetworkIsolation` (macOS): required for `gh`, `gcloud`, `terraform` with TLS + MITM proxy. Opens exfil path — enable only when needed

## Subprocess env-scrub and PID isolation

- `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` (v2.1.83+, hardened v2.1.98/v2.1.113): strips Anthropic/cloud provider credentials from subprocess env before exec. Prevents cred leak via child processes.
- Linux (v2.1.98+): subprocess sandboxing via PID namespace isolation — defense-in-depth complement to env-scrub.
- Enable both for projects with cloud creds in env (trading bots, cotiza-api-cloud, InviSight).

## When to enable

Projects with secrets in env/home (cloud creds, API keys, trading bots), agents running untrusted code, workflows where exfil or destructive bash would be catastrophic.

## Interaction with permission model

Sandbox is a second layer. `block-destructive.sh` and `deny:` still apply as defense-in-depth. With `autoAllowBashIfSandboxed: true`, bash `ask:`/`allow:` become less relevant for kernel-protected commands, but still cover `excludedCommands` fallback.
