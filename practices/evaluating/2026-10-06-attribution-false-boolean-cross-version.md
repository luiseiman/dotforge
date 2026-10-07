---
id: practice-2026-10-06-attribution-false-boolean-cross-version
title: attribution:false boolean form breaks older CLIs (whole settings file skipped) — keep object form in shared files (v2.1.269, v2.1.281)
source: "/forge watch — CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: evaluating
tags: [git, attribution, settings, sync, compatibility]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
v2.1.281: `"attribution": false` hides all commit and PR attribution. **Older CLI versions skip a settings file that holds the boolean** — a shared `.claude/settings.json` with the boolean form disables every other key in that file for collaborators on older builds. Keep `{"commit": "", "pr": "", "sessionUrl": false}` object form in committed files. v2.1.269: the attribution reminder no longer overrides a CLAUDE.md or memory rule against attribution. Note: upstream attribution lines now reference `Claude Fable 5.1` / `Claude Opus 4.7 (1M context)` per model — `attribution.commit` templates keyed on a model name go stale.

## Evidence
`_common.md` § Git documents `attribution.commit`/`pr`/`sessionUrl`. `/forge sync` writes `settings.json` to 12 projects, some used from the VPS where the Claude Code binary may lag the Mac (native installs auto-update, Homebrew/apt do not). Same class as the hook-parsing resilience note in `hook-architecture.md`.

## Impact on dotforge
- `.claude/rules/_common.md` § Git: boolean form caution
- `template/settings.json.tmpl`, `global/settings.json.tmpl`: never emit boolean `attribution`
- `skills/sync-template/SKILL.md`: merge rule — if a project has boolean `attribution`, convert to object form
- `skills/audit-project/SKILL.md`: flag boolean `attribution` in shared file

## Decision
Pending
