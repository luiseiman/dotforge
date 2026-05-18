---
id: practice-2026-05-18-docs-domain-migration-claude-code
title: "Docs domain migration: docs.anthropic.com/en/docs/claude-code → code.claude.com/docs/en"
source: "own experience — /forge watch run 2026-05-17"
source_type: experience
discovered: 2026-05-18
status: active
tags: [docs, links, watch-upstream, maintenance]
tested_in: dotforge
incorporated_in: [skills/watch-upstream/SKILL.md, docs/internal/improvement-plan-internals.md]
replaced_by: null
effectiveness: informational
error_type: null
---

## Description

All `docs.anthropic.com/en/docs/claude-code/*` URLs now return **HTTP 301 → code.claude.com/docs/en/***. The watch-upstream skill's hardcoded URL list (`overview`, `settings`, `hooks`, `memory`, `agent-tool`, `cli`) all redirect on every fetch. Net cost: every `/forge watch` run does six unnecessary round-trips before resolving.

The `agent-tool` slug also moved — it's now `sub-agents` on the new domain. So that one is both domain-migrated AND renamed.

## Evidence

Confirmed during `/forge watch` on 2026-05-17:

```
WebFetch https://docs.anthropic.com/en/docs/claude-code/overview
→ 301 Moved Permanently → https://code.claude.com/docs/en/overview

WebFetch https://docs.anthropic.com/en/docs/claude-code/agent-tool
→ 404 Not Found
WebFetch https://code.claude.com/docs/en/sub-agents
→ 200 OK
```

Effective date: rollout appears to have happened between the previous watch capture set (2026-04-26 onward, which still used docs.anthropic.com without 301 issues) and 2026-05-17. Possibly tied to the `code.claude.com` launch alongside Claude Code's plugins / web product expansion (cf. the `claude-code-setup` plugin push around the same window).

## Impact on dotforge

- `skills/watch-upstream/SKILL.md` Step 1 — hardcoded URL list needs the domain swap + the `agent-tool` → `sub-agents` rename
- `docs/` — any markdown linking to `docs.anthropic.com/en/docs/claude-code/*` (search and replace)
- `practices/active/*.md` — `source:` field on several entries references the old domain; cosmetic, can be left or batch-rewritten
- `scripts/runtime/lib.sh` and any other tooling that fetches docs — search for hardcoded URLs

The fetches still work today via 301, so this is not breaking — just wasteful round-trips and an opportunity to update the canonical references before old links rot.

## Decision
Incorporated 2026-05-18. URLs updated in watch-upstream skill (6 fetch URLs + 1 fallback search query), agent-tool path renamed to sub-agents, defensive note added pointing to llms.txt as canonical index for future migrations. Internal docs reference also updated.