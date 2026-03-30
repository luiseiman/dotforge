---
id: practice-2026-03-30-precompact-nonblocking
title: "PreCompact is non-blocking — hook-architecture.md incorrectly said it can block"
source: "watch-upstream — code.claude.com/docs/en/hooks"
source_type: research
discovered: 2026-03-30
status: active
tags: [hooks, precompact, documentation, correction]
tested_in: []
incorporated_in: [.claude/rules/domain/hook-architecture.md]
replaced_by: null
effectiveness: not-applicable
error_type: config
---

## Description

Official docs say PreCompact is "Non-blocking (logging/notification only)".
Previous documentation in hook-architecture.md incorrectly stated "can block with exit 2".

## Impact

If someone writes a hook that tries to block compaction via PreCompact, it will silently fail.
The compaction proceeds regardless of exit code.

## Incorporated

Corrected `.claude/rules/domain/hook-architecture.md`:
- Changed: "PreCompact hook receives: `trigger` ("auto"/"manual") + `custom_instructions` — can block with exit 2"
- To: "PreCompact hook receives: `trigger` ("auto"/"manual") — NON-BLOCKING, exit code is ignored, use for logging/capture only"
