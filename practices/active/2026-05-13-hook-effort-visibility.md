---
id: practice-2026-05-13-hook-effort-visibility
title: Hooks receive effort.level + Bash subprocesses get $CLAUDE_EFFORT env (v2.1.133)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [hooks, effort, telemetry, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
Two related signals expose the active effort level to runtime code:

- **Hook JSON input** now includes `effort.level` (`"low" | "medium" | "high" | "xhigh" | "max"`)
- **Bash tool subprocesses** see `$CLAUDE_EFFORT` env var with the same value

Available since v2.1.133. Enables effort-aware decisions: a destructive-action hook can be stricter at `low` (likely a quick fix that shouldn't touch prod) and more permissive at `max` (deliberate engineering session).

```bash
# Inside a hook
EFFORT=$(jq -r '.effort.level // "high"')
case "$EFFORT" in
  low|medium) [[ "$cmd" =~ migrate|drop ]] && exit 2 ;;
esac
```

## Evidence
CHANGELOG v2.1.133: "Hooks now receive the active effort level via the `effort.level` JSON input field and the `$CLAUDE_EFFORT` environment variable, and Bash tool commands can read `$CLAUDE_EFFORT`".

## Impact on dotforge
- `.claude/rules/domain/hook-events.md` — document `effort.level` as a payload field on all events
- `.claude/rules/domain/hook-architecture.md` — note `$CLAUDE_EFFORT` env var availability inside Bash tool commands
- `template/hooks/block-destructive.sh` — candidate enhancement: tighten matching when `CLAUDE_EFFORT=low` (e.g., block `git push origin main` from low-effort sessions on shared repos)
- `template/hooks/session-report.sh` — log effort distribution per session as a new metric

## Decision
Pending
