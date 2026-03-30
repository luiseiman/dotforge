---
globs: "**/*.sh,**/settings.json,**/settings.json.partial"
description: "Hook system design patterns and safety requirements"
domain: claude-code-engineering
last_verified: 2026-03-30
---

# Hook Architecture

- Hook events: SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop, PreCompact, PostCompact, PermissionRequest, SubagentStart, CwdChanged, StopFailure, SessionEnd
- Exit codes: 0 = allow, 1 = warn/error (non-blocking), 2 = block (stops the operation)
- In settings.json, hooks MUST be objects: {"type": "command", "command": "path/to/script.sh"}
- NEVER use plain strings for hooks — Claude Code rejects them silently
- Hook types: `command` (bash), `http` (POST to URL), `prompt` (LLM decision), `agent` (subagent) — most documented hooks use `command`
- Matchers: Bash, Read, Write, Edit, Grep, Glob — determine which tool triggers the hook
- block-destructive.sh is mandatory; supports profiles: minimal, standard, strict
- lint-on-save.sh is recommended; matcher = Write|Edit for post-save linting
- session-report.sh runs on Stop; generates JSON metrics to ~/.claude/metrics/
- All hooks must be executable: chmod +x (permissions -rwxr-xr-x)
- Validate hooks with bash -n before deploying; shellcheck if available
- Counter files for metrics use md5 hash of PWD for cross-invocation persistence
- PostCompact hook receives: `trigger` ("auto"/"manual") + `compact_summary` (full generated text) — VERIFIED 2026-03-30, docs say "common fields only" but these extra fields DO arrive
- PreCompact hook receives: `trigger` ("auto"/"manual") — NON-BLOCKING, exit code is ignored, use for logging/capture only
- SessionStart `source` field values: "startup", "resume", "compact", "clear" — use to differentiate behavior
- Tasks System (Jan 2026): persistent state in `~/.claude/tasks/<id>/` — survives compaction and /clear
- PermissionRequest: intercept permission dialog before shown, can auto-allow/deny with exit 2
- SubagentStart: inject additionalContext into spawned subagent via stdout
- CwdChanged: fires when directory changes mid-session, supports CLAUDE_ENV_FILE
- StopFailure: fires when turn ends by API error (rate_limit, billing_error, etc.)
