---
globs: "**/agents/*.md,**/rules/agents.md,**/CLAUDE.md"
description: "Top-level session parallelism — worktrees, fork, teleport — distinct from subagent delegation"
domain: claude-code-engineering
last_verified: 2026-10-07
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
- **Isolation guarantee (v2.1.222)**: a worktree session and every subagent it spawns cannot run destructive git commands against the main checkout, in any session type. `/fork` creates its own worktree (v2.1.221); background sessions hold the worktree lock while they run (v2.1.248); `.worktreeinclude` patterns starting with `**/` work (v2.1.239). `claude rm` refusals print the exact flag to resolve them: `--discard-unpushed <commit>@<worktree-id>` (v2.1.260) or `--force-remove-worktree <worktree-id>` (v2.1.268)
- `-w #<PR>` / `-w <GitHub PR URL>` / `-w <GitLab MR URL>` (v2.1.233) fetches the PR/MR from `origin` and branches the worktree from it

### Lifecycle improvements (2026 changelog)

- **Auto-unlock on agent finish**: Claude-managed worktrees no longer keep the git lock after the spawning agent exits. `git worktree remove`/`git worktree prune` now work without manual `--force`. Pre-fix the lock persisted, causing `'main' is already used by worktree at ...` when trying to `git checkout main` (lived during sync-all 2026-06-01 — TRADINGBOT's `claude/festive-maxwell-a70698` and `heuristic-swartz-65163d` worktrees blocked main checkout)
- **`EnterWorktree` mid-session switching**: a single session can now `EnterWorktree(path)` between Claude-managed worktrees without ending the session. Enables Lead-coordinated workflows where one agent context inspects/merges multiple teammate worktrees sequentially
- **Cleanup hygiene**: after Agent Teams or long-running parallel work, `git worktree list --porcelain | awk '/^worktree/ {print $2}'` discovers stale Claude-managed worktrees; remove with `git worktree remove <path>` (no `--force` needed post-fix)
- Independent from `worktree.bgIsolation: "none"` (v2.1.143) — auto-unlock applies regardless of isolation mode

## Background sessions (v2.1.139+)

Process-level isolation alongside the filesystem-level isolation of `--worktree`. Six surfaces:

- `claude --bg "<task>"`: start a session in the background and return immediately. Prints session ID and management commands. Combine with `--agent <name>` to run a specific subagent
- `claude attach <id>`: attach to a running background session in the current terminal
- `claude logs <id>`: print recent output
- `claude respawn <id>`: restart a stopped session with conversation intact (`--all` restarts every stopped session)
- `claude rm <id>`: remove from the agent-view list
- `claude stop <id>` / `claude kill <id>`: stop a running session

`claude agents` (v2.1.139+, Research Preview) opens the unified agent view showing every session (running/blocked/done). When stdin is piped, the older subagent-listing behavior is preserved.

`claude agents --json` (v2.1.145+) emits live sessions as a JSON array for scripting (tmux-resurrect, custom status bars, session pickers). `/resume` supports background sessions since v2.1.144 — `--bg`-started sessions appear in the picker marked `bg`. `claude agents` rows show `done/total` agent count before the row detail (v2.1.161+) — useful when one fan-out has many subagents to track progress at a glance.

Pick by isolation needed:
- **Worktree** (`--worktree`): separate working tree, separate branch. Best for parallel features that touch the same files
- **Fork session** (`--fork-session`): clone history, separate session ID, same working tree. Best for "what-if" exploration
- **Background** (`--bg`): same working tree, separate context, runs without blocking your shell. Best for long unattended tasks (overnight refactor, batch lint, scheduled audit)

## Disabling bg session worktree isolation (v2.1.143+)

`worktree.bgIsolation` setting in `settings.json`:

- `"auto"` (default): every `--bg` session opens in its own worktree via `EnterWorktree`. Two bg sessions never see each other's in-flight edits
- `"none"`: bg sessions edit the working copy directly. Skip `EnterWorktree` entirely

Set `"none"` only when worktrees are impractical: Bazel monorepos that assume a single root, repos with deep `.gitmodules` chains, build systems that write to the repo root (asset pipelines, codegen). **Risk**: two concurrent bg sessions can clobber each other — there's no automatic isolation. Serialize bg work or use `--worktree` explicitly for the cases that can.

## Configuring sessions dispatched from `claude agents` (v2.1.141-143)

`claude agents` is no longer just a dashboard — it's a launcher. Flags applied at the CLI become defaults for sessions dispatched from the view:

- `--cwd <path>` (v2.1.141) scope to a directory
- `--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir` (v2.1.142) — same surface as interactive `claude`
- `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions` (v2.1.142)
- v2.1.143: detaching to `/bg` preserves the launcher flags. Dispatched bg sessions now honor `permissions.defaultMode` from settings.json (previous versions overrode to `auto`)

For exhaustive flag reference see `cli-flags.md`.

## Session handoff

- `--fork-session`: resume with a new session ID instead of reusing the original. Use with `--resume` or `-c` to clone a session's history without touching the original
- `--teleport`: resume a web session (claude.ai/code) in the local terminal
- `--remote "<task>"`: spawn a new web session from CLI
- `claude --from-pr <n>`: resume sessions linked to a GitHub PR (auto-linked when created via `gh pr create`)

## Fast-start flags relevant to parallelism

- `--bare`: skip auto-discovery (hooks, skills, plugins, MCP, auto memory, CLAUDE.md). Sets `CLAUDE_CODE_SIMPLE`. Use for scripted calls or SDK cold starts — up to 10× faster
- `--add-dir <path>`: grants file access but NOT `.claude/` discovery. Exception: `.claude/skills/` IS loaded from added dirs (live change detection). Other config (agents, commands, rules) is ignored. **Opt-in CLAUDE.md load** (2026): set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to also load `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, and `CLAUDE.local.md` from `--add-dir` paths. Use for shared-config repos where multiple projects pull in common rules from a central directory. `CLAUDE.local.md` honored only if `--setting-sources` includes `local`
- `--agents '<json>'`: define subagents inline via JSON (same fields as frontmatter plus `prompt`). Useful for ad-hoc one-off agents without a file
- `--setting-sources user,project,local`: filter which scopes load. Use for deterministic tests
- `--teammate-mode auto|in-process|tmux`: how agent-team teammates display. `in-process` = same pane, `tmux` = split terminals
