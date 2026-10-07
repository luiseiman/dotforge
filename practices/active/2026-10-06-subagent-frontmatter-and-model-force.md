---
id: practice-2026-10-06-subagent-frontmatter-and-model-force
title: Subagent frontmatter additions (omitClaudeMd, maxTurns, cacheTtl), CLAUDE_CODE_SUBAGENT_MODEL_FORCE overrides model pins, fork mode default (v2.1.232–v2.1.281)
source: "/forge watch — docs/en/sub-agents + CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [subagents, agents, model-routing, context, cost]
tested_in: []
incorporated_in: ["agents/researcher.md", ".claude/rules/domain/agent-orchestration.md", ".claude/rules/agents.md", ".claude/rules/domain/rule-effectiveness.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
- Frontmatter: `omitClaudeMd: true` skips user/project/local CLAUDE.md (v2.1.271 — managed still loads); `maxTurns` marks output partial at limit with a `SendMessage` continue hint (v2.1.246); `experimental.cacheTtl: "5m"|"1h"` per-agent prompt cache (v2.1.248); settings `promptCacheTtl` / `subagentPromptCacheTtl` (v2.1.243); `color`; `initialPrompt` (for `--agent` main session); `name` validated — no `:` or leading `-` (v2.1.218); UTF-8 BOM files now load (v2.1.239).
- Model resolution: per-invocation `model` → definition `model` → `CLAUDE_CODE_SUBAGENT_MODEL` → main. Family alias (`opus`) resolves to main's model if same family (v2.1.251). `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (v2.1.257) applies env/main model to EVERY subagent, **ignoring per-spawn and definition `model:`** — silently defeats dotforge haiku/sonnet/opus pins.
- Fork mode on by default in interactive (v2.1.232; `CLAUDE_CODE_FORK_SUBAGENT` no longer needed); `/subtask` replaces `/fork` (v2.1.212); forks share exact parent tool pool; background tool set adds `LSP` (v2.1.280) and `SubagentHandoff`. Interactive non-teammate spawns run in background by default. Built-in Explore now "Opus (or main)", skips CLAUDE.md + git status. `--agents` accepts a JSON file path with `-p` (v2.1.281), validated at startup (v2.1.242). `--append-subagent-system-prompt(-file)` (v2.1.205/261, `-p` only). Combined subagent descriptions should stay <15K tokens (docs cite v2.1.296 — docs are ahead of CHANGELOG head 2.1.291).
- Results: subagent output reaches main under a marker header; in auto mode via a classifier-reviewed hand-back call (v2.1.271/277). Sibling agent roster injected when `SendMessage` in tools (v2.1.206). "Default teammate model" setting removed — teammates use leader's model (v2.1.234). `agent_id` for in-process teammates now the agent ID, `name@team` moves to `teammate_id` (v2.1.290).

## Evidence
0 hits for `omitClaudeMd`, `maxTurns`, `cacheTtl`, `CLAUDE_CODE_SUBAGENT_MODEL`, `SubagentHandoff`, `/subtask`, `fork mode`. `agents/researcher.md` / `test-runner.md` load full CLAUDE.md hierarchy they rarely need.

## Impact on dotforge
- `agents/researcher.md`, `agents/test-runner.md`: add `omitClaudeMd: true` + `maxTurns` (transactional agents)
- `agents/architect.md`, `security-auditor.md`: `experimental.cacheTtl: "1h"` for long audits
- `.claude/rules/model-routing.md`, `model-ids.md`: `_FORCE` warning + resolution order
- `.claude/rules/domain/agent-orchestration.md`: fork default, `/subtask`, background tool set, result marker, teammate fields
- `.claude/rules/agents.md`: SendMessage follow-up rule covers `maxTurns` partial output

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.6.0 (/forge update, catalogue block).
