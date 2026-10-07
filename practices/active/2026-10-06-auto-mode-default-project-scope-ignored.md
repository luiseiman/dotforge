---
id: practice-2026-10-06-auto-mode-default-project-scope-ignored
title: Auto mode is the default when no defaultMode is set; project-scope auto/bypassPermissions ignored (v2.1.257–v2.1.285)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [permissions, auto-mode, settings, templates, breaking-change, security]
tested_in: []
incorporated_in: ["global/settings.json.tmpl", ".claude/rules/domain/auto-mode.md", ".claude/rules/domain/permission-model.md", "audit/checklist.md", "audit/score.sh", "scripts/audit_all.py", "skills/audit-project/SKILL.md"]
replaced_by: null
effectiveness: monitoring
error_type: security
---

## Description
- v2.1.284: interactive terminal + VS Code sessions start in **auto mode** when no permission mode is configured, on every plan and provider. v2.1.283 (third-party/telemetry-off), v2.1.285 (`-p` + Python SDK on third-party). `permissions.defaultMode` still overrides.
- v2.1.257: `permissions.defaultMode` values `auto` and `bypassPermissions` **do not take effect from project or local settings** — only user/managed scope or `--permission-mode`.
- Classifier changes: server-side classifier is default on API/Enterprise/Bedrock/Vertex/Foundry/gateways (`CLAUDE_CODE_AUTO_MODE_SERVER=0` opts out, v2.1.278/282); turn stops after 10 consecutive unanswered denials (v2.1.280); classifier ignores `ANTHROPIC_DEFAULT_SONNET_MODEL` pin to 5.5 and uses Sonnet 5 (v2.1.288); `/permissions` has an Auto mode tab; `Monitor` allow rules set aside in auto mode (v2.1.246); `SendMessage` cross-session classified before dispatch (v2.1.222).

## Evidence
`template/settings.json.tmpl` and `global/settings.json.tmpl` set no `defaultMode` → every synced project now silently starts in auto mode. `global/settings.json.tmpl` allows `Bash(python3 *)`, `npx`, `node`, `Agent` — exactly the broad rules auto mode strips. `auto-mode.md:15-17` still says "Classifier runs on Sonnet 4.6… Fallback to prompt: 3 consecutive blocks OR 20 total" and "Enable: `permissions.defaultMode: "auto"`". `skills/audit-project/SKILL.md:70` audits "auto-pass if not auto".

## Impact on dotforge
- `global/settings.json.tmpl`: decide whether to pin `permissions.defaultMode` at user scope (production-tier projects should not drift into auto silently)
- `.claude/rules/domain/auto-mode.md`: rewrite header block (default, server classifier, opt-out, 10-denial stop)
- `.claude/rules/domain/permission-model.md`: note project/local scope cannot set `auto`/`bypassPermissions`
- `skills/audit-project/SKILL.md` item 8 + `audit/checklist.md` + `audit/score.sh` + `scripts/audit_all.py`
- Verify current mode of all 12 registry projects (`claude agents --json` or `/status`)

## Decision
Accepted 2026-10-06 — incorporated in dotforge v4.4.0 (/forge update, breaking batch).
