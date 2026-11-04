---
id: practice-2026-11-04-short-behavioral-rules-ask-vs-proceed-surgical-edits
title: Eight short behavioral instructions for `_common.md` / global CLAUDE.md: ask-vs-proceed criterion, line-level surgical changes, fix the cause not the test, handoff-resume checks, no identical retry, outcome/nonGoals, lockfile regeneration, review-finding triage
source: "/forge scout — top-starred Claude Code config repos (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [rules, claude-md, prompting]
tested_in: []
incorporated_in: []
replaced_by: null
effectiveness: null
error_type: null
---

## Description
Across FerroxLabs/agents-md, multica-ai/andrej-karpathy-skills, soumatheusgomes/vibe-coding-toolkit, shinpr/claude-code-workflows, michaelshimeles/rstack and OneRedOak/claude-code-workflows the only instructions dotforge lacks are: (1) "Ask before proceeding when the request has two plausible interpretations and the choice materially affects the output; proceed without asking when the ambiguity can be resolved by reading the code or running a command" — resolves the tension between Karpathy's "if uncertain, ask" and the global "Autonomy" rule; (2) "Every changed line should trace directly to the user's request / remove imports, variables, functions that YOUR changes made unused / don't remove pre-existing dead code unless asked / match existing style" — dotforge only has the file-level "modify only strictly necessary files"; (3) "If the verification fails, fix the cause, not the test" (stacks/tdd says "fix the code or the test", weaker); (4) "When resuming from a handoff, check actual files, Git state, checks, and processes" + "A blocker stops only dependent tasks" + "Do not repeat an identical attempt without new evidence" → `template/rules/context-continuity.md`; (5) treat user-written exclusions (nonGoals) as out of scope, escalate only if the agreed outcome or exclusions must change → `agents/implementer.md`, `agents/architect.md`; (6) `<!-- forge:decisions -->` section in `CLAUDE.md.tmpl` for settled decisions so Claude does not relitigate them; (7) "Resolve lockfile conflicts by regenerating, never by hand-merging" → node/react stacks; (8) review-finding triage: "Do not upgrade solely because a bot asserted a problem / Disagreement is allowed; an unexplained omission is not" → `agents/code-reviewer.md`. Total ≈150 words of always-loaded text.

## Evidence
FerroxLabs `AGENTS.md` §4, §8; Karpathy `CLAUDE.md` §1, §3; vibe-toolkit `templates/AGENTS.md.template` § Execution continuity; shinpr `skills/requirement-convergence/SKILL.md`; rstack `AGENTS.md`; OneRedOak `guides/orchestration-layer/templates/review-triage.md`; CCDK `templates/CLAUDE.md` §3. Counter-evidence: drona23 `benchmark/SEMANTIC.md` shows anti-sycophancy lines are a measured no-op in one-shot (baseline already 0%), so this batch must be evaluated with `docs/v3/EVAL-METHOD.md` arms before being declared effective.

## Impact on dotforge
- `template/rules/_common.md` § Scope + § Testing; `global/CLAUDE.md.tmpl` § Principles
- New `template/rules/context-continuity.md` (globs: **/*)
- `agents/implementer.md`, `architect.md`, `code-reviewer.md`
- `stacks/node-express`, `stacks/react-vite-ts` rules
- Blocked on the open worktree that refactors `.claude/rules/` (task "rules lazy refactor") — coordinate, do not duplicate

## Decision
Pending — captured from the 2026-11-04 scout (23 repos). Items 1–2 of the same scout shipped as v4.8.1, item 4 as v4.9.0; item 3 (expanded deny lists) was explicitly declined by the user.
