---
id: practice-2026-10-06-agents-md-native-support
title: Claude Code reads AGENTS.md natively when no CLAUDE.md exists; instructionFiles setting (v2.1.277–v2.1.285)
source: "/forge watch — docs/en/memory + CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: evaluating
tags: [memory, claude-md, export, templates, native-first]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
- v2.1.277: Claude reads `AGENTS.md` (and `.claude/AGENTS.md`) as project instructions when no `CLAUDE.md`/`.claude/CLAUDE.md`/`CLAUDE.local.md` exists in cwd or above. `~/.claude/CLAUDE.md`, managed CLAUDE.md and `.claude/rules/` still load alongside. v2.1.281: works on Bedrock/Vertex/Foundry/telemetry-off.
- "Project instructions" setting in `/config`: `claude-md-or-agents-md` (default) | `claude-md-and-agents-md` | `claude-md` | `managed-only`. Settings form: `pluginConfigs["cc-plugin-agents-md@builtin"].options.instructionFiles` — honored from user/`--settings`/managed only (plugin ID was `agents-md@builtin` before v2.1.285).
- Differences: `InstructionsLoaded` hooks do NOT fire for a directly-read AGENTS.md (they do for `@AGENTS.md` import); `--add-dir` AGENTS.md doesn't load. A `CLAUDE.local.md` counts as CLAUDE.md and suppresses AGENTS.md. Remove `SessionStart` hooks that print AGENTS.md (double context).
- `/import` (v2.1.213) appends a one-time copy of AGENTS.md etc. to CLAUDE.md and carries MCP/commands/subagents/skills. `/doctor prompt-audit` (v2.1.283) audits CLAUDE.md/AGENTS.md/rules/skills for stale paths, old-model phrasing, contradictions.
- `claudeMdExcludes` now matches symlinked rules by either path (v2.1.239). `CLAUDE_CODE_PROJECT_DIR_NAME` shares one auto-memory dir across launch dirs (v2.1.234).

## Evidence
Only hits in dotforge: `skills/export-config/SKILL.md:35` and `global/commands/forge-export.md` (Codex export target). dotforge-managed projects all ship `CLAUDE.md` so default behavior is unchanged — but `/forge export codex` now produces a file Claude Code itself may read when CLAUDE.md is absent.

## Impact on dotforge
- `.claude/rules/memory.md`, `.claude/rules/domain/context-window-optimization.md`: AGENTS.md section + `InstructionsLoaded` caveat
- `skills/export-config/SKILL.md`: note that exported AGENTS.md is live for Claude Code too; keep `@AGENTS.md` import pattern for shared-file setups
- `skills/audit-project/SKILL.md`: checklist item — project with AGENTS.md but no CLAUDE.md is valid native config
- `template/CLAUDE.md.tmpl`: optional `@AGENTS.md` import comment

## Decision
Pending
