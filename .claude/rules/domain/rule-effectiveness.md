---
globs: "**/rules/*.md,**/stacks/*/rules/*"
description: "Rule design, glob patterns, and effectiveness measurement"
domain: claude-code-engineering
last_verified: 2026-04-02
---

# Rule Effectiveness

## Frontmatter fields (complete, source-verified)

| Field | Values | Effect |
|-------|--------|--------|
| `globs:` | CSV glob patterns | Eager loading at session start |
| `paths:` | Unquoted CSV only | Lazy loading with `alwaysApply: false` |
| `model` | `haiku`, `sonnet`, `opus`, `inherit` | Pin model tier for rule/skill execution |
| `effort` | `low`, `medium`, `high`, `max`, integer | Thinking level / reasoning depth |
| `context` | `inline`, `fork` | Execute inline or fork to subagent |
| `agent` | agent type string | Sub-agent type when `context: fork` |
| `allowed-tools` | tool name filter | Restrict available tools |
| `user-invocable` | boolean | Show as slash command |

## Loading behavior

- `globs:` — always works, loads eagerly at session start. Preferred for lightweight rules
- `paths:` — ONLY unquoted CSV. NEVER quoted strings or YAML arrays (fail silently). Requires `alwaysApply: false`
- Only _common.md is allowed without frontmatter (always loaded)
- System prompt has static (cached) and dynamic (per-turn) boundary — rules land in dynamic section

## Design constraints

- Max 50 lines per rule file; split if longer
- Each rule: what it covers, clear patterns, common mistakes
- Rule coverage = files matching ≥1 rule glob / total rules
- Classification: Active (>50%), Occasional (10-50%), Inert (<10%) — prune inert rules
- Error promotion: 3+ occurrences → derive rule
- Stack rules: stacks/{name}/rules/ with settings.json.partial
- Domain rules: .claude/rules/domain/ — project-owned, never touched by sync

## System prompt conflicts to override

These are hardcoded in Claude Code's system prompt — rules must use strong language to counter:
- "DO NOT ADD ANY COMMENTS" — override with "ALWAYS add docstrings"
- "fewer than 4 lines" response limit — override with "provide detailed explanations"
- "Use TodoWrite VERY frequently" — cannot be suppressed easily
