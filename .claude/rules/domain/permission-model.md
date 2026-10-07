---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "Permission modes, evaluation cascade, deny list requirements"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Permission Model

## 6 permission modes

| Mode | Behavior | Use case |
|------|----------|----------|
| default | Allow/deny rules + prompt for unknowns | Normal interactive use |
| acceptEdits | Allow most edits without prompt — **exceptions: shell rc files (always) + build-tool config (v2.1.160+)** | SDK mode |
| plan | Read-only enforcement | Architecture planning |
| auto | LLM classifier decides per-tool (server-side classifier by default, v2.1.278+). **Session default when `defaultMode` is unset (v2.1.284+)** | Autonomous operation |
| dontAsk | Auto-deny everything not explicitly allowed | CI/headless pipelines (see also `--permission-prompts none`, v2.1.259: keeps the active mode's decisions but denies anything that would prompt) |
| bypassPermissions | Allow everything | Fully trusted environments |

**Scope restriction (v2.1.257)**: `permissions.defaultMode` values `auto` and `bypassPermissions` do not take effect from project (`.claude/settings.json`) or local (`settings.local.json`) scope — set them in user or managed settings, or pass `--permission-mode` for one session. Before v2.1.257 `bypassPermissions` took effect from any file. See `auto-mode.md` for the v2.1.284 default flip.

## Paths that always prompt regardless of mode (v2.1.160+)

Claude Code prompts before writing to these regardless of `permissions.defaultMode` (even `acceptEdits` and `auto`). The prompt is built-in and cannot be suppressed without `bypassPermissions`:

**Shell startup files** (always):
- `.zshenv`, `.zlogin`, `.bash_login`
- Anything under `~/.config/git/`

**Build-tool config** (prompts in `acceptEdits` mode):
- `.npmrc`, `.yarnrc*`, `bunfig.toml`, `.bazelrc`
- `.pre-commit-config.yaml`
- Anything under `.devcontainer/`

Reason: these files can execute arbitrary commands at shell-startup time or alter the entire toolchain, so a single hallucinated edit can compromise the dev environment. Defense-in-depth: `sandbox.filesystem.denyWrite` is the kernel-level equivalent that cannot be bypassed by mode. For projects where Claude should never touch these even with consent, add to `permissions.deny`.

## Reads outside working directories (`permissions.blockReadsOutsideWorkingDirectories`, v2.1.257+)

Denies Read/Grep/Glob and Bash file reads outside the session's working directories (cwd + `--add-dir` + `permissions.additionalDirectories`); auto mode prompts on the first outside read. Twelve follow-up fixes through v2.1.290 closed holes in compound Bash, `cd`+`git` chains, auto-memory dirs, symlinked CLAUDE.md/rules/AGENTS.md, pasted image paths, and `sandbox.credentials.files` on git config. Recommended for production-tier projects (TRADINGBOT, cotiza-api-cloud, SOMA) — but add the vault, shared config dirs, or `~/.claude/projects` explicitly via `additionalDirectories` first, or `/forge` skills that read `$DOTFORGE_DIR` will be denied.

## Hardening modes for unattended runs

- `--restricted` / `CLAUDE_CODE_RESTRICTED=1` (v2.1.248): removes command/code-running tools and WebFetch unless named individually in `--tools`; confines file tools to working directories; loads only managed settings + `--settings`; refuses `bypassPermissions` and cloud-session creation. Built for eval harnesses on shared machines
- `--permission-prompts none` (v2.1.259, `-p` only): anything that would prompt is denied while the active mode keeps deciding. Prefer over `dontAsk` when allow rules should still apply
- **Native dangerous-`rm` guard** (v2.1.261/281): `rm` targeting `/`, `~`, `$VAR`, `"$(pwd)"`, or inside `bash -c` scripts prompts even in auto and bypass modes; an unanswered prompt is denied after 2 minutes. Opt-outs: `CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT=1`, `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT=1`. Overlaps `block-destructive.sh` for `rm` only — the hook still owns force-push, `DROP`, `chmod 777`, `git checkout --`

## Evaluation cascade

1. Bypass mode → immediate Allow
2. Persistent deny rules (pattern matching)
3. **Plan mode → Read-only enforcement** (v2.1.136+: now precedes allow rules — was a bug where `Edit(*)` allow could write under plan mode)
4. Persistent allow rules
5. AcceptEdits mode → Allow
6. Auto mode → LLM classifier evaluation (with `hard_deny` short-circuit before classifier — see `auto-mode.md`)
7. Default → derive from tool's danger level

## Settings cascade (priority order)

Managed > Local (`.claude/settings.local.json`) > Project (`.claude/settings.json`) > Global (`~/.claude/settings.json`). Enterprise-managed scope details in `permission-managed-settings.md`.

## Bash prefix detection

Separate fast-model LLM call extracts command prefixes. `cat foo.txt` → `cat`. `git commit -m "foo"` → `git commit`. `npm run lint` → `none` (always prompts). Injection like `git status\`ls\`` → `command_injection_detected`.

## Permission-detection bypasses fixed in v2.1.145-149

Three classes of prefix-detection holes patched in the v2.1.145–v2.1.149 hardening pass. Projects running older versions may have had silent auto-approvals for these patterns:

- **Bare env var assignments** (v2.1.145): `FOO=bar some-command` with `FOO` not on the known-safe allowlist (`LANG`, `TZ`, `NO_COLOR`, etc.) was auto-approved. The bare-assignment case wasn't routed through env-prefix detection.
- **PowerShell built-in `cd` functions** (v2.1.149): `cd..`, `cd\`, `cd~`, and drive-letter switches like `X:` changed the working directory without being detected, letting a subsequent command in the same PowerShell call read outside the workspace boundary. Affects Windows users + anyone with `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` on Linux/macOS.
- **Stale `PWD`/`OLDPWD`/`DIRSTACK` variable tracking** (v2.1.149): the parser trusted stale values across `cd`/`pushd`/`popd`, enabling the same workspace-escape class as the cd built-ins.

Defense-in-depth that catches these even when prefix detection missed them: `block-destructive.sh` (regex over full command string) + kernel-level `sandbox.filesystem.denyRead`. See `sandboxing.md`.

## Permission-detection bypasses fixed in v2.1.221–v2.1.290

Second hardening wave. Any build older than the cited version silently auto-approved the pattern:

- zsh `[[ ]]` regex conditionals (v2.1.221); zsh conditional syntax checking (v2.1.238); zsh-specific variable names now prompt (v2.1.288)
- Hidden/padded commands (v2.1.223); dangling `&&` / `||` always prompts (v2.1.246)
- Arithmetic assignment to integer variables (`OPTIND=1/0`, `RANDOM=2+2`) no longer auto-approved (v2.1.252)
- Variable prefixes (`TZ="$HOME" rm …`) now hit deny/ask rules under sandbox auto-allow (v2.1.288); variable-name prefixes on `declare`/`export`/`readonly` prompt (v2.1.290)
- `rg` / `git grep` with shell-expanded wildcards, `ps`, `pyright`, `tee` now prompt (v2.1.268–290)
- Read deny covers pasted image paths and symlinks (v2.1.274); symlink swapped after the permission check is caught (v2.1.251); Grep/Glob apply `Read(...)` deny through symlinked search paths (v2.1.251)
- PreToolUse `updatedInput` re-checked against ALL rules and safety checks, not only `deny` (v2.1.290); `permissions.ask` honored inside compound/subshell commands in auto mode (v2.1.257)
- Workflow `scriptPath` read before the permission check fixed (v2.1.251); workflow `import()` sandbox escape fixed (v2.1.223)

Rule hygiene (startup warnings/errors): an allow rule with a wildcard before the subcommand (`Bash(git * main)`) also matches options inserted before the subcommand — warned since v2.1.246; a rule with text after `)` is reported invalid (v2.1.260); a `!`-prefixed deny/ask rule applies only within its own settings source (v2.1.269). `/commit-push-pr`: git/gh with `--force`, `--amend`, `--no-verify` never auto-approved (v2.1.229).

## Workspace trust (v2.1.218–v2.1.248)

The workspace-trust dialog gates, beyond project settings and top-level hooks:
- Project-level subagent frontmatter `hooks:` blocks (v2.1.218) — untrusted → skipped, subagent still runs; `claude -p`/SDK/CI never run untrusted frontmatter hooks
- Inline `mcpServers` in `.claude/agents/*.md` or `--add-dir` agent files (v2.1.238); project `.mcp.json` `headersHelper` (v2.1.248, also under `-p`). Helpers from project/plugin/agent files run **without inherited credential env vars**
- Nested git repos no longer inherit trust from a parent checkout (v2.1.232)
- `claude --bg` and sessions dispatched from `claude agents` check trust before starting (v2.1.225)
- Not gated: `~/.claude/agents/`, `--agents` inline JSON, managed settings

Pre-v2.1.218 injection path (hostile PR ships `agents/reviewer.md` with hooks that fire on next checkout) is closed. See `agent-orchestration.md` § Subagent frontmatter hooks require workspace trust.

## Core rules

- Never `Bash(*)` — use specific: `Bash(git *)`, `Bash(docker *)`, `Bash(npm *)`
- Mandatory deny paths: `**/.env`, `**/*.key`, `**/*.pem`, `**/*credentials*`
- Mandatory deny cmds: `rm -rf *`, `git push*--force*`, `DROP TABLE`, `DROP DATABASE`, `chmod -R 777`
- Deny merge: union (add missing, never remove). Allow: preserve as-is
- NEVER touch `skipDangerousModePermissionPrompt` — user decision only
- Audit: missing `settings.json` OR `block-destructive.sh` → score capped at 6.0
- OS-level defense-in-depth: see `sandboxing.md`

## Tightened auto-approvals (v2.1.113+)

- `Bash(find:*)` no longer auto-approves `find -exec` / `find -delete` — back to normal permission flow
- Bash deny rules match commands wrapped in `env`, `sudo`, `watch`, `ionice`, `setsid`
- macOS: `/private/{etc,var,tmp,home}` treated as dangerous under `Bash(rm:*)` allow rules
- v2.1.119: PowerShell auto-approval matches Bash; `cd <project-dir> && git ...` no longer prompts when `cd` is a no-op
- Audit any stack `settings.json.partial` with `Bash(find:*)` or `Bash(rm:*)` allow rules — prior auto-approvals will prompt

## Glob/Grep are platform-dependent (v2.1.117+)

Native macOS/Linux builds replace standalone `Glob`/`Grep` with embedded `bfs`/`ugrep` via Bash. `Glob(...)` and `Grep(...)` permission specifiers become inert on native builds. Windows and npm-installed builds keep originals. Prefer `Bash(...)` rules for cross-platform coverage.
