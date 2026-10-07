---
id: practice-2026-10-06-claude-mods-tool-check-vs-behaviors-v3
title: Claude Mods — plugins modify runtime behavior via hooks modules (tool.check, turn.step, agent.spawn); overlaps behaviors v3 (v2.1.287–v2.1.290)
source: "/forge watch — CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [plugins, mods, behaviors, v3, native-first, boundary]
tested_in: []
incorporated_in: ["scripts/compiler/compile.sh", ".claude/hooks/generated/", "docs/v3/SPEC.md", "docs/v3/DECISIONS.md", "docs/v3/COMPILER.md", ".claude/rules/domain/hook-events.md"]
replaced_by: null
effectiveness: monitoring
error_type: logic
---

## Description
v2.1.287 launched Claude Mods: plugins ship hooks modules that hot-reload in-session and intercept `tool.check`, `turn.step`, `ui.render`, `prompt.submit`, `agent.spawn`. Built-in `plugin-authoring` skill documents the API; built-in `you-should-know` mod monitors sessions. `claude plugin validate` reports `gatingHooks` (v2.1.289). v2.1.290: org-managed guards win over user-installed mods; server tool use tracking added to mod hooks; theme color types for plugins; organization approval ceilings for tools.

## Evidence
dotforge v3 behaviors compile YAML → bash `PreToolUse` hooks sharing `.forge/runtime/state.json` for graduated escalation (silent→nudge→warning→soft_block). A native `tool.check` module is a first-class, in-process equivalent with no bash/jq/state-file plumbing. `native-vs-dotforge-boundary.md` keeps the escalation engine as the "real delta" — that delta must be re-validated against Mods: can a mod hold per-session counters and escalate? If yes, the compiler (`scripts/compiler/`) should target a mod module instead of bash hooks, or behaviors v3 should be retired.

## Impact on dotforge
- `.claude/rules/domain/native-vs-dotforge-boundary.md`: behaviors verdict — re-verify against Mods
- `docs/v3/COMPETITIVE.md`, `DECISIONS.md`: new competitor is native
- `scripts/compiler/compile.sh`: evaluate a `--target mod` backend (spike before deciding)
- `.claude/rules/domain/plugin-distribution.md`: Mods section, `gatingHooks`, managed-guard precedence
- `.claude/rules/domain/hook-architecture.md`: distinguish settings hooks vs mod hooks modules

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.7.0 (native-first boundary decisions). See docs/changelog.md v4.7.0 for the verdict.
