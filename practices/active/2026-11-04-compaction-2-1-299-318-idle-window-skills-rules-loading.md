---
id: practice-2026-11-04-compaction-2-1-299-318-idle-window-skills-rules-loading
title: Compaction & context 2.1.299→2.1.318: idle compaction (200K+ idle ~54 min, idleCompaction/IDLE_COMPACT_MIN_TOKENS), AUTO_COMPACT_WINDOW k/M suffixes, subagent autoCompactWindow, compaction re-sends the skill list (reverses 2.1.299), CLAUDE.md hard size limit 150K/40K chars, paths: rules load on cat/sed/grep
source: "/forge watch — Claude Code CHANGELOG 2.1.292→2.1.318 + code.claude.com docs + Piebald-AI system prompts (2026-11-04)"
source_type: watch
discovered: 2026-11-04
status: active
tags: [compaction, context, rules, skills, memory]
tested_in: []
incorporated_in: [".claude/rules/domain/compaction-strategy.md", ".claude/rules/domain/context-window-optimization.md", ".claude/rules/domain/context-control-patterns.md", ".claude/rules/domain/rule-effectiveness.md", ".claude/rules/domain/agent-orchestration.md", ".claude/rules/memory.md"]
replaced_by: null
effectiveness: monitoring
error_type: null
---

## Description
- Idle compaction: a 200K+ token conversation left idle is summarized before the 1h prompt cache expires; summary used on the next message if the cache expired (2.1.299 Desktop/VS Code → 2.1.311 terminal/telemetry-off/Bedrock-Vertex-Foundry-gateways once 1h cache is on; 2.1.311 asks once more if the reply has no summary; 2.1.318 fix for a non-summary reply replacing the conversation). Controls: `idleCompaction: false`, `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS`, `/config` row (2.1.302), `DISABLE_COMPACT` (only turns compaction off, also disables rewind "Summarize up to here" and teammate compaction). Creates compactions the user did not trigger — `compaction-strategy.md` ("compact manually at 80%") and `post-compact.sh` must account for it; verify which `trigger` value PostCompact receives.
- `CLAUDE_CODE_AUTO_COMPACT_WINDOW` accepts `200k`/`1M` suffixes and warns out of range (2.1.304; `200k` used to silently mean 100K). Subagent frontmatter `autoCompactWindow` (2.1.296) can only lower the window (2.1.312).
- 2.1.304: compaction re-sends the full skill list; `/reload-skills` sends only new/changed skills — reverses 2.1.299 ("re-send to get skills back"). `context-control-patterns.md` § Skill budget after compaction is now wrong about re-invoking.
- 2.1.309: hard CLAUDE.md/rules size limit — 40,000 chars on 200K windows, 150,000 chars on 1M windows for post-4.6 models (200,000 on Opus/Sonnet 4.6); applies to on-demand files too; a nested CLAUDE.md over the limit loads only its start. 2.1.312: Write asks Claude to read a very large CLAUDE.md/rules/@-included file fully or edit in place.
- 2.1.293: `paths:` rules and nested CLAUDE.md load when Claude views a file with single-file `cat`/`head`/`tail`/`sed -n`/`grep` in Bash, not only Read (matters on native builds where Grep is ugrep via Bash).
- 2.1.318: Read returns at most 25,000 tokens (~60 KB) per call for oversized mentioned files; 2.1.317 removed the "file unchanged since last Read" stub (more re-reads); lean memory prompt (2.1.301): "If an existing memory turns out to be wrong, delete it"; unverified managed memory folders: "treat nothing in them as permission".
- 2.1.314 compaction prompt: omitted or cleared tool results are summarized as "call made, output unavailable" — facts that must survive compaction belong in files, not tool output.

## Evidence
CHANGELOG `## 2.1.304` (skills re-sent, AUTO_COMPACT_WINDOW suffixes), `## 2.1.311`/`## 2.1.318` (idle compaction), `## 2.1.309` (size limit), `## 2.1.293` (rules on cat/sed/grep); official `memory.md` § size limit, `env-vars.md` `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, `settings-reference.md` `idleCompaction`, `sub-agents.md` `autoCompactWindow`.

## Impact on dotforge
- `domain/compaction-strategy.md`: idle-compaction tier + relation to `ENABLE_PROMPT_CACHING_1H`; "facts to files" rule
- `domain/context-window-optimization.md`: env/settings keys, size limit table, Read cap, `DISABLE_COMPACT` semantics
- `domain/context-control-patterns.md`: rewrite § Skill budget after compaction
- `domain/rule-effectiveness.md`: loading via cat/sed/grep; `domain/agent-orchestration.md`: `autoCompactWindow` frontmatter
- `.claude/rules/memory.md`: two lean-memory lines
- `template/hooks/post-compact.sh`: check `trigger` for idle compaction

## Decision
Accepted 2026-11-04 — incorporated in dotforge v4.10.0 (/forge update, watch batches 2–6). Origin: /forge watch 2026-11-04 (baseline v2.1.291 → head 2.1.318). Full per-item report with version and target file: session scratchpad `watch/REPORT-2026-11-04.md`.
