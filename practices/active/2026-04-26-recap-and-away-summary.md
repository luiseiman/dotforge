---
id: practice-2026-04-26-recap-and-away-summary
title: Native session recap (/recap, awaySummaryEnabled) — overlaps last-compact.md pattern (v2.1.108)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [context, settings, upstream, overlap]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
Three related additions for resuming idle sessions:

- `/recap` slash command — summarizes session state on demand
- `awaySummaryEnabled` setting — auto-shows a recap when returning to an idle session
- `CLAUDE_CODE_ENABLE_AWAY_SUMMARY` env var — forces recap on for telemetry-disabled deployments (Bedrock, Vertex, Foundry, `DISABLE_TELEMETRY`)

Available since v2.1.108; v2.1.110 enabled it for telemetry-disabled users.

## Evidence
CHANGELOG v2.1.108: "Added recap feature to provide context when returning to a session, configurable in `/config` and manually invocable with `/recap`".
CHANGELOG v2.1.110: "Session recap is now enabled for users with telemetry disabled... Opt out via `/config` or `CLAUDE_CODE_ENABLE_AWAY_SUMMARY=0`".

This overlaps with dotforge's `.claude/session/last-compact.md` pattern (in `template/rules/_common.md` and `template/hooks/post-compact.sh`). They solve adjacent problems: recap = idle return summary; last-compact = surviving compaction. Worth documenting the overlap so users don't double up.

## Impact on dotforge
- `.claude/rules/domain/context-control-patterns.md` — add `/recap` and `awaySummaryEnabled` alongside `/btw`, `/focus`, `/compact`
- `template/rules/_common.md` — clarify that `last-compact.md` is for compaction (model-driven loss of context), `/recap` is for user-driven idle return; they coexist
- `docs/best-practices.md` — note the pair

## Decision
Pending
