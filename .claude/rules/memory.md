---
globs: "**/*"
description: "Memory management policy — always loaded"
---

# Memory Policy

## Error Memory (CLAUDE_ERRORS.md)
- Before modifying code, read CLAUDE_ERRORS.md for known issues in the affected area
- After fixing a bug, record it: date, area, root cause, fix applied, derived rule
- If same error appears 3+ times across sessions, promote the derived rule to _common.md or a stack-specific rule
- Format: markdown table with columns Date | Area | Type | Error | Cause | Fix | Rule
- Type must be one of: `syntax`, `logic`, `integration`, `config`, `security`

## Agent Memory (.claude/agent-memory/)
- Agents with `memory: project` persist learnings in .claude/agent-memory/<agent-name>/
- Consult agent memory before starting work in their domain
- Update agent memory after completing tasks with new discoveries
- Agents WITHOUT memory (researcher, test-runner) are transactional — they execute and report, don't accumulate knowledge

## Auto-Memory (Claude Code built-in)
- Claude Code persists discoveries automatically when autoMemoryEnabled is true
- Do not duplicate auto-memory content in CLAUDE.md — they serve different purposes
- CLAUDE.md = prescriptive (what to do). Auto-memory = descriptive (what was discovered)
- **200-line / 25 KB cutoff**: only the first 200 lines (or 25 KB, whichever first) of MEMORY.md are injected at session start — anything beyond is invisible; the truncation warning names the cut point (v2.1.268)
- Invisible characters and text imitating Claude Code markup (`<system-reminder>`, `Human:`) are neutralized in MEMORY.md and recalled notes before injection (v2.1.284/288) — do not rely on memory files to carry literal control markup
- Auto memory cannot be enabled from a background session (v2.1.285); session cleanup never deletes the project memory folder (v2.1.228 fix)
- Keep MEMORY.md as a concise index of links to memory files, not a dump of content
- If MEMORY.md approaches 150 lines, archive low-relevance entries or consolidate related memories
- Memory files themselves have no line limit — only the MEMORY.md index is capped
