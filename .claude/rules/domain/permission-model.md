---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "Dual-list permission model and deny list requirements"
domain: claude-code-engineering
last_verified: 2026-03-25
---

# Permission Model

- Dual-list security: allow (explicit permissions) + deny (forbidden patterns)
- Never use Bash(*) — use specific wildcards: Bash(git *), Bash(docker *), Bash(npm *)
- Mandatory deny entries: **/.env, **/*.key, **/*.pem, **/*credentials*
- Mandatory deny commands: rm -rf *, git push*--force*, DROP TABLE, DROP DATABASE, chmod -R 777
- settings.json (committed, shared) vs settings.local.json (personal, gitignored)
- Sync merge strategy: deny list = union of sets (add missing, never remove); allow list = preserve as-is
- NEVER touch skipDangerousModePermissionPrompt — user decision only
- Permission sprawl: exact commands accumulate instead of wildcards (e.g., 40 ssh entries → 3 patterns)
- Audit: if settings.json OR block-destructive hook missing → security cap, max score 6.0
- mcpServers config goes in settings.json alongside permissions
