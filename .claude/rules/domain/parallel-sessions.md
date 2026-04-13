---
globs: "**/agents/*.md,**/rules/agents.md,**/CLAUDE.md"
description: "Top-level session parallelism — worktrees, fork, teleport — distinct from subagent delegation"
domain: claude-code-engineering
last_verified: 2026-04-13
---

# Parallel Sessions

Two orthogonal axes of parallelism: (a) **subagents** — isolated context, shared main-session scope (see `agent-orchestration.md`); (b) **top-level sessions** — separate Claude instances, independent terminals, separate working trees. Use this rule for (b).

## When to parallelize at the session level

- Independent features or bugfixes that should not share a working tree
- Long-running tasks where you want to keep iterating on something else in parallel
- Experiments you may want to throw away without polluting main history
- Verification passes: one session edits, another reviews in a clean worktree

## Worktree isolation

- `claude --worktree <name>` / `-w <name>`: creates isolated worktree at `<repo>/.claude/worktrees/<name>`. Auto-generated name if omitted
- `claude -w feature-x --tmux`: also creates a tmux session (iTerm2 native panes when available, `--tmux=classic` for traditional)
- Each worktree has its own branch, its own `.claude/session/`, and does not see other worktrees' in-flight edits

## Session handoff

- `--fork-session`: resume with a new session ID instead of reusing the original. Use with `--resume` or `-c` to clone a session's history without touching the original
- `--teleport`: resume a web session (claude.ai/code) in the local terminal
- `--remote "<task>"`: spawn a new web session from CLI
- `claude --from-pr <n>`: resume sessions linked to a GitHub PR (auto-linked when created via `gh pr create`)

## Fast-start flags

- `--bare`: skip auto-discovery (hooks, skills, plugins, MCP, auto memory, CLAUDE.md). Sets `CLAUDE_CODE_SIMPLE`. Use for scripted calls or SDK cold starts — up to 10× faster
- `--add-dir <path>`: grants file access but NOT `.claude/` discovery. Exception: `.claude/skills/` IS loaded from added dirs (live change detection). Other config (agents, commands, rules) is ignored
- `--agent <name>`: override the agent setting for the session
- `--agents '<json>'`: define subagents inline via JSON (same fields as frontmatter plus `prompt`). Useful for ad-hoc one-off agents without a file
- `--setting-sources user,project,local`: filter which scopes load. Use for deterministic tests
- `--teammate-mode auto|in-process|tmux`: how agent-team teammates display. `in-process` = same pane, `tmux` = split terminals
