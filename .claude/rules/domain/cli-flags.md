---
globs: "**/CLAUDE.md,**/agents/*.md,**/skills/**/SKILL.md,**/scripts/**/*.sh,**/.github/workflows/*.yml"
description: "Claude Code CLI flags and subcommands — automation, interactive, headless"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Claude Code CLI Flags

Reference for non-paralellism CLI surface. For session-parallelism flags see `parallel-sessions.md`.

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
- `--init-only` / `--maintenance`: run `Setup` hooks (matchers `init` / `maintenance`) and exit. See `hook-events.md` for Setup payload
- `--input-format text|stream-json` and `--include-partial-messages`: SDK streaming knobs (require `--output-format stream-json`)
- `--strict-mcp-config`: only honor MCP servers from `--mcp-config`
- `--system-prompt` / `--system-prompt-file` / `--append-system-prompt` / `--append-system-prompt-file`: prompt customization (replace vs append). A flag and its `-file` form can be combined since v2.1.283 (file content first). **Snapshot semantics**: the prompt is built on the conversation's first request and reused until compaction — including across `--resume`/`--continue`; pass `--system-prompt-snapshot off` (v2.1.257) to rebuild every request while iterating on prompt text. A line containing only `__SYSTEM_PROMPT_DYNAMIC_BOUNDARY__` splits a custom prompt into cached (above) and per-run (below) parts (v2.1.275)
- `--append-subagent-system-prompt "<text>"` / `--append-subagent-system-prompt-file <path>` (v2.1.205/261, `-p` only): append to every subagent's system prompt, nested ones included, forks excepted
- `--autocompact <auto|tokens>` (v2.1.221): session-only auto-compact window; `/autocompact` persists per model (v2.1.288)
- `--agents '<json>'` or, with `-p`, `--agents <file.json>` (v2.1.281): define subagents inline; validated at startup, exits on an invalid value (v2.1.242)
- `--forward-subagent-text` (v2.1.211, stream-json): emit subagent text/thinking with `parent_tool_use_id`; nested subagents since v2.1.219, forked-skill subagents since v2.1.275
- `--max-budget-usd` counts subagent spend; at the cap, new spawns fail and running background subagents are stopped (v2.1.217)
- `--mcp-config` with `-p` waits up to `MCP_TIMEOUT` (30 s default; `CLAUDE_CODE_MCP_STARTUP_WAIT_MS`) for servers before the first turn (v2.1.221); `--permission-prompt-tool` cannot approve MCP tools marked user-interaction (v2.1.199)
- `--tools "Bash,Edit,Read"` (or `""`/`"default"`) restricts built-in tools; `--allowedTools` and `--disallowedTools` apply pattern-matched permission rules. **Native build conditional (v2.1.162+)**: on native macOS/Linux builds the standalone `Grep` / `Glob` tools are replaced by embedded `bfs`/`ugrep` via Bash. Listing `--tools "Grep,Glob"` explicitly activates the native searchers (otherwise they're routed through Bash). On Windows / npm builds the flag behaves as before
- `--debug-file <path>` / `--debug "api,hooks"`: targeted debug output
- `--restricted` / `CLAUDE_CODE_RESTRICTED=1` (v2.1.248+): eval-harness mode for shared machines — removes command/code-running tools and WebFetch unless named in `--tools`, confines file tools to working directories, loads only managed settings + `--settings`, refuses `bypassPermissions` and cloud sessions
- `--permission-prompts host|none` (v2.1.259+, `-p` only): `none` denies anything that would prompt while the active mode keeps deciding — safer than `dontAsk` when allow rules should still apply. `--permission-mode manual` is an alias of `default` (v2.1.200+)
- `--safe-mode` / `CLAUDE_CODE_SAFE_MODE=1` (v2.1.169+): start Claude Code with ALL customizations disabled — no hooks, skills, plugins, custom agents, custom MCP. Auth + built-in permissions + built-in tools only. Use for triaging "is dotforge breaking something?" vs "is Claude Code itself broken?". Equivalent to `--bare` but with explicit semantics and CI-friendly env var. If a project misbehaves only outside `--safe-mode`, the bug is in user/project config not core

## Other interactive flags

- `--name`/`-n "label"`: display name for the session (resumable via `claude --resume <name>`); `/rename` changes it mid-session
- `--session-id <uuid>`: explicit UUID for the conversation
- `--remote-control` (`--rc`) / `claude remote-control`: enable Remote Control so the session is also controllable from claude.ai or the Claude app. `--remote-control-session-name-prefix` overrides the hostname-based default
- `--ide`: auto-connect to a running IDE if exactly one is available
- `--init` / `--init-only`: run init hooks (and exit, with `--init-only`)
- `--plugin-dir <path>`: load plugins from a directory, `.zip`, or a folder of plugins (v2.1.265) for this session only (repeatable); `--plugin-url <url>` fetches a zip
- `--advisor fable|opus|sonnet|<id>`: enable the server-side advisor tool for the session (overrides `advisorModel` setting)
- `--desktop [--continue | --resume <id>]` (v2.1.285): open the Desktop app on this directory/session and exit (macOS, x64 Windows, Claude subscription)
- `--worktree #<n> | <GitHub PR URL> | <GitLab MR URL>` (v2.1.233 for GitLab): branch the worktree from a PR/MR fetched from `origin`
- `--cloud "<task>"` (was `--remote`, now a deprecated alias); `--environment ccpool_<id> --ref <branch>` targets a self-hosted environment (v2.1.224)
- `--betas "interleaved-thinking"`: pass beta headers (API-key only)
- `--chrome` / `--no-chrome`: enable/disable Chrome browser integration
- `--disable-slash-commands`: disable all skills/commands for this session
- `--allow-dangerously-skip-permissions`: add `bypassPermissions` to the Shift+Tab cycle WITHOUT starting in it (different from `--dangerously-skip-permissions`)
- `--channels plugin:<name>@<marketplace>`: listen for MCP channel notifications (requires Claude.ai auth); `--dangerously-load-development-channels` allows non-allowlist channels for local development
- `--agent <name>`: override the agent setting for the session

## Background sessions (v2.1.139+)

- `--bg "<task>"`: start the session as a background agent and return immediately. Prints session ID + management commands. Combine with `--agent <name>` to run a specific subagent. See `parallel-sessions.md` for the full lifecycle (`attach`/`logs`/`respawn`/`rm`/`stop`)
- `claude agents` (Research Preview): opens the agent view — unified list of every Claude Code session (running/blocked/done). When stdin is piped, falls back to listing configured subagents

## CLI subcommands

- `claude install [version|stable|latest]`: install/reinstall the native binary at a specific version
- `claude auth (login|logout|status)`: account auth; `--email`, `--sso`, `--console` modifiers; `auth status --text` for human-readable
- `claude agents`: opens agent view (v2.1.139+); when piped, lists configured subagents grouped by source. Accepts launcher flags for dispatched background sessions (v2.1.141-143):
  - `--cwd <path>` (v2.1.141) — scope the agent list / dispatch to a directory
  - `--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir`, `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions` (v2.1.142) — same surface as interactive `claude`, applies to sessions dispatched FROM the view (not those already running)
  - `--json` (v2.1.145) — emit live sessions as JSON array for scripting (tmux-resurrect, status bars, session pickers)
  - v2.1.143: `/bg` and ←-detach preserve `--mcp-config`, `--settings`, `--add-dir`, `--plugin-dir`, `--strict-mcp-config`, `--fallback-model`, `--allow-dangerously-skip-permissions` when backgrounding interactive sessions. Bg sessions dispatched from `claude agents` now honor `permissions.defaultMode` from settings.json (previously overrode to auto)
- `claude attach <id|name>` / `logs <id|name>` / `respawn <id>` / `rm <id>` / `stop <id>` / `daemon status|stop --any`: background session lifecycle (v2.1.139+; partial-name match v2.1.290; `rm --discard-unpushed` v2.1.260, `--force-remove-worktree` v2.1.268). See `parallel-sessions.md`
- `claude auto-mode (defaults|config|reset)`: print built-in classifier rules / effective config as JSON; `defaults --label <prefix>` filters (v2.1.208); `reset [-y]` removes the user `autoMode` section (v2.1.212)
- `claude remote-control`: server mode (no local interactive session) — pair from claude.ai
- `claude setup-token`: generate a long-lived OAuth token for CI scripts (requires Claude subscription) — canonical CI auth flow
- `claude auth status`: JSON with `authMethod` (`none|claude.ai|oauth_token|api_key|api_key_helper|third_party`) and `configDirectory` (v2.1.268); exit 1 when logged out
- `claude mcp`, `claude plugin` / `claude plugins`: configuration subcommands. `claude mcp login|logout <name> [--no-browser]` runs/clears a server's OAuth flow from the shell (v2.1.185+)
- `claude purge [path] [--dry-run|-y|-i|--all]` (renamed from `claude project purge` in v2.1.288, old name warns): delete all local state for a project — transcripts, task lists, debug logs, edit history, prompt history, `~/.claude.json` entry
- `claude doctor`: read-only install + settings diagnostics without starting a session (settings-file validation errors, Remote Control eligibility); `/doctor` in-session can also apply fixes
- `claude import [codex|…] [--dry-run] [--yes]` (v2.1.213): bring another coding agent's config into Claude Code (appends instruction files to CLAUDE.md, carries MCP/commands/subagents/skills). Not on Bedrock/Vertex/Foundry
- `claude ultrareview [target] [--json] [--timeout <min>] [--post|--no-post]` (v2.1.227 for `--post`): non-interactive cloud review; `--post` comments findings on a github.com PR
- `claude gateway --config gateway.yaml`, `claude self-hosted-runner setup|doctor|orchestrator` (v2.1.224): enterprise gateway / self-hosted cloud runners — outside dotforge scope

## Env vars worth knowing

- `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` (v2.1.129+): opt in to `/v1/models` discovery for the `/model` picker against custom `ANTHROPIC_BASE_URL` gateways. Was automatic in v2.1.126–v2.1.128 — **breaking change for users who depended on the auto behavior**. Affects Bedrock app-inference-profile, Vertex custom endpoints, Foundry, and any gateway. Pinned `model:` in settings is unaffected
- `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` (v2.1.132+): opt out of the fullscreen alternate-screen renderer; keeps conversation in native scrollback
- `CLAUDE_CODE_FORCE_SYNC_OUTPUT=1` (v2.1.129+): force-enable synchronized output for terminals auto-detection misses (Emacs `eat`, custom embedded terminals)
- `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE` (v2.1.129+): for Homebrew/WinGet installs, runs the upgrade command in background and prompts for restart
- `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL` (v2.1.136+): re-enable session quality survey for enterprises capturing responses via OpenTelemetry
- `CLAUDE_CODE_SESSION_ID` (v2.1.132+): exported to Bash tool subprocesses, matches the `session_id` passed to hooks
- `$CLAUDE_EFFORT` (v2.1.133+): active effort level exported to Bash tool subprocesses; hook inputs see the same value under `effort.level`. See `hook-events.md`
- `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` — **removed 2026-06-01**; no env path to pin fast mode to an older Opus. See `model-ids.md`
- `CLAUDE_CODE_RESTRICTED=1` (v2.1.248+): same as `--restricted`
- `ANTHROPIC_DEFAULT_MODEL` (v2.1.236+): model new sessions start on; `CLAUDE_CODE_SUBAGENT_MODEL` / `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (v2.1.252/257): default / forced subagent model
- `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (default 3), `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` (default 20), `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS` (1–256), `CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0`
- `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` (v2.1.233+): restore TodoWrite/TaskCreate on Opus 4.8+/Sonnet 5+/Fable
- `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` (v2.1.223+): hold native-1M models to 200K; `CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT=1` skips the auto-compact cap for unknown IDs
- `CLAUDE_CODE_AUTO_MODE_SERVER=0` (v2.1.278+): use the local auto-mode classifier instead of the server-side default
- `CLAUDE_CODE_DISABLE_WEB_FETCH`, `CLAUDE_CODE_WEBFETCH_DEADLINE_MS` (default 300000 — a page not downloaded in 5 min fails, v2.1.268), `CLAUDE_CODE_WEB_SEARCH_REFILLS_PER_HOUR` (100/hour refill replaces the 200-call cap)
- `CLAUDE_CODE_MCP_STARTUP_WAIT_MS`, `CLAUDE_CODE_MAX_MCP_DESCRIPTION_LENGTH`, `CLAUDE_CODE_NONSTREAMING_TIMEOUT_RETRIES`, `CLAUDE_CODE_DISABLE_STRUCTURED_OUTPUTS`, `CLAUDE_CODE_GATEWAY_HINT_HEADERS`
- `CLAUDE_CODE_PROJECT_DIR_NAME` (v2.1.234+): with `CLAUDE_CONFIG_DIR`, share one auto-memory dir across launch directories; `CLAUDE_CODE_NEW_INIT=1`: `/init` also reads AGENTS.md, `.windsurf/rules`, `.clinerules`
- `CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT=1`, `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT=1`: opt out of the native dangerous-`rm` guard (see `permission-model.md`)
- `feedbackDrafts` setting / `SendFeedback` tool (v2.1.247): Claude drafts feedback reports you review in `/feedback`. A feedback upload includes the system prompt (CLAUDE.md content), tool definitions and model parameters with secrets redacted (v2.1.224) — an egress point to disable on production-tier projects handling regulated data
- `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP=<n>` (v2.1.143+): override the 8-consecutive-block cap on Stop hooks. See `hook-events.md` Stop hook contract
- `CLAUDE_CODE_SAFE_MODE=1` (v2.1.169+): equivalent to `--safe-mode` flag — disables all customizations. CI-friendly for "is the failure my config or upstream?" triage
- `CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1` (v2.1.195+): disable mouse click/drag/hover in fullscreen mode while keeping wheel scroll. Use when terminal multiplexers (tmux, zellij) capture clicks and break text selection
- `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS=1` (v2.1.169+): companion to `disableBundledSkills` setting — skip the harness-shipped skills (`/deep-research`, etc.) so project-owned versions take over without name collision
