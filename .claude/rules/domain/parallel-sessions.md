---
globs: "**/agents/*.md,**/rules/agents.md,**/CLAUDE.md"
description: "Top-level session parallelism — worktrees, fork, teleport — distinct from subagent delegation"
domain: claude-code-engineering
last_verified: 2026-05-13
---

# Parallel Sessions

Two orthogonal axes of parallelism: (a) **subagents** — isolated context, shared main-session scope (see `agent-orchestration.md`); (b) **top-level sessions** — separate Claude instances, independent terminals, separate working trees. This rule covers (b). For exhaustive CLI flag reference see `cli-flags.md`.

## When to parallelize at the session level

- Independent features or bugfixes that should not share a working tree
- Long-running tasks where you want to keep iterating on something else in parallel
- Experiments you may want to throw away without polluting main history
- Verification passes: one session edits, another reviews in a clean worktree

## Worktree isolation

- `claude --worktree <name>` / `-w <name>`: creates isolated worktree at `<repo>/.claude/worktrees/<name>`. Auto-generated name if omitted
- `claude -w feature-x --tmux`: also creates a tmux session (iTerm2 native panes when available, `--tmux=classic` for traditional)
- Each worktree has its own branch, its own `.claude/session/`, and does not see other worktrees' in-flight edits
- `worktree.baseRef` setting (v2.1.133+): `"fresh"` (default) branches from `origin/<default>`, `"head"` branches from local HEAD. **Subtle versioned breaking**: in v2.1.128–v2.1.132 the default was `head` (carried unpushed commits into new worktrees); v2.1.133 reverted to `fresh`. Set `worktree.baseRef: "head"` if you rely on unpushed work being available to teammates

## Background sessions (v2.1.139+)

Process-level isolation alongside the filesystem-level isolation of `--worktree`. Six surfaces:

- `claude --bg "<task>"`: start a session in the background and return immediately. Prints session ID and management commands. Combine with `--agent <name>` to run a specific subagent
- `claude attach <id>`: attach to a running background session in the current terminal
- `claude logs <id>`: print recent output
- `claude respawn <id>`: restart a stopped session with conversation intact (`--all` restarts every stopped session)
- `claude rm <id>`: remove from the agent-view list
- `claude stop <id>` / `claude kill <id>`: stop a running session

`claude agents` (v2.1.139+, Research Preview) opens the unified agent view showing every session (running/blocked/done). When stdin is piped, the older subagent-listing behavior is preserved.

Pick by isolation needed:
- **Worktree** (`--worktree`): separate working tree, separate branch. Best for parallel features that touch the same files
- **Fork session** (`--fork-session`): clone history, separate session ID, same working tree. Best for "what-if" exploration
- **Background** (`--bg`): same working tree, separate context, runs without blocking your shell. Best for long unattended tasks (overnight refactor, batch lint, scheduled audit)

## Session handoff

- `--fork-session`: resume with a new session ID instead of reusing the original. Use with `--resume` or `-c` to clone a session's history without touching the original
- `--teleport`: resume a web session (claude.ai/code) in the local terminal
- `--remote "<task>"`: spawn a new web session from CLI
- `claude --from-pr <n>`: resume sessions linked to a GitHub PR (auto-linked when created via `gh pr create`)

## Fast-start flags relevant to parallelism

- `--bare`: skip auto-discovery (hooks, skills, plugins, MCP, auto memory, CLAUDE.md). Sets `CLAUDE_CODE_SIMPLE`. Use for scripted calls or SDK cold starts — up to 10× faster
- `--add-dir <path>`: grants file access but NOT `.claude/` discovery. Exception: `.claude/skills/` IS loaded from added dirs (live change detection). Other config (agents, commands, rules) is ignored
- `--agents '<json>'`: define subagents inline via JSON (same fields as frontmatter plus `prompt`). Useful for ad-hoc one-off agents without a file
- `--setting-sources user,project,local`: filter which scopes load. Use for deterministic tests
- `--teammate-mode auto|in-process|tmux`: how agent-team teammates display. `in-process` = same pane, `tmux` = split terminals
