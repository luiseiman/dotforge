---
globs: "**/agents/*.md,**/rules/agents.md"
description: "Agent delegation patterns and team coordination"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Agent Orchestration

## Subagent architecture (source-verified)

- Each subagent gets independent context window — genuinely isolated from main thread
- Full tool access: Bash, Edit, Write, Read, Glob, Grep, etc.
- Fork subagents share parent prompt cache (Anthropic caching API) — saves tokens
- Max 10 concurrent tool executions across all agents (`gW5 = 10`)
- `shouldAvoidPermissionPrompts: true` for background agents (auto-deny, no UI)
- **Sub-agent nesting: default depth 3 (v2.1.219+)**: `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` overrides (`=1` disables nesting). History: single-level until v2.1.172, up to 5 in v2.1.172–218, 3 since v2.1.219. Forks at the limit cannot spawn further. **20 concurrent running subagents** by default (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`, v2.1.217; lifted while ultracode is on). The 200-per-session spawn cap was removed in v2.1.224 — lifetime count is unlimited. Token cost compounds geometrically — a 3-level chain with fanout=3 = up to 27 leaf agents. Use nesting only when each level has a distinct concern (e.g. Lead → 3 perspective leads → 3 specialists each). For flat fan-out prefer `/workflows` which is more visible and budget-trackable

## Task types

- `local_agent` — sub-agent via AgentTool (standard delegation)
- `remote_agent` — remote execution
- `in_process_teammate` — shared memory (Coordinator mode)
- `dream` — auto-dream background memory consolidation

## Background by default + restricted tool set (v2.1.198+)

Subagents run in the BACKGROUND by default. Foreground only when Claude needs the result before continuing. Background subagents get a **restricted built-in tool set** regardless of frontmatter `tools:` — tools outside the allowlist are SILENTLY removed with no error unless it leaves `tools:` empty:

**Background-safe built-in tools**: Read, Grep, Glob, LSP (v2.1.280+), Bash, PowerShell, Edit, Write, NotebookEdit, WebFetch, WebSearch, TodoWrite, Skill, ToolSearch, EnterWorktree, ExitWorktree, Monitor, TaskStop, SendMessage, SubagentHandoff, Artifact. MCP tools preserved. Everything else removed.

**Todo/task tools are model-gated**: `TodoWrite`, `TaskCreate/Get/Update/List` exist only on Claude 3.x, Opus 4.0–4.7, Sonnet 4.0–4.6, Haiku 4.5 (v2.1.233/268). On Opus 4.8+, Sonnet 5+, Fable they are absent unless `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`. `TaskOutput` removed (v2.1.277). Any hook or behavior keyed on these tools is inert on current models (dotforge `respect-todo-state` disabled in v4.4.0).

Foreground subagents keep the broader tool set. Forks skip both filters (fork inherits parent's exact pool).

dotforge implications:
- Audit `agents/*.md` — architect (may need EnterPlanMode/ExitPlanMode), security-auditor (may need AskUserQuestion), any agent listing tools outside the allowlist gets silent removal in background mode
- If an agent MUST have foreground tools, set `background: false` in frontmatter to force foreground execution
- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` kills background entirely
- Monitor watches always carry a deadline (max 30 min, 10 min in `-p`); the `persistent` option was removed (v2.1.271). Background Bash/PowerShell in unattended `-p`/SDK/CI/cloud sessions stop after 30 min by default, 2 h max (v2.1.285/288); interactive sessions are exempt

## Frontmatter and spawn additions (v2.1.232–v2.1.281)

- **Fork mode on by default** in interactive sessions (v2.1.232; `CLAUDE_CODE_FORK_SUBAGENT=1` no longer needed). `/subtask` replaced `/fork` (v2.1.212). Forks inherit the exact parent tool pool and keep the parent's `plan`/`dontAsk` mode. Interactive non-teammate spawns run in the background by default
- `omitClaudeMd: true` (v2.1.271) — subagent skips user/project/local CLAUDE.md (managed still loads; `.claude/rules/` path-scoped files skip too). dotforge sets it on `researcher` only — `test-runner` needs the project's build/test commands from CLAUDE.md
- `maxTurns: N` (v2.1.246) — output marked partial at the limit with a hint to continue via `SendMessage`; resume, never respawn
- `experimental.cacheTtl: "5m"|"1h"` (v2.1.248) per agent; settings `promptCacheTtl` / `subagentPromptCacheTtl` (v2.1.243) keep the main conversation at 1h while subagents stay at 5m. Experimental — not set on dotforge agents yet
- `name` validated (no `:` or leading `-`, v2.1.218); files starting with a UTF-8 BOM now load (v2.1.239); `--agents` accepts a JSON file path with `-p` (v2.1.281) and is validated at startup (v2.1.242)
- Model resolution: per-invocation `model` → definition `model` → `CLAUDE_CODE_SUBAGENT_MODEL` → main. Family alias (`opus`) resolves to main's model when same family (v2.1.251). **`CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (v2.1.257) overrides every pin** — check it is unset before trusting `model: haiku` cost assumptions
- Results reach the main agent under a marker header; in auto mode through a classifier-reviewed hand-back call (v2.1.271/277). Sibling roster is injected when `SendMessage` is in `tools` (v2.1.206). Teammates use the leader's model — the "Default teammate model" setting was removed (v2.1.234). In-process teammate results carry `agent_id` (agent ID) and `teammate_id` (`name@team`, v2.1.290)
- Combined subagent `description` text should stay under ~15K tokens (docs, v2.1.296) — it is injected into every turn's delegation prompt

## Subagent output scanning (v2.1.210+, prompt-injection defense)

Claude Code scans every subagent's final report BEFORE the main conversation reads it. Two automatic transformations:

1. **Backslash insertion**: text imitating Claude Code output (`<system-reminder>` tags, lines starting with `Human:`/`Assistant:`) gets a backslash inserted so it reads as ordinary text.
2. **Marker line**: prepends `[harness: subagent output matched instruction-shaped pattern(s):` when the report imitates a `<system-reminder>` tag or mentions permission settings like `bypassPermissions` or `--dangerously-skip-permissions`.

Defense against hostile content the subagent read (files, URLs, tool output). NOT a substitute for restricting subagent capability (`tools:` allowlist, `permissionMode`, `disallowedTools`) — downstream tool calls the marked report might steer Claude toward still go through the session's permission checks and sandboxing.

## Subagent frontmatter hooks require workspace trust (v2.1.218+)

Project-level subagent `hooks:` blocks in `.claude/agents/*.md` now require workspace-trust acceptance BEFORE they fire. Non-interactive sessions (`-p`, SDK, CI) silently SKIP untrusted frontmatter hooks — subagent still runs, hooks are inert, debug log records the skip.

Trust scope:
- `.claude/agents/*.md` project-level → workspace-trust gate applies to `hooks:` (v2.1.218) AND inline `mcpServers:` (v2.1.238)
- `--add-dir` folders outside trusted workspace → separate trust required; nested git repos do not inherit trust from a parent (v2.1.232)
- `~/.claude/agents/` user-level → no trust needed (files you wrote)
- `--agents` inline JSON or file path → no trust needed (explicit caller input)
- Helpers (`headersHelper`, etc.) from project/plugin/agent files run without inherited credential env vars (v2.1.248)

Permission-mode inheritance (v2.1.267): a subagent's `permissionMode: bypassPermissions` works only if the main session also runs bypass, and honors an org policy that disables bypass (v2.1.223). If main is in `bypassPermissions`, `acceptEdits`, or `auto`, the subagent inherits that mode regardless of its own `permissionMode`. Forks keep the parent's `plan`/`dontAsk` mode and cannot exit plan mode (v2.1.284/285). PreToolUse auto-allow hooks no longer bypass tool restrictions in background agent tasks (v2.1.222). dotforge agents set no `permissionMode` — they inherit.

Pre-v2.1.218: frontmatter hooks could run from untrusted folders including in non-interactive sessions — the injection surface a hostile PR could exploit (malicious `agents/reviewer.md` frontmatter hook fires on next Claude session in the checkout). Post-v2.1.218 that path is closed.

CI implication: pipelines using `claude -p` with project-level agent frontmatter hooks silently skip them. Migrate hooks to `~/.claude/agents/` or `--agents` inline JSON for CI usage.

## Delegation rules

- Decision tree: 1-file fix → direct. Research-heavy → researcher. Code+tests → implementer
- Multi-component (>3 files, >2 concerns) → Agent Team
- Agent Team: Lead (coordinates, does NOT implement) + max 3-4 teammates
- Each teammate MUST use isolation: "worktree" (confirmed by EnterWorktree/ExitWorktree tools)
- Sequential chaining: researcher → architect → implementer → test-runner → code-reviewer
- NEVER spawn new agent for follow-ups — use SendMessage({to: agentId}) to continue
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` env var: enables native Agent Teams (research preview, requires Opus)

## Memory and lifecycle

- Memory agents: architect, implementer, code-reviewer, security-auditor, session-reviewer (persist in .claude/agent-memory/)
- Transactional agents: researcher, test-runner (execute and report, no memory)
- Dynamic loading from `~/.claude/agents/` — custom agent definitions auto-discovered
- Subagent output must not exceed 30% of main context — always structured summaries
- Always verify subagent output (run tests/lint) before declaring task done
- `/reload-skills` slash command (v2.1.152+) re-scans skill directories in the current session without restart — pair with the SessionStart hook field `reloadSkills: true` if a hook installs skills

## Agent-scoped hooks (frontmatter `hooks:`)

Agents can declare `PreToolUse`, `PostToolUse`, and `Stop` hooks in their frontmatter, scoped to that subagent's lifecycle. Hooks fire ONLY while that subagent is the active executor — not globally — enabling per-role guardrails without polluting `.claude/settings.json`.

Use cases per dotforge agent role:

| Agent | Event | Purpose |
|-------|-------|---------|
| `code-reviewer` | PostToolUse on `Edit\|Write` | Run lint/typecheck; block on errors via `decision: "block"` (or `continueOnBlock: true` for self-healing) |
| `security-auditor` | PreToolUse on `Bash\|Write\|Edit` | Read-only enforcement — auto-deny mutations (defense-in-depth atop `allowed-tools:`) |
| `test-runner` | PostToolUse on `Bash` | Parse test results from output; persist failures into agent-memory |
| `implementer` | Stop | Refuse exit unless tests passed for files touched this session |
| `researcher` | PreToolUse on `Edit\|Write` | Belt-and-suspenders deny (already restricted via `allowed-tools:`) |
| `architect` | PreToolUse on `Edit\|Write` | Plan-mode enforcement — block until plan accepted |
| `session-reviewer` | PostToolUse | Capture corrections/patterns for `/forge insights` feeding |

Composition with global hooks: agent hooks **merge** with `.claude/settings.json` hooks — both run. Static deny rules cannot be removed by agent-scoped hooks. Schema mirrors the top-level `hooks` object shape.

**Status in dotforge (2026-06-01)**: documented architecturally here; not yet wired into `agents/*.md` files pending empirical schema verification against upstream docs. When adopting, validate against `code.claude.com/docs/en/sub-agents` and test in `agents/test-runner.md` first (lowest blast radius).

## OpenTelemetry instrumentation (v2.1.139+, v2.1.145+)

- `claude_code.llm_request` spans carry `agent_id` and `parent_agent_id` attributes (v2.1.139+)
- `claude_code.tool` spans carry the same attributes since v2.1.145 — pre-v2.1.145 tool spans lacked agent attribution
- Trace parenting fixed in v2.1.145: background subagent spans correctly nest under the dispatching Agent tool span (before, they were roots — broke the agent-tree visualization)
- Combined effect: distributed tracing of agent trees is now complete
- **v2.1.161 metric label expansion**: `OTEL_RESOURCE_ATTRIBUTES` values are now included as labels on metric datapoints. Slice usage metrics by team, repo, or any custom dimension. Pre-fix only span attributes carried these — metrics were unsliceable.
- **v2.1.161 tool parameter capture**: `tool_decision` events include `tool_parameters` when `OTEL_LOG_TOOL_DETAILS=1`. Opt-in: parameter values may contain secrets, so disabled by default. Use for forensic replay of denied tool calls.
- **v2.1.193 `claude_code.assistant_response` log event**: new OTel log event containing the assistant's response text. Enables auditing what was emitted to the user (compliance, redaction QA, forensic review). **PII risk**: response text may include user data, code with secrets, or internal IDs that leaked from tool output — opt-in only via OTel logger config, never default-on for sessions handling regulated data unless the OTel sink is itself compliant.

## Agent Teams: implicit team (v2.1.178+)

With `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, every session now has one implicit team — no need to declare a Lead + teammates structure manually for ad-hoc fan-out. Lowers the activation cost for Agent Teams (previously required explicit team scaffolding). Composes with sub-agent nesting: a teammate can recurse into its own sub-agents up to the spawn depth (default 3, `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`).

dotforge implication: `.claude/rules/agents.md` Agent Teams criteria still apply (≥3 components, ≤4 teammates, worktree isolation). The implicit team just removes ceremony — the design constraints don't relax.

## `claude agents --json waitingFor` (v2.1.162+)

`claude agents --json` now includes a `waitingFor` field per session showing the current blocker — values like `permission_prompt`, `deferred_tool`, `user_input`, `network`, `null` (running). Use for status-bar widgets, tmux session pickers, or auto-attach scripts that wake the user only when a session needs them. Combines with the `done/total` agent count (v2.1.161+) to give a complete picture without attaching.

## Single-file grep satisfies read-before-edit (v2.1.160+)

Single-file `grep`/`egrep`/`fgrep` now counts as having "read" the file for the Edit precondition. Pre-fix, even after grepping a file, an Edit would still trigger the "Read this file first" requirement. Multi-file searches still don't satisfy the check (no single file is considered fully read).

Implication for `researcher` agent pattern: a focused grep for the target symbol in a specific file is sufficient context to hand off to `implementer` without an intermediate full Read — saves tokens on large files.

## Related: top-level parallelism

Subagents share the main session's working tree. For independent top-level Claude instances (worktrees, `--fork-session`, `--teleport`, `--bare`, `--add-dir`, `--agents` inline JSON), see `parallel-sessions.md`.

## Slash command priority (collision risk)

bundledSkills > builtinPluginSkills > skillDirCommands > workflowCommands > pluginCommands > pluginSkills > COMMANDS()

Skills installed via dotforge can shadow built-in commands if names collide — be intentional about naming.

## Model self-invocation of slash commands (v2.1.108+)

Since v2.1.108, the model can invoke slash commands directly in its tool-use loop — previously user-only. Implication for skill design:

- Destructive or state-mutating commands (reset, unregister, capture) should set `disable-model-invocation: true` (v2.1.111+) to stay user-gated — since v2.1.222 the runtime hard-refuses model invocation of such skills with an "ask the user to run it" message
- `user-invocable: true` by itself no longer restricts the model — both flags needed for full gating
- Audit `global/commands/` and `skills/*/SKILL.md` when introducing new commands: ask "do I want the model to self-trigger this?"
