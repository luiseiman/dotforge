---
globs: "**/CLAUDE.md,**/agents/*.md,**/skills/**/SKILL.md,**/scripts/**/*.sh,**/.github/workflows/*.yml"
description: "Claude Code CLI flags and subcommands — automation, interactive, headless"
domain: claude-code-engineering
last_verified: 2026-05-13
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
- `--system-prompt` / `--system-prompt-file` / `--append-system-prompt` / `--append-system-prompt-file`: prompt customization (replace vs append)
- `--tools "Bash,Edit,Read"` (or `""`/`"default"`) restricts built-in tools; `--allowedTools` and `--disallowedTools` apply pattern-matched permission rules
- `--debug-file <path>` / `--debug "api,hooks"`: targeted debug output

## Other interactive flags

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
- `--agent <name>`: override the agent setting for the session

## Background sessions (v2.1.139+)

- `--bg "<task>"`: start the session as a background agent and return immediately. Prints session ID + management commands. Combine with `--agent <name>` to run a specific subagent. See `parallel-sessions.md` for the full lifecycle (`attach`/`logs`/`respawn`/`rm`/`stop`)
- `claude agents` (Research Preview): opens the agent view — unified list of every Claude Code session (running/blocked/done). When stdin is piped, falls back to listing configured subagents

## CLI subcommands

- `claude install [version|stable|latest]`: install/reinstall the native binary at a specific version
- `claude auth (login|logout|status)`: account auth; `--email`, `--sso`, `--console` modifiers; `auth status --text` for human-readable
- `claude agents`: opens agent view (v2.1.139+); when piped, lists configured subagents grouped by source
- `claude attach <id>` / `logs <id>` / `respawn <id>` / `rm <id>` / `stop <id>`: background session lifecycle (v2.1.139+)
- `claude auto-mode (defaults|config)`: print built-in classifier rules / effective config as JSON
- `claude remote-control`: server mode (no local interactive session) — pair from claude.ai
- `claude setup-token`: generate a long-lived OAuth token for CI scripts (requires Claude subscription) — canonical CI auth flow
- `claude mcp`, `claude plugin` / `claude plugins`: configuration subcommands

## Env vars worth knowing

- `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` (v2.1.129+): opt in to `/v1/models` discovery for the `/model` picker against custom `ANTHROPIC_BASE_URL` gateways. Was automatic in v2.1.126–v2.1.128 — **breaking change for users who depended on the auto behavior**. Affects Bedrock app-inference-profile, Vertex custom endpoints, Foundry, and any gateway. Pinned `model:` in settings is unaffected
- `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1` (v2.1.132+): opt out of the fullscreen alternate-screen renderer; keeps conversation in native scrollback
- `CLAUDE_CODE_FORCE_SYNC_OUTPUT=1` (v2.1.129+): force-enable synchronized output for terminals auto-detection misses (Emacs `eat`, custom embedded terminals)
- `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE` (v2.1.129+): for Homebrew/WinGet installs, runs the upgrade command in background and prompts for restart
- `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL` (v2.1.136+): re-enable session quality survey for enterprises capturing responses via OpenTelemetry
- `CLAUDE_CODE_SESSION_ID` (v2.1.132+): exported to Bash tool subprocesses, matches the `session_id` passed to hooks
- `$CLAUDE_EFFORT` (v2.1.133+): active effort level exported to Bash tool subprocesses; hook inputs see the same value under `effort.level`. See `hook-events.md`
