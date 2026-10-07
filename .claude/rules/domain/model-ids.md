---
globs: "**/agents/*.md,**/CLAUDE.md"
description: "Model IDs and agent defaults for Claude Code subagent instantiation"
domain: claude-code
last_verified: 2026-10-06
---

# Model IDs (October 2026)

| Tier | Model ID | Context | Max output | Default since |
|------|----------|---------|------------|---------------|
| fable | `claude-fable-5-1` | 1M | TBD | v2.1.257 (Fable 5 `claude-fable-5` since v2.1.170) |
| opus | `claude-opus-5-5` | 1M | 128K tokens | v2.1.280 (Opus 5 `claude-opus-5` v2.1.219; Opus 4.8 v2.1.154) |
| sonnet | `claude-sonnet-5-5` | 1M | 64K tokens | v2.1.284 (Sonnet 5 `claude-sonnet-5` v2.1.195–201) |
| haiku | `claude-haiku-4-5-20251001` | 200K | 8K tokens | — |

Pricing per MTok in/out: Opus 5.5 $4/$20 · Sonnet 5.5 $2/$10 · Fable 5.1 $10/$50. Pro + Team Standard default model flipped Sonnet → Opus in v2.1.280. Legacy pins (`claude-opus-4-8`, `claude-opus-4-7`, `claude-sonnet-4-6`) still resolve — use only to reproduce benchmarks predating v2.1.219 (2026-07-24).

1M context is the default for Opus 4.7+, Sonnet 5+, Fable on every provider incl. Bedrock, Vertex, Foundry, gateways, custom `ANTHROPIC_BASE_URL` (v2.1.280). `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` holds every native-1M model to 200K (v2.1.223). Unknown model IDs get an auto-compact cap; `CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1` restores the old behavior. Auto-compact: Sonnet 5+ near 967K (full 1M, v2.1.233), Opus/Fable shortly before 1M (v2.1.260).

`ANTHROPIC_DEFAULT_MODEL` sets the model new sessions start on (v2.1.236). `modelPicker` (v2.1.242; user/managed/`--settings` only, whole-value, ignored in project/local) controls the `/model` rows; `modelPricing` managed multiplier up to 10x. `/effort` saves a per-model default (v2.1.252). Print mode emits `[claude-code:unrecognized_model]` on stderr for unknown IDs, mapped via `modelOverrides` (v2.1.233). `CLAUDE_CODE_SUBAGENT_MODEL` sets the default subagent model; `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (v2.1.257) overrides every per-spawn and frontmatter `model:` — silently defeats dotforge agent pins.

**Fable 5.1 (v2.1.257+, 1M)** is a Mythos-class model with capabilities exceeding any prior generally-available Claude. Treat as the top tier for the highest-stakes work (architecture across irreversible blast radius, security audits on production-tier projects, complex novel problems). Do NOT default agents to fable without explicit cost justification ($10/$50).

Default agents: opus → architect, security-auditor. sonnet → implementer, code-reviewer, session-reviewer. haiku → researcher, test-runner.

## Built-in `Explore` inherits main model (v2.1.198+, BREAKING cost)

Pre-v2.1.198: built-in `Explore` subagent always ran on Haiku (intentional cost floor for read-only search work). Post-v2.1.198: inherits main conversation's model, capped at Opus on the Claude API. Third-party providers (Bedrock/Vertex/Foundry/Mantle) inherit main model directly (no cap).

A session on Opus 4.7/4.8 pays Opus rates for exploration triggered by "find X", "search for Y", "explore the codebase" — Claude routinely delegates to built-in Explore for those.

**dotforge's custom `researcher` agent is NOT affected** — it pins `model: haiku` explicitly in frontmatter. But the built-in Explore path bypasses `.claude/rules/model-routing.md` since it isn't a custom agent.

Overrides:
- Ship `~/.claude/agents/Explore.md` with `model: haiku` — shadows the built-in and restores old cost profile
- `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1` — kill built-in Explore + Plan entirely (Claude reads files directly with Read/Grep)

Production-tier projects on Opus 4.7/4.8: audit session usage; if `agents --json` shows Explore invocations at Opus cost, decide between override or disable.

## Effort levels (v2.1.111+)

Five core tiers: `low` < `medium` < `high` < `xhigh` < `max`. `xhigh` is Opus/Fable-exclusive — Sonnet/Haiku fall back to `high`. **`ultracode` is an independent toggle since v2.1.284** (`/effort` → Tab, or `/effort ultracode on|off`): it no longer forces `xhigh` and stays on at any effort level; the CLI flag `--effort ultracode` (v2.1.203+) still requests `xhigh` + ultracode together. Session-only. With it on, each substantive request can spawn several workflows in sequence (understand → change → verify). Pairs with `workflow-and-ultracode-policy.md`: `production`/`heavy` tier → `/effort xhigh` + `/effort ultracode on` at session start. Global default is `effort: high` (v2.1.94). `maxEffortLevel` setting (v2.1.267, top-level or per model under `modelSettings`) caps effort on every provider — the lowest cap from any scope wins. Frontmatter `effort:`/`model:` on skills, commands and agents is honored on pinned-default models since v2.1.259/267 (was silently ignored before) — `agents/security-auditor.md` `effort: max` is now live.

- Skills/agents WITHOUT explicit `effort:` consume more tokens and run slower
- Pin `effort: low` in `agents/researcher.md` and `agents/test-runner.md` to keep them cheap
- Consider `xhigh` (not `max`) for `security-auditor`/`architect` on complex tasks — deeper reasoning without the cost jump of max
- Benchmark baselines computed before 2026-04-07 are no longer comparable
- For deterministic transformations (rename, reformat) explicit `effort: low` is recommended

## `/effort` persistence (v2.1.162+)

After picking a level via `/effort`, the picker confirms "this will be the default for new sessions" — the choice persists across new sessions (not just the current one). Pre-v2.1.162 the persistence behavior was silent and confused users into re-setting effort each session. The picker is now explicit about the scope. Use `--effort <level>` per-invocation when you need a one-off override without mutating the persistent default.

## `/model` is per-session by default (v2.1.144+)

- `/model <id>` changes the model **for the current session only**. Previously (pre-v2.1.144) it mutated `~/.claude/settings.json` so the choice persisted.
- To set the persistent default: open the picker with `/model` (no args), select the model, press `d`
- CI implication: prefer `--model <id>` flag on each `claude` invocation rather than expecting `/model` to leak across processes
- Trading workflow implication: switch one bot session to Opus 4.7 for a high-stakes job without affecting the rest

## Fast mode (Opus toggle)

- `/fast` toggles a lower-latency variant of the active Opus model mid-session; works in remote sessions and falls back to standard speed when unavailable (v2.1.257/271/286)
- Opus 5 / 5.5 fast mode: **$10/$50 per MTok** (v2.1.219+). Opus 4.7 removed from fast mode in v2.1.219 — `/fast` applies only to Opus 5.x and 4.8
- History: default flipped to Opus 4.7 (v2.1.142), Opus 4.8 (v2.1.154, 2x rate for 2.5x speed), Opus 5 (v2.1.219), Opus 5.5 (v2.1.280). `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` removed 2026-06-01 — pre-flip benchmarks cannot be reproduced via env var; re-baseline against the current default

> Claude 3 Haiku deprecated — retiring April 19, 2026. Use claude-haiku-4-5 only.
> Update this table when Anthropic releases new model versions.
