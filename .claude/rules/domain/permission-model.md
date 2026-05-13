---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "Permission modes, evaluation cascade, deny list requirements"
domain: claude-code-engineering
last_verified: 2026-05-13
---

# Permission Model

## 6 permission modes

| Mode | Behavior | Use case |
|------|----------|----------|
| default | Allow/deny rules + prompt for unknowns | Normal interactive use |
| acceptEdits | Allow all edits without prompt | SDK mode |
| plan | Read-only enforcement | Architecture planning |
| auto | LLM classifier decides per-tool (Sonnet 4.6) | Autonomous operation |
| dontAsk | Auto-deny everything not explicitly allowed | CI/headless pipelines |
| bypassPermissions | Allow everything | Fully trusted environments |

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
