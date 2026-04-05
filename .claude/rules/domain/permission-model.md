---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "Dual-list permission model and deny list requirements"
domain: claude-code-engineering
last_verified: 2026-04-02
---

# Permission Model

## 5-step evaluation cascade (source-verified)

1. Bypass mode check → immediate Allow
2. Persistent deny rules (pattern matching)
3. Persistent allow rules
4. AcceptEdits mode → Allow (SDK mode)
5. Plan mode → Read-only enforcement
6. Default → derive from tool's danger level

## Settings cascade (priority order)

Managed (enterprise, read-only) > Local project (.claude/settings.local.json) > Project shared (.claude/settings.json) > Global user (~/.claude/settings.json)

## Bash prefix detection

- Uses separate LLM call (fast model) to extract command prefixes
- `cat foo.txt` → `cat`, `git commit -m "foo"` → `git commit`
- `npm run lint` → `none` (no prefix — always prompts unless broadly allowed)
- Injection detected: `git status\`ls\`` → `command_injection_detected`
- Allow/deny rules match extracted prefixes, NOT raw commands

## Auto-mode permission stripping

When auto/YOLO mode activates, allow rules matching these are SILENTLY REMOVED:
- Interpreters: python, python3, python2, node, deno, tsx, ruby, perl, php, lua
- Package runners: npx, bunx, npm run, yarn run, pnpm run, bun run
- Shells: bash, sh, zsh, fish, eval, exec, env, xargs, ssh
- System: sudo
- Matching: exact (`python`), prefix (`python:*`), wildcard (`python*`, `python *`, `python -*`)
- Stripping is REVERSIBLE — rules stored in `strippedDangerousRules`, restored on exit
- Workaround: use specific tool commands (pytest, uvicorn, vitest), not interpreter patterns

## Tool concurrency & safety

| Tool | Concurrent-Safe | Read-Only |
|------|----------------|-----------|
| Read, Glob, Grep, LS | ✅ | ✅ |
| WebFetch, WebSearch | ✅ | ✅ |
| TodoWrite | ✅ | ❌ |
| Bash | ❌ | ❌ |
| Write, Edit | ❌ | ❌ |
| Agent | ❌ | ❌ |

## Core rules

- Never use Bash(*) — use specific wildcards: Bash(git *), Bash(docker *), Bash(npm *)
- Mandatory deny entries: **/.env, **/*.key, **/*.pem, **/*credentials*
- Mandatory deny commands: rm -rf *, git push*--force*, DROP TABLE, DROP DATABASE, chmod -R 777
- Sync merge strategy: deny list = union of sets (add missing, never remove); allow list = preserve as-is
- NEVER touch skipDangerousModePermissionPrompt — user decision only
- MCP tools default to `passthrough` (always ask) — fourth permission type beyond allow/ask/deny
- Audit: if settings.json OR block-destructive hook missing → max score 6.0
