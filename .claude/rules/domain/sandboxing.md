---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "OS-level bash sandboxing — filesystem and network isolation complementary to permission rules"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Sandboxing

OS-level isolation of bash subprocesses (macOS, Linux, WSL2 only — no Windows native). Default off. Configured via `sandbox.*` in `settings.json`. Complements permission rules, does not replace them.

## Core keys

- `enabled`: turn on. Default false
- `failIfUnavailable`: hard-fail startup if sandbox cannot start (managed-settings hard gate)
- `autoAllowBashIfSandboxed` (default true): auto-approve bash when sandboxed, trading prompts for kernel enforcement
- `excludedCommands`: run outside sandbox (e.g. `["docker *"]` when socket access is needed)
- `allowUnsandboxedCommands: false`: disables `dangerouslyDisableSandbox` escape hatch entirely
- `credentials` (v2.1.187+, schema expanded v2.1.221–232): `files: [{path, mode: "mask|deny", extract: "regex", onExtractNoMatch, decode: "jwt", maskClaims}]`, `envVars: [{name, mode}]`, plus `awsPairs` / `sigv4` for AWS key pairs. `mode: "mask"` redacts the value in tool output, `mode: "deny"` blocks the read. Masking requires `network.tlsTerminate` and is honored only from user, managed, or `--settings` scope — a project partial carrying `sandbox.credentials` is inert. **File `mode: "mask"` works on Linux and WSL only; on macOS it falls back to `deny`** — so on a Mac an app that must read its own API key file cannot use mask; keep the key in env (`envVars` mask) instead. Invalid `credentials` config degrades to `deny` instead of failing startup. GitLab tokens redacted and `glab` config store protected like `gh` (v2.1.224). Defense-in-depth over `denyRead` — recommended for production-tier projects (TRADINGBOT, cotiza-api-cloud, InviSight) at user scope: `deny` for `~/.aws`, `~/.ssh`, `~/.kube`, `~/.netrc`; `envVars` mask for keys the app reads from env. Old boolean form no longer valid.
- Scope-restricted keys (user/managed/`--settings` only): `credentials`, `ripgrep`, `bwrapPath`, `socatPath`; `excludedCommands` from project/local is ignored when managed sets `allowUnsandboxedCommands:false` or `allowManagedDomainsOnly:true` (v2.1.282–290). Project settings cannot widen or disable an admin-required sandbox. See `permission-managed-settings.md` § Project/local scope cannot widen policy
- `!` bash-mode commands typed by the user run **outside** the sandbox even in strict mode (v2.1.260); `allowUnsandboxedCommands:false` still disables the model's `dangerouslyDisableSandbox`. Sandboxed heredocs and `python3 -c` no longer prompt every run under auto-allow (v2.1.283)
- `allowAppleEvents` (v2.1.181+, macOS only): opt-in to let sandboxed commands send Apple Events. Required for scripts that drive Finder/Safari/Mail/Automator. Default deny — leave off unless a project genuinely needs OS automation.

## Filesystem (kernel-enforced)

- `filesystem.allowWrite` / `denyWrite` / `denyRead` / `allowRead`
- Arrays MERGE across managed + project + user scopes. Also merge with `Edit(...)` and `Read(...)` permission rules. `--setting-sources` is honored by the sandbox filesystem config since v2.1.246
- Prefixes: `//abs`, `~/home`, `./project-rel`. **Do not write deny entries with a trailing slash** (`"~/.aws/"`) — they were silently bypassable before v2.1.224; macOS wildcard read-deny (`**/.env`) now takes precedence and survives renames (v2.1.236)
- Applies to ALL subprocesses (kubectl, terraform, npm), not only Claude's file tools. Sandbox violation details now appear in Bash results (v2.1.224/243). Sandboxed commands may write to project dirs named `hooks/` or `config/` again (v2.1.275 — were caught by the shared-`.git` exception)

## Network (kernel-enforced)

