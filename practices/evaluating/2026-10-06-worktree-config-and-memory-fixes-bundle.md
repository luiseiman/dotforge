---
id: practice-2026-10-06-worktree-config-and-memory-fixes-bundle
title: Low-priority fixes bundle — worktree include patterns, /cd settings reload, auto-memory hardening, code-review flags, MCP client defaults (v2.1.221–v2.1.290)
source: "/forge watch — CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: evaluating
tags: [worktree, memory, code-review, mcp, misc]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
- Worktrees: `.worktreeinclude` patterns beginning with `**/` fixed (v2.1.239); `/fork` creates its own worktree (v2.1.221); v2.1.161 scope fix stands.
- `/cd` (v2.1.246): project + local `settings.json` are re-read from the new directory.
- Auto-memory: invisible chars and Claude-Code-markup imitations neutralized in `MEMORY.md` and recalled notes (v2.1.284/288); truncation warning names the cut point (v2.1.268); cannot be enabled from a background session (v2.1.285); session cleanup no longer deletes memory folder contents (v2.1.228).
- `/code-review`: `/review` alias (v2.1.223); `--max-findings <n>|all` (v2.1.274); medium effort also reports cleanup + CLAUDE.md-convention findings (v2.1.290); `--comment` posts to GitLab MRs; runs as background subagent (W30); Bedrock/Vertex/Foundry can start it (v2.1.246). `/simplify` and `/security-review` bundled.
- MCP: Bedrock/Vertex/Foundry/telemetry-off use v2 MCP client + 2026-07-28 negotiation by default (v2.1.288); URL-mode elicitation needs `"bareElicitationCapability": true` if a server stops connecting (v2.1.287).
- Fast mode: available in remote sessions, falls back to standard speed (v2.1.257/271/286).
- Built-in "Concise" output style (v2.1.237). `/design` research preview (W34). Ultraplan removed (v2.1.222).

## Evidence
All low priority; no dotforge content contradicted. `agents.md` item 6 and `native-vs-dotforge-boundary.md` reference `/code-review` without the new flags.

## Impact on dotforge
- `.claude/rules/agents.md`, `.claude/rules/domain/native-vs-dotforge-boundary.md`: `/code-review` flags
- `.claude/rules/domain/parallel-sessions.md`: worktree notes
- `.claude/rules/memory.md`: MEMORY.md neutralization note
- `.claude/rules/domain/permission-managed-settings.md`: MCP client defaults

## Decision
Pending
