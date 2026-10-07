---
globs: "**/*.sh,**/settings.json"
description: "Hook event payloads and per-event behavior details"
domain: claude-code-engineering
last_verified: 2026-10-07
---

# Hook Event Details

## Context events

- PostCompact command: `trigger` ("auto"/"manual") + `compact_summary` (full text)
- PostCompact SDK: `compactType` + `messageCountBefore` + `messageCountAfter`
- PreCompact: `compactType` + `messageCount` — **BLOCKABLE since v2.1.105** (exit 2 prevents compaction)
- SessionStart `source`: "startup", "resume", "compact", "clear", "fork" (v2.1.232+). **Resume staleness fields (v2.1.251+)**: `seconds_since_last_response`, `context_tokens`, `prompt_cache_likely_expired`, `estimated_cache_write_usd` — lets `session-restore.sh` size its re-injection by whether the cache is already cold. Output: `hookSpecificOutput.initialUserMessage` auto-submits a first turn. dotforge wires three hooks here (v3.7.0+): `check-updates.sh` (version check), `session-restore.sh` (re-injects last-compact.md when source=compact), `session-startup.sh` (snapshot + drift detection on every other source — writes `.claude/session/last-startup.md` plus rotating `startup-history/<ISO>.md`, last 5). **v2.1.152**: SessionStart hooks can return `hookSpecificOutput.reloadSkills: true` to trigger a same-session skill directory re-scan after installing new skills, and `hookSpecificOutput.sessionTitle: "..."` to set the session display title on startup/resume (extending the v2.1.94 UserPromptSubmit-only capability).
- CwdChanged: fires on directory change, supports CLAUDE_ENV_FILE
- DirectoryAdded (v2.1.219+): fires after `/add-dir` (matcher `slash_command`) or an SDK `register_repo_root` call adds a working directory mid-session. Use to re-run drift/trust checks on the new root
- PreModelSwitch / PostModelSwitch (v2.1.251+): matcher = model name. Pre is blockable (`permissionDecision` allow/deny/ask + `permissionDecisionReason`); Post is observational. Fires on `/model`, fallback chains, and `--fallback-model` switches
- FileChanged: fires on external file modification — use for auto-reload
- InstructionsLoaded: fires when CLAUDE.md or `.claude/rules/*.md` loads. `load_reason`: `session_start` | `nested_traversal` | `path_glob_match` | `include` | `compact`. Observability-only, no decision control.
- Setup: fires for `--init-only` / `--maintenance` runs. Matchers: `init` | `maintenance`. Use for credential rotation, env-var provisioning, prerequisite checks BEFORE session starts. dotforge wires `pre-session-check.sh` (v3.7.0+) — validates settings.json JSON, behaviors/index.yaml YAML, all wired hooks present + executable, block-destructive.sh executable. Exit 2 blocks session start.
- **post-session (v2.1.169+, self-hosted runners only)**: fires after the session ends and BEFORE the workspace is deleted. Use for log persistence, artifact extraction, audit-trail capture in CI/cron environments that wipe workspaces between runs. Not applicable to interactive local sessions (workspace is not deleted).

## Tool events

- PreToolUse/PostToolUse: receive ABSOLUTE file paths since v2.1.90
- PostToolUse/PostToolUseFailure: input includes `duration_ms` (v2.1.119+) — tool execution time excluding permission prompts and PreToolUse hooks. Use for per-tool latency metrics without external timing
- PostToolUseFailure: fires when tool execution fails — use for error tracking
- PostToolUse `continueOnBlock: true` (v2.1.139+) — when set in the hook config, a `decision: "block"` feeds the `reason` back to Claude and the turn continues instead of stopping. Use for non-fatal validators (lint, type-check, drift detection)
- PostToolUse `hookSpecificOutput.updatedToolOutput` (v2.1.121+): replaces tool output for the model. Pre-v2.1.121 was MCP-only (`updatedMCPToolOutput`); now works for Bash, Edit, Write, Read, etc. Use sparingly — rewriting can hide errors and breaks audit trail
- PostToolBatch (v2.1.x+): fires when a batch of parallel tool calls completes, before the next model call. No matcher. Blockable via `decision: "block"` — point of choice for end-of-batch validation. **v2.1.161 behavior change**: a failed Bash call in the batch no longer cancels the other parallel calls. Post-fix, the batch always sees ALL dispatched results regardless of individual failures. Hook logic that assumed atomicity ("if I see N results, all N succeeded") must inspect per-tool success/failure explicitly
- UserPromptExpansion: fires when a slash command expands. Matcher: command name. Blockable — can prevent the expansion
- UserPromptSubmit: hook can return `hookSpecificOutput.sessionTitle: "..."` (v2.1.94+) to set the session display title (shown in `/resume` and terminal title)
- TaskCreated/TaskCompleted: agent lifecycle — use for orchestration metrics
- Hook output >50K chars: saved to disk, file path + preview sent (v2.1.89)

