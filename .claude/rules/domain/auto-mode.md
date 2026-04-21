---
globs: "**/settings.json,**/settings.local.json"
description: "Auto mode classifier, permission stripping, tool concurrency"
domain: claude-code-engineering
last_verified: 2026-04-20
---

# Auto Mode & Tool Safety

## Auto mode (GA, v2.1.83+)

- Classifier runs on **Sonnet 4.6** regardless of session model
- Evaluates each tool call for safety before allowing
- Fallback to prompt: 3 consecutive blocks OR 20 total blocks in session
- Subagent evaluation: auto mode applies to subagent tool calls too
- Enable: `permissions.defaultMode: "auto"` in settings.json (research-preview `--enable-auto-mode` gate removed in v2.1.111 — no CLI flag needed)
- `--permission-mode auto` to start in auto mode from CLI
- Disable (managed): `permissions.disableAutoMode: "disable"`
- **Max subscribers on Opus 4.7**: auto mode available as a tier gate (v2.1.111+) — no opt-in beyond the pricing plan
- `showThinkingSummaries`: defaults to false since v2.1.89 — controls VISIBILITY only. Thinking blocks render as collapsed stub when off, full summary when on. **Does NOT reduce thinking token spend** — model generates the same content either way. Headless mode (`-p`) and SDK callers always receive summaries regardless of this flag.
- `alwaysThinkingEnabled`: enables extended thinking by default for all sessions. **This is the actual cost knob** — set `false` to stop generating thinking blocks. To trim spend without disabling, lower `effort` or the API `thinking_budget` instead. Typically set via `/config`, not edited directly.
- `disableSkillShellExecution`: blocks inline shell in skills/commands (managed)
- `forceRemoteSettingsRefresh`: fail-closed — blocks startup until remote settings fetched (v2.1.92)

## Permission stripping in auto mode

Broad allow rules are SILENTLY STRIPPED when auto mode activates:
- Interpreters: python, python3, node, deno, tsx, ruby, perl, php, lua
- Package runners: npx, bunx, npm run, yarn run, pnpm run, bun run
- Shells: bash, sh, zsh, fish, eval, exec, env, xargs, ssh
- System: sudo, Agent
- Matching: exact, prefix (`python:*`), wildcard (`python*`, `python -*`)
- Stripping is REVERSIBLE — stored in `strippedDangerousRules`, restored on exit
- Workaround: use specific tool commands (pytest, uvicorn, vitest)

## Tool concurrency & safety

| Tool | Concurrent-Safe | Read-Only |
|------|----------------|-----------|
| Read, Glob, Grep, LS | yes | yes |
| WebFetch, WebSearch | yes | yes |
| TodoWrite | yes | no |
| Bash | no | no |
| Write, Edit | no | no |
| Agent | no | no |
