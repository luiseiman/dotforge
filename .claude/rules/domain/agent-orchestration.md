---
globs: "**/agents/*.md,**/rules/agents.md"
description: "Agent delegation patterns and team coordination"
domain: claude-code-engineering
last_verified: 2026-04-08
---

# Agent Orchestration

## Subagent architecture (source-verified)

- Each subagent gets independent context window — genuinely isolated from main thread
- Full tool access: Bash, Edit, Write, Read, Glob, Grep, etc.
- Fork subagents share parent prompt cache (Anthropic caching API) — saves tokens
- Max 10 concurrent tool executions across all agents (`gW5 = 10`)
- `shouldAvoidPermissionPrompts: true` for background agents (auto-deny, no UI)

## Task types

- `local_agent` — sub-agent via AgentTool (standard delegation)
- `remote_agent` — remote execution
- `in_process_teammate` — shared memory (Coordinator mode)
- `dream` — auto-dream background memory consolidation

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

## Related: top-level parallelism

Subagents share the main session's working tree. For independent top-level Claude instances (worktrees, `--fork-session`, `--teleport`, `--bare`, `--add-dir`, `--agents` inline JSON), see `parallel-sessions.md`.

## Slash command priority (collision risk)

bundledSkills > builtinPluginSkills > skillDirCommands > workflowCommands > pluginCommands > pluginSkills > COMMANDS()

Skills installed via dotforge can shadow built-in commands if names collide — be intentional about naming.
