---
globs: "**/settings.json,**/settings.local.json"
description: "Auto mode classifier, permission stripping, tool concurrency"
domain: claude-code-engineering
last_verified: 2026-10-06
---

# Auto Mode & Tool Safety

## Auto mode (GA v2.1.83+ — SESSION DEFAULT since v2.1.284)

- **Default when `permissions.defaultMode` is unset** (v2.1.283 third-party/telemetry-off, v2.1.284 every interactive + VS Code session on every plan/provider, v2.1.285 `-p` + Python SDK on third-party). A settings file without `defaultMode` = auto mode ON. dotforge pins `"defaultMode": "default"` in `global/settings.json.tmpl` (user scope) to keep prompt-for-unknowns; opt into auto per session with `--permission-mode auto`
- **Project/local scope cannot set `auto` or `bypassPermissions`** (v2.1.257) — silently ignored. Only user settings, managed settings, or `--permission-mode` take effect. Per-project opt-in via `.claude/settings.json` / `settings.local.json` is impossible
- Classifier is **server-side by default** on Claude API, Enterprise, Bedrock, Vertex, Foundry, gateways (v2.1.278; direct API with telemetry off v2.1.282). `CLAUDE_CODE_AUTO_MODE_SERVER=0` opts out to the local classifier. `/status` shows an "Auto mode server" row. Local classifier ignores an `ANTHROPIC_DEFAULT_SONNET_MODEL` pin to Sonnet/Opus 5.5 and runs Sonnet 5 (v2.1.288). Same defaults incl. severity-scored classification on third-party providers (v2.1.246); the v2.1.158 `CLAUDE_CODE_ENABLE_AUTO_MODE=1` opt-in is no longer required (v2.1.207+)
- Turn stops after **10 consecutive unanswered denials** (v2.1.280). Over-long conversations are compacted for the classifier (v2.1.288). Pre-v2.1.280 fallback was 3 consecutive / 20 total blocks
- Subagent evaluation: applies to subagent tool calls; subagent results hand back through a classifier-reviewed call (v2.1.271). Cross-session `SendMessage` is classified before dispatch (v2.1.222)
- `/permissions` has an Auto mode tab for classifier rules (v2.1.246). `Monitor` allow rules are set aside while auto mode is on. Classifier cannot be fooled by `status.showUntrackedFiles=no` (v2.1.237); blocks transcript tampering and asks before `rm -rf` on unresolved variables (v2.1.202+)
- `--permission-mode auto` (or `manual` as alias of `default`, v2.1.200) from CLI. Disable (managed): `permissions.disableAutoMode: "disable"`. `claude auto-mode reset [-y]` removes the user `autoMode` section (v2.1.212); `claude auto-mode defaults --label <prefix>` filters built-in rules (v2.1.208)
- Audit item 8 (`audit/checklist.md`) treats a missing `defaultMode` as auto mode active — deny list must cover secrets
- `showThinkingSummaries`: defaults to false since v2.1.89 — controls VISIBILITY only. Thinking blocks render as collapsed stub when off, full summary when on. **Does NOT reduce thinking token spend** — model generates the same content either way. Headless mode (`-p`) and SDK callers always receive summaries regardless of this flag.
- `alwaysThinkingEnabled`: enables extended thinking by default for all sessions. **This is the actual cost knob** — set `false` to stop generating thinking blocks. To trim spend without disabling, lower `effort` or the API `thinking_budget` instead. Typically set via `/config`, not edited directly.
- `disableSkillShellExecution`: blocks inline shell in skills/commands (managed)
- `forceRemoteSettingsRefresh`: fail-closed — blocks startup until remote settings fetched (v2.1.92)

## Extending the classifier with `"$defaults"` (v2.1.118+)

`autoMode.allow`, `autoMode.soft_deny`, and `autoMode.environment` accept the literal string `"$defaults"` as a placeholder for the built-in classifier rules. Without it, the array REPLACES the defaults (all-or-nothing). With it, custom rules are appended to the built-ins.

```json
{
  "autoMode": {
    "allow": ["$defaults", "Bash(make build:*)", "Bash(scripts/lint.sh)"],
    "soft_deny": ["$defaults"]
  }
}
```

Always prepend `"$defaults"` unless you intend a full classifier replacement.

## Three tiers: allow / soft_deny / hard_deny (v2.1.136+)

`autoMode` now supports three tiers with distinct semantics:

| Tier | Behavior | Override path |
|------|----------|---------------|
| `allow` | Auto-approve when rule matches | Always granted if matched |
| `soft_deny` | Block by default, classifier may grant pass | Classifier can override on user intent |
| `hard_deny` | Block unconditionally — classifier ignored, no allow can override | None |

Use `hard_deny` for patterns that must never auto-approve regardless of how the model rationalizes the intent — e.g. `Bash(curl *|sh)`, `Bash(eval *)`, base64-decode pipes. Recommended for projects with secrets in env, trading bots, or any cloud-cred-handling code.

```json
{
  "autoMode": {
    "hard_deny": ["Bash(curl *|sh)", "Bash(* base64 -d * | sh)"],
    "allow": ["$defaults", "Bash(make build:*)"],
    "soft_deny": ["$defaults"]
  }
}
```

## Classify every shell command (`classifyAllShell`, v2.1.193+)

`autoMode.classifyAllShell: true` routes ALL Bash and PowerShell commands through the classifier instead of just unknown/unmatched ones. Pre-v2.1.193, an `allow` match short-circuited the classifier; with this flag, every shell call is evaluated for safety even if `allow` would otherwise grant it. Trades latency (extra classifier hop per command) for defense-in-depth (catches `allow` rules that turned out broader than intended).

Use for production-tier projects where the cost of one wrong auto-approval exceeds the cost of ~100ms per Bash call. Not recommended for high-throughput dev tooling (test loops, build watchers).

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

**Native macOS/Linux builds (v2.1.117+)**: standalone `Glob` and `Grep` tools are replaced by embedded `bfs` and `ugrep` reachable through `Bash`. They no longer appear as separate concurrent-safe surfaces — searches inherit Bash's "not concurrent-safe" classification. Hooks with `matcher: "Glob"` or `matcher: "Grep"` silently never fire on native builds. Windows and npm-installed builds keep the original tools.

**Batch-level failure isolation (v2.1.161+)**: "Bash = not concurrent-safe" refers to kernel-level concurrency (filesystem races, shared state). At the batch dispatch level, v2.1.161 changed semantics — a failed Bash call in a parallel batch no longer cancels the others. Independent calls complete and their results all reach `PostToolBatch`. See `hook-events.md` § PostToolBatch.
