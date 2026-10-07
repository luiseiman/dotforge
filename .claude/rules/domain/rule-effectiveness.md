---
globs: "**/rules/*.md,**/stacks/*/rules/*"
description: "Rule design, glob patterns, and effectiveness measurement"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Rule Effectiveness

## Frontmatter fields (complete, source-verified)

| Field | Values | Effect |
|-------|--------|--------|
| `globs:` | CSV glob patterns | Eager loading at session start |
| `paths:` | Unquoted CSV only | Lazy loading with `alwaysApply: false` |
| `model` | `haiku`, `sonnet`, `opus`, `fable`, full ID, `inherit` | Pin model for skill/command/agent execution. Honored on pinned-default models since v2.1.259 (was silently ignored); `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` overrides it for agents |
| `effort` | `low`, `medium`, `high`, `xhigh`, `max`, integer | Thinking level; `xhigh` Opus/Fable-only. Honored on pinned-default models since v2.1.267; capped by `maxEffortLevel` |
| `omitClaudeMd` | boolean (agents) | Skip user/project/local CLAUDE.md in the subagent context (v2.1.271+) |
| `maxTurns` | integer (agents) | Stop the subagent after N turns; output marked partial, resumable via `SendMessage` (v2.1.246+) |
| `context` | `inline`, `fork` | Execute inline or fork to subagent |
| `agent` | agent type string | Sub-agent type when `context: fork` |
| `allowed-tools` | tool name filter | Restrict available tools |
| `disallowed-tools` | tool name filter | (v2.1.152+) Remove tools from the model while the skill/command is active. Companion to `allowed-tools`. Pattern for read-only analytical skills: `disallowed-tools: [Bash, Write, Edit]` |
| `user-invocable` | boolean | Show as slash command |
| `disable-model-invocation` | boolean | Skill only invocable by the user, not the model (v2.1.111+). Use for destructive or gated commands after v2.1.108 (model can self-invoke slash commands) |

## Loading behavior

- `globs:` — always works, loads eagerly at session start. Preferred for lightweight rules
- `paths:` — ONLY unquoted CSV. NEVER quoted strings or YAML arrays (fail silently). Requires `alwaysApply: false`
- Only _common.md is allowed without frontmatter (always loaded)
- System prompt has static (cached) and dynamic (per-turn) boundary — rules land in dynamic section

## Design constraints

- Max 50 lines per rule file; split if longer
- Skill description cap: 1,536 chars (raised from 250 in v2.1.105). Front-load key use case
- Each rule: what it covers, clear patterns, common mistakes
- Rule coverage = files matching ≥1 rule glob / total rules
- Classification: Active (>50%), Occasional (10-50%), Inert (<10%) — prune inert rules
- Error promotion: 3+ occurrences → derive rule
- Stack rules: stacks/{name}/rules/ with settings.json.partial
- Domain rules: .claude/rules/domain/ — project-owned, never touched by sync

## Runtime placeholders in skill content (v2.1.120+)

Skill markdown body (not just frontmatter) supports `${CLAUDE_EFFORT}` — resolves at runtime to the active effort tier (`low|medium|high|xhigh|max`). Lets one skill scale depth without forking:

```markdown
Run audit at ${CLAUDE_EFFORT} depth. low = file presence; high = content + cross-checks.
```

Pair with explicit `effort:` frontmatter when a skill MUST run at a fixed tier; omit for caller-driven depth.

## Settings fields worth knowing (beyond permissions)

- `availableModels` — restrict the model picker to a subset (project policy)
- `effortLevel` — persist effort across sessions (vs the session-only `--effort` flag)
- `defaultShell` — `bash | powershell` at the settings level (cross-platform projects)
- `viewMode` — `default | verbose | focus` default transcript view
- `enableWeakerNestedSandbox` — Docker-friendly relaxed sandbox
- `pluginTrustMessage` — custom plugin trust prompt warning

For managed-scope (enterprise) variants, see `permission-model.md` Enterprise managed settings.

## System prompt conflicts to override

These are hardcoded in Claude Code's system prompt — rules must use strong language to counter:
- "DO NOT ADD ANY COMMENTS" — override with "ALWAYS add docstrings"
- "fewer than 4 lines" response limit — override with "provide detailed explanations"
- "Use TodoWrite VERY frequently" — only present on models that still ship the todo tools (≤ Opus 4.7 / Sonnet 4.6 / Haiku 4.5); absent on Opus 4.8+, Sonnet 5+, Fable unless `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` (v2.1.268)