## Permission events

- PermissionRequest: intercept permission dialog, auto-allow/deny with exit 2. Output `decision: {behavior, updatedInput?, ruleApply?}`. Fires in `--print` mode since v2.1.268. `agent`-type handlers rejected here (v2.1.280). Fails closed when matching fails or input is unserializable (v2.1.288)
- PermissionDenied: fires on auto mode classifier denials only (not manual deny or PreToolUse block). Input: tool_name, tool_input, tool_use_id, reason. Return `{retry: true}` to allow retry
- Elicitation / ElicitationResult: `{"decision": "block"}` now declines the elicitation (v2.1.284)
- PreToolUse `defer`: pause execution for async external approval (Slack, mobile notification). Combine with `asyncRewake: true` for human-in-the-loop flows (v2.1.89+)

## Agent events

- SubagentStart: inject additionalContext into spawned subagent via stdout
- SubagentStop: a specific matcher no longer fires when the agent type is empty (v2.1.275)
- TeammateIdle: fires when a team member has no pending work; no longer fired from subagents or forks (v2.1.290). `idle_prompt` notifications are silenced while background agents run (v2.1.288)
- InstructionsLoaded carries `agent_id`, `agent_type`, `effort` (v2.1.288) — attribute which subagent loaded which rule
- Subagent API requests carry `x-claude-code-agent-id` / `x-claude-code-parent-agent-id` headers (v2.1.139+); OTEL `claude_code.llm_request` spans include `agent_id` / `parent_agent_id` attributes — use for distributed tracing of agent trees

## Shared payload fields

- `session_id` — present in every hook input; matches `$CLAUDE_CODE_SESSION_ID` exported into Bash tool subprocesses (v2.1.132+)
- `effort.level` — present in every hook input (v2.1.133+); values `"low" | "medium" | "high" | "xhigh" | "max"`. Bash tool subprocesses see the same value as `$CLAUDE_EFFORT`. Enables effort-aware hook decisions (stricter at low, relaxed at max)
- `cwd` — absolute working directory
- `transcript_path` — path to the session transcript jsonl
- `scratchpad_dir` (v2.1.257+) — session-scoped scratch directory; write hook temp files here instead of `/tmp`
- Path placeholders in hook config: `${CLAUDE_PROJECT_DIR}` (project root — stays put inside worktrees), `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`

## Hook JSON output fields (universal)

Standard output fields all hooks may return:
- `continue: bool` — false aborts the current turn
- `stopReason: string` — surfaced in the UI when continue=false
- `suppressOutput: bool` — hide stdout from the model
- `systemMessage: string` — inject a system-style message into context
- `terminalSequence: string` (v2.1.141+) — emit raw escape sequences for desktop notifications (OSC 9 on iTerm2/macOS), window titles (`\033]0;<title>\007`), or terminal bell (`\a`). Works without a controlling TTY, so hooks can signal the user during background sessions. Example: `{"terminalSequence":"]0;Build green"}`

### Channel-specific 10K char cap (BREAKING, 2026)

**`additionalContext`, `systemMessage`, and plain stdout are now capped at 10,000 characters** (separate from the older v2.1.89 generic 50K spill-to-file rule). When any of these channels exceeds 10K chars, the excess is saved to a file in the session directory and the model receives a `pointer-with-preview` reference instead of the inline content.

dotforge implication: `template/hooks/post-compact.sh` + `scripts/compact-filter.py` were designed against the 50K threshold. With 10K, moderately-filtered compact summaries (between 10K and 50K chars) spill to file → the model sees a pointer instead of the full summary inline. `session-restore.sh` and `session-startup.sh` are also at risk — they emit `additionalContext` and may exceed 10K post-compaction if drift section grows. Re-tune compact-filter target to ≤10K. Audit any custom project hooks that emit verbose context.

## CLAUDE_ENV_FILE preamble execution (4-hook scope)

`CLAUDE_ENV_FILE` is a session-scoped file that **4 hook events** can write to in order to persist environment variables across all subsequent Bash tool subprocesses. Claude Code executes the file as a preamble script before each Bash invocation — direnv-equivalent built into Claude Code.

The 4 hooks with `$CLAUDE_ENV_FILE` access:
- `SessionStart` — set baseline env at session start
- `Setup` — set env for CI/maintenance runs
- `CwdChanged` — re-source env on directory change (direnv pattern)
- `FileChanged` — react to `.env` file modifications

**APPEND-mode warning:** Claude Code appends to `$CLAUDE_ENV_FILE`. Do NOT point it at an existing source script — your script gets corrupted with appended exports.

