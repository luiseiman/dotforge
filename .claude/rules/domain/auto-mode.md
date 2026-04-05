---
globs: "**/settings.json,**/settings.local.json"
description: "Auto mode classifier, permission stripping, tool concurrency"
domain: claude-code-engineering
last_verified: 2026-04-05
---

# Auto Mode & Tool Safety

## Auto mode (research preview, v2.1.83+)

- Classifier runs on **Sonnet 4.6** regardless of session model
- Evaluates each tool call for safety before allowing
- Fallback to prompt: 3 consecutive blocks OR 20 total blocks in session
- Subagent evaluation: auto mode applies to subagent tool calls too
- Enable: `permissions.defaultMode: "auto"` in settings.json
- Disable (managed): `permissions.disableAutoMode: "disable"`

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
