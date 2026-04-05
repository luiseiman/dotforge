---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "Permission modes, evaluation cascade, deny list requirements"
domain: claude-code-engineering
last_verified: 2026-04-05
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
3. Persistent allow rules
4. AcceptEdits mode → Allow
5. Auto mode → LLM classifier evaluation
6. Plan mode → Read-only enforcement
7. Default → derive from tool's danger level

## Settings cascade (priority order)

Managed (enterprise) > Local (.claude/settings.local.json) > Project (.claude/settings.json) > Global (~/.claude/settings.json)

## Bash prefix detection

- Separate LLM call (fast model) extracts command prefixes
- `cat foo.txt` → `cat`, `git commit -m "foo"` → `git commit`
- `npm run lint` → `none` (always prompts unless broadly allowed)
- Injection: `git status\`ls\`` → `command_injection_detected`

## Core rules

- Never use Bash(*) — use specific: Bash(git *), Bash(docker *), Bash(npm *)
- Mandatory deny: **/.env, **/*.key, **/*.pem, **/*credentials*
- Mandatory deny commands: rm -rf *, git push*--force*, DROP TABLE, DROP DATABASE, chmod -R 777
- Deny merge: union of sets (add missing, never remove). Allow: preserve as-is
- NEVER touch skipDangerousModePermissionPrompt — user decision only
- MCP tools default to `passthrough` (always ask)
- Audit: if settings.json OR block-destructive hook missing → max score 6.0