Pattern (SessionStart + CwdChanged for direnv-equivalent):
```bash
# SessionStart hook
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ] && [ -f ".env" ]; then
  grep -v '^#' .env | sed 's/^/export /' >> "$CLAUDE_ENV_FILE"
fi
```

Use cases for dotforge-managed projects: TRADINGBOT (broker creds per env), cotiza-api-cloud (WebSocket env vars), InviSight-iOS (Supabase tokens), GCP/AWS projects with cloud creds. Reduces per-call env injection workarounds.

## SessionStart watchPaths registers persistent FileChanged matchers

`SessionStart` hooks can return `hookSpecificOutput.watchPaths` (array of file paths). Claude Code registers these paths with the OS-level file watcher (**FSEvents** on macOS, **inotify** on Linux). For the rest of the session, modifications to any registered path automatically fire `FileChanged` events — no polling, millisecond latency.

```json
{
  "hookSpecificOutput": {
    "additionalContext": "...",
    "watchPaths": [
      ".claude/settings.json",
      ".claude/rules/_common.md",
      "behaviors/index.yaml"
    ]
  }
}
```

dotforge governance use case: today `pre-session-check.sh` (Setup hook) validates governance-critical files (`settings.json`, `behaviors/index.yaml`, `.claude/rules/*.md`) at session boundaries only. With `watchPaths`, mid-session drift can be detected inline — a user-side edit or subagent mutation triggers `FileChanged` immediately. Pair with a `FileChanged` hook to re-validate or warn.

## Stop hook contract (v2.1.143+)

- Stop hooks that return `decision: "block"` repeatedly were able to loop forever (block → retry → block). A cap was added: **8 consecutive blocks** terminate the turn with a warning
- Override the cap via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP=<n>` env var
- Implication: blocks **must converge**. A Stop hook that gates on a flaky test should count attempts and let the turn pass after N retries instead of looping. Treat `decision: "block"` as a signal for "more work needed", not "force always"

## StopFailure matchers (production routing)

Matcher accepts the documented `error_type` values. Use for production-grade routing instead of treating all stop failures the same:

| `error_type` matcher | When it fires | Recommended action |
|----------------------|---------------|--------------------|
| `rate_limit` | API request hit RPM/TPM ceiling | Log only — Claude Code auto-retries. Alert if >N/hour |
| `authentication_failed` | OAuth token expired/revoked, or `ANTHROPIC_API_KEY` invalid | Trigger token rotation or page operator |
| `billing_error` | Subscription quota exhausted or payment failed | **PAGE** — bot will not recover without human intervention |
| `server_error` | Anthropic-side 5xx | Log + degrade gracefully. Alert if persistent (>5min sustained) |
| `cloud_credential_error` (v2.1.267+) | Bedrock/Vertex/Foundry credential chain failed (expired STS, missing ADC, wrong profile) | Page operator — rotate cloud creds; distinct from `authentication_failed` (Anthropic auth) |

Production hook config:
```json
{
  "StopFailure": [
    {"matcher": "billing_error",         "hooks": [{"type": "command", "command": ".claude/hooks/page-operator.sh billing"}]},
    {"matcher": "authentication_failed", "hooks": [{"type": "command", "command": ".claude/hooks/rotate-token.sh"}]},
    {"matcher": "rate_limit",            "hooks": [{"type": "command", "command": ".claude/hooks/log-rate-limit.sh"}]},
    {"matcher": "server_error",          "hooks": [{"type": "command", "command": ".claude/hooks/log-server-error.sh"}]}
  ]
}
```

StopFailure is observability-only (not blockable) — the hook reports/alerts, it can't prevent the failure. Useful for trading bots, cron-driven `/schedule` jobs, and any unattended session where silent death is unacceptable.

## Display events (v2.1.152+)

- **MessageDisplay**: fires when an assistant message is about to be rendered to the user. Hook returns `hookSpecificOutput.displayContent` — a display-only replacement (the model's own transcript is untouched) — to redact PII/secrets or hide the message. First "display-time" event — distinct from all prior events which are control-flow

## Stop / SubagentStop additional fields (v2.1.145+)

Both Stop and SubagentStop hook inputs now include:
- `background_tasks` — list of `claude --bg` sessions still running when the foreground turn stops
- `session_crons` — list of `/schedule`-created crons active in this session

Enables exit-time reporting of pending background work without external probing. `template/hooks/session-report.sh` reads both to emit `pending_bg_tasks` and `active_crons` counts in the JSON metrics file.

## MCP elicitation events (v2.1.76+)

- Elicitation: fires when an MCP server requests structured user input mid-tool-call. Hook can return `action: "accept" | "decline" | "cancel"` and override field values via `content: {field: "new_value"}`
- ElicitationResult: fires after the user (or hook) responds. Observability + audit
- Combined with `disableSkillShellExecution` and managed settings, lets enterprises pre-validate MCP form submissions before they reach the server
