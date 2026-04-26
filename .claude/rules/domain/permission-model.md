---
globs: "**/settings.json,**/settings.local.json,**/settings.json.partial"
description: "Permission modes, evaluation cascade, deny list requirements"
domain: claude-code-engineering
last_verified: 2026-04-26
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

## Enterprise managed settings (v2.1.83+)

- `managed-settings.d/` drop-in directory: every `*.json` inside merges with the main `managed-settings.json`. Lets ops ship modular policy files.
- `allowManagedHooksOnly: true` — blocks ALL user/project/plugin hooks. Only managed-scope hooks (and hooks from plugins force-enabled by managed settings) run. Under this policy `.claude/hooks/` is inert at runtime — audit scoring should reflect runtime applicability, not file presence.
- `allowedChannelPlugins` — restricts which plugins activate via `--channels`.
- `forceRemoteSettingsRefresh` — fail-closed: blocks startup until remote settings fetched (v2.1.92).

## Dynamic permissions from hooks (v2.1.84+)

`PreToolUse` and `PermissionRequest` hooks can mutate runtime permission state via JSON output:

```json
{
  "hookSpecificOutput": {
    "decision": {
      "behavior": "allow|deny",
      "updatedInput": { "...": "..." },
      "updatedPermissions": [
        { "type": "addRules",          "rules": ["Bash(make *)"] },
        { "type": "replaceRules",      "rules": ["..."] },
        { "type": "removeRules",       "rules": ["..."] },
        { "type": "setMode",           "mode": "auto|default|plan|acceptEdits" },
        { "type": "addDirectories",    "directories": ["/tmp/build"] },
        { "type": "removeDirectories", "directories": ["..."] }
      ]
    }
  }
}
```

Use cases: a behavior self-elevates its allowlist for a session, a safety hook downgrades to `plan` mode after detecting risk, or a build hook whitelists a temporary directory. Static deny rules still enforce — a hook cannot remove a managed deny.

**Security note on `updatedInput` (v2.1.110+)**: when a hook returns `updatedInput` to mutate a tool call, the modified input is re-checked against `permissions.deny` before execution. A hook cannot use `updatedInput` to smuggle an otherwise-denied payload past static deny rules. Before v2.1.110 the recheck was missing and a hook could bypass denies via mutation.

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
- For OS-level defense-in-depth (kernel-enforced filesystem/network isolation), see `sandboxing.md`

## Tightened auto-approvals (v2.1.113+)

- `Bash(find:*)` allow rules NO LONGER auto-approve `find -exec` or `find -delete` — those drop back to the regular permission flow
- Bash deny rules now match commands wrapped in `env`, `sudo`, `watch`, `ionice`, `setsid`, and similar exec wrappers
- macOS: `/private/{etc,var,tmp,home}` paths are treated as dangerous removal targets under `Bash(rm:*)` allow rules
- v2.1.119: PowerShell tool commands can be auto-approved in permission mode (matching Bash); `cd <project-dir> && git ...` no longer triggers a permission prompt when the `cd` is a no-op
- Audit any stack `settings.json.partial` with `Bash(find:*)` or `Bash(rm:*)` allow rules — relying on prior auto-approval will now prompt

## Glob/Grep are platform-dependent (v2.1.117+)

On native macOS/Linux builds, standalone `Glob` and `Grep` tools are replaced by embedded `bfs`/`ugrep` reachable through Bash. `Glob(...)` and `Grep(...)` permission specifiers become inert on native builds — Windows and npm-installed builds keep the original tools. Prefer `Bash(...)` rules for cross-platform coverage.
