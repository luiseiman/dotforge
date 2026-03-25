---
globs: "**/*.sh,**/settings.json,**/settings.json.partial"
description: "Hook system design patterns and safety requirements"
domain: claude-code-engineering
last_verified: 2026-03-25
---

# Hook Architecture

- Hook events: SessionStart, PreToolUse, PostToolUse, UserPromptSubmit, Stop, SubagentStop
- Exit codes: 0 = allow, 1 = warn/error (non-blocking), 2 = block (stops the operation)
- In settings.json, hooks MUST be objects: {"type": "command", "command": "path/to/script.sh"}
- NEVER use plain strings for hooks — Claude Code rejects them silently
- Matchers: Bash, Read, Write, Edit, Grep, Glob — determine which tool triggers the hook
- block-destructive.sh is mandatory; supports profiles: minimal, standard, strict
- lint-on-save.sh is recommended; matcher = Write|Edit for post-save linting
- session-report.sh runs on Stop; generates JSON metrics to ~/.claude/metrics/
- All hooks must be executable: chmod +x (permissions -rwxr-xr-x)
- Validate hooks with bash -n before deploying; shellcheck if available
- Counter files for metrics use md5 hash of PWD for cross-invocation persistence