- `network.allowedDomains`: outbound allowlist with wildcards. Non-listed domains prompt; `network.strictAllowlist: true` (v2.1.219+) denies them without prompting
- `network.deniedDomains` (v2.1.113+): overrides `allowedDomains` wildcards for specific hosts — use when you trust `*.example.com` except `bad.example.com`. A trailing-dot host (`bad.example.com.`) now blocks too (v2.1.282)
- Per-command `allowed_domains` on Bash/PowerShell/Monitor calls in auto mode (v2.1.271): the model can request a narrower outbound set for one command; still bounded by the session allowlist
- `network.tlsTerminate`: required for `credentials` masking (v2.1.221)
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

## Worktree allowlist scope fix (v2.1.149)

When working inside a `claude --worktree`, the sandbox's automatic write allowlist for the shared `.git` directory was previously covering the **entire main repo root** (with `hooks/` and `config` denied as exceptions). v2.1.149 corrected the scope to just the shared `.git` directory subset.

Implications:
- Pre-v2.1.149: code running in a worktree had sandbox-blessed write access to most of the main repo's files
- Post-v2.1.149: sandbox correctly limits writes to the worktree itself + the legitimate shared `.git` paths
- Agent Teams patterns that relied on worktree teammates writing to main-repo files were exploiting the bug — verify and rework
- **Workflow regression + fix (v2.1.149 → v2.1.161)**: the v2.1.149 scope correction was too strict for Workflow agents with `isolation: "worktree"` — they were blocked from editing files inside their OWN worktree. v2.1.161 restored correct scope: writes to the agent's own worktree are allowed, writes outside still denied. Only impacts users of `agent(prompt, {isolation: 'worktree'})` in `/workflows` scripts.
- **Destructive git against the main checkout blocked (v2.1.222)**: worktree-isolated sessions and their subagents can no longer run destructive git commands that target the main checkout (reset, checkout --, branch -D on main). `isolation: worktree` enforces working-directory checks (v2.1.203) and repository-boundary checks (v2.1.210); PowerShell gets the working-directory check only. This is permission-level, independent of the sandbox.

## Built-in safety prompts (Claude-Code-level, v2.1.160+)

Claude Code itself prompts before writing to shell startup files (`.zshenv`, `.zlogin`, `.bash_login`, `~/.config/git/`) and build-tool config (`.npmrc`, `.yarnrc*`, `bunfig.toml`, `.bazelrc`, `.pre-commit-config.yaml`, `.devcontainer/` — the build-tool list applies only in `acceptEdits` mode). See `permission-model.md` § Paths that always prompt.

These are NOT sandbox-level — they are Claude-Code-level UX prompts, suppressed only by `bypassPermissions`. For defense-in-depth that survives `bypassPermissions`, `claude -p`, and Agent SDK, use `sandbox.filesystem.denyWrite` to enforce at kernel level:

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "denyWrite": [
        "~/.zshenv", "~/.zlogin", "~/.bash_login",
        "~/.config/git",
        ".npmrc", ".yarnrc", ".yarnrc.yml",
        "bunfig.toml", ".bazelrc",
        ".pre-commit-config.yaml",
        ".devcontainer"
      ]
    }
  }
}
```

## PowerShell execution policy bypass (v2.1.143+)

Claude Code passes `-ExecutionPolicy Bypass` by default when invoking the PowerShell tool, allowing unsigned scripts to run. Enabled by default for Windows users on Bedrock/Vertex/Foundry.

For enterprise environments with AppLocker, signed-only PowerShell policies, or strict PSScriptAnalyzer rules, this crosses the OS-level trust boundary:

- `CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY=1` — opt out of the bypass; the tool honors the system execution policy
- `CLAUDE_CODE_USE_POWERSHELL_TOOL=0` — disable the PowerShell tool entirely

For projects that handle financial data, healthcare records, or any regulated workload on Windows, set the respect-policy env var as a managed-settings env or in the CI runbook.
