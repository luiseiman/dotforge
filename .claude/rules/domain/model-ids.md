---
globs: "**/agents/*.md,**/CLAUDE.md"
description: "Model IDs and agent defaults for Claude Code subagent instantiation"
domain: claude-code
last_verified: 2026-04-20
---

# Model IDs (April 2026)

| Tier | Model ID | Context | Max output |
|------|----------|---------|------------|
| opus | `claude-opus-4-7` | 1M | 128K tokens |
| sonnet | `claude-sonnet-4-6` | 1M | 64K tokens |
| haiku | `claude-haiku-4-5-20251001` | 200K | 8K tokens |

Default agents: opus → architect, security-auditor. sonnet → implementer, code-reviewer, session-reviewer. haiku → researcher, test-runner.

## Effort levels (v2.1.111+)

Five tiers: `low` < `medium` < `high` < `xhigh` < `max`. `xhigh` is Opus 4.7-exclusive — other models fall back to `high` when xhigh is requested. Global default is `effort: high` (changed v2.1.94, 2026-04-07, was `medium`).

- Skills/agents WITHOUT explicit `effort:` consume more tokens and run slower
- Pin `effort: low` in `agents/researcher.md` and `agents/test-runner.md` to keep them cheap
- Consider `xhigh` (not `max`) for `security-auditor`/`architect` on complex tasks — deeper reasoning without the cost jump of max
- Benchmark baselines computed before 2026-04-07 are no longer comparable
- For deterministic transformations (rename, reformat) explicit `effort: low` is recommended

> Claude 3 Haiku deprecated — retiring April 19, 2026. Use claude-haiku-4-5 only.
> Update this table when Anthropic releases new model versions.
