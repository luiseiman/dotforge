---
globs: "**/agents/*.md,**/rules/agents.md,**/CLAUDE.md"
description: "Top-level session parallelism — worktrees, fork, teleport — distinct from subagent delegation"
domain: claude-code-engineering
last_verified: 2026-04-26
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

## Automation / headless flags (print mode, `-p`)

- `--effort low|medium|high|xhigh|max` (v2.1.113): pin effort at startup. Deterministic for benchmarks
- `--max-budget-usd N`: hard cost cap. Exits with error when reached
- `--max-turns N`: hard turn cap
- `--json-schema '{...}'`: validated structured JSON output. See Agent SDK structured outputs
- `--fallback-model <id>`: auto-fallback when default model overloaded
- `--no-session-persistence`: don't save session to disk (can't be resumed)
- `--include-hook-events`: stream all hook events (requires `--output-format stream-json`)
- `--replay-user-messages`: echo stdin back for acknowledgment (stream-json pair)
- `--exclude-dynamic-system-prompt-sections`: move per-machine bits (cwd, env, git status) into first user message — improves prompt-cache reuse across users/machines
- `--init-only` / `--maintenance`: run init/maintenance hooks and exit
- `--input-format text|stream-json` and `--include-partial-messages`: SDK streaming knobs (require `--output-format stream-json`)
- `--strict-mcp-config`: only honor MCP servers from `--mcp-config`, ignore everything else
- `--system-prompt` / `--system-prompt-file` / `--append-system-prompt` / `--append-system-prompt-file`: prompt customization (replace vs append)
- `--tools "Bash,Edit,Read"` (or `""`/`"default"`) restricts built-in tools; `--allowedTools` and `--disallowedTools` apply pattern-matched permission rules
- `--debug-file <path>` / `--debug "api,hooks"`: targeted debug output

## Other CLI flags (interactive)

- `--name`/`-n "label"`: display name for the session (resumable via `claude --resume <name>`); `/rename` changes it mid-session
- `--session-id <uuid>`: explicit UUID for the conversation
- `--remote-control` (`--rc`) / `claude remote-control`: enable Remote Control so the session is also controllable from claude.ai or the Claude app. `--remote-control-session-name-prefix` overrides the hostname-based default
- `--ide`: auto-connect to a running IDE if exactly one is available
- `--init` / `--init-only`: run init hooks (and exit, with `--init-only`)
- `--plugin-dir <path>`: load plugins from a directory for this session only (repeatable)
- `--betas "interleaved-thinking"`: pass beta headers (API-key only)
- `--chrome` / `--no-chrome`: enable/disable Chrome browser integration
- `--disable-slash-commands`: disable all skills/commands for this session
- `--allow-dangerously-skip-permissions`: add `bypassPermissions` to the Shift+Tab cycle WITHOUT starting in it (different from `--dangerously-skip-permissions`)
- `--channels plugin:<name>@<marketplace>`: listen for MCP channel notifications (requires Claude.ai auth); `--dangerously-load-development-channels` allows non-allowlist channels for local development

## CLI subcommands

- `claude install [version|stable|latest]`: install/reinstall the native binary at a specific version
- `claude auth (login|logout|status)`: account auth; `--email`, `--sso`, `--console` modifiers; `auth status --text` for human-readable
- `claude agents`: list configured subagents grouped by source
- `claude auto-mode (defaults|config)`: print built-in classifier rules / effective config as JSON
- `claude remote-control`: server mode (no local interactive session) — pair from claude.ai
- `claude setup-token`: generate a long-lived OAuth token for CI scripts (requires Claude subscription) — canonical CI auth flow
- `claude mcp`, `claude plugin` / `claude plugins`: configuration subcommands
