---
id: practice-2026-03-30-postcompact-payload-verify
title: "PostCompact payload verified: compact_summary and trigger ARE present"
source: "watch-upstream — code.claude.com/docs/en/hooks"
source_type: research
discovered: 2026-03-30
status: active
tags: [hooks, postcompact, context-continuity, verified]
tested_in: [dotforge]
incorporated_in: [.claude/rules/domain/hook-architecture.md]
replaced_by: null
effectiveness: not-applicable
error_type: null
verified: 2026-03-30
verification_result: "compact_summary AND trigger ARE present in PostCompact payload. Official docs are incomplete — they say 'Common fields only' but these extra fields DO arrive."
---

## Description

Official docs say PostCompact receives "Common fields only" (session_id, transcript_path, cwd, etc.).
dotforge's `post-compact.sh` reads `compact_summary` and `trigger` — both undocumented.

## Verification

Added debug logging to `.claude/hooks/post-compact.sh`, triggered `/compact` manually.
Actual payload received:
```json
{
  "session_id": "...",
  "transcript_path": "...",
  "cwd": "...",
  "hook_event_name": "PostCompact",
  "trigger": "manual",
  "compact_summary": "<full summary text>"
}
```

Both `compact_summary` and `trigger` confirmed present. Docs are incomplete, not wrong about what exists.
Hook implementation is correct. Context continuity cycle is intact.

## Incorporated

Updated `.claude/rules/domain/hook-architecture.md` with:
"PostCompact hook receives: `trigger` + `compact_summary` — VERIFIED 2026-03-30, docs say 'common fields only' but these extra fields DO arrive"
