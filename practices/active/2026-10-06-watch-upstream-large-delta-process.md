---
id: practice-2026-10-06-watch-upstream-large-delta-process
title: When /forge watch delta exceeds ~30 releases, download CHANGELOG raw and split classification across subagents by version range
source: "own experience"
source_type: experience
discovered: 2026-10-06
status: active
tags: [process, watch-upstream, subagents, context, skills]
tested_in: dotforge
incorporated_in: ["skills/watch-upstream/SKILL.md", ".claude/rules/domain/workflow-economics.md"]
replaced_by: null
effectiveness: monitoring
error_type: logic
---

## Description
`WebFetch` on `CHANGELOG.md` summarizes through a small model and returned one line per version for 2.1.284–2.1.291 — it silently dropped ~60 versions and every bullet. For deltas >30 releases: (1) `curl` the raw CHANGELOG into the scratchpad, (2) `sed` the slice between the newest header and the last-covered version, (3) spawn 2 sonnet subagents in parallel, each owning a contiguous version range, with the dotforge impact table and an instruction to `grep` the repo per kept bullet before classifying, (4) keep doc pages (`settings`, `memory`) as persisted files and grep them for `v2.1.N` notes instead of reading inline. Spot-check the top findings against the raw slice before reporting. Cost this run: ~500K subagent tokens for 62 versions, main context stayed usable.

## Evidence
2026-10-06 run: baseline v2.1.218 → head v2.1.291 (73 releases, 3185 changelog lines). WebFetch summary missed `PreModelSwitch`, nesting depth 3, todo-tools gating, `blockReadsOutsideWorkingDirectories`, auto-mode default — all found only via raw slice. Two agents reported slightly inconsistent boundaries (no headers for 2.1.253–256, 2.1.262, 2.1.264, 2.1.279) — ranges must be assigned by header presence, not arithmetic.

## Impact on dotforge
- `skills/watch-upstream/SKILL.md`: add Step 1b "raw changelog slice" + Step 2b "split by range when >30 versions" + spot-check step
- `.claude/rules/domain/workflow-economics.md`: this is the bash-first + 2-agent pattern, not a workflow — document as the reference for `/forge watch`
- `global/commands/forge.md`: `watch` description mentions last-covered-version baseline in `practices/metrics.yml`

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.6.0 (/forge update, catalogue block).
