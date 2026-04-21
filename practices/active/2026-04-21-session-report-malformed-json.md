---
id: session-report-malformed-json
source: session-insights
status: active
captured: 2026-04-21
tags: [insights, hooks, bug, high-priority, session-report]
tested_in: [dotforge, cds-dashboard, cotiza-api-cloud, crm, beautiful-lederberg]
incorporated_in: ['3.3.1']
---

# `template/hooks/session-report.sh` writes malformed JSON — affects ALL projects

## Observation

Every JSON file under `~/.claude/metrics/<project>/*.json` is malformed. Checked 5 projects (dotforge, cds-dashboard, cotiza-api-cloud, crm, beautiful-lederberg), all fail to parse at line 4, col 15. The `/forge insights` skill cannot use session metrics as a data source — silently degrades to retroactive git-log analysis.

## Root cause

Two bugs in `template/hooks/session-report.sh`:

1. **Line 26**: `ERRORS_ADDED=$(grep -c "| $DATE |" CLAUDE_ERRORS.md 2>/dev/null || echo "0")` — GNU grep returns `0` and exit code 1 when no match. `||` fires → echoes `"0"` → stdout becomes `0\n0`, producing multi-line JSON values.
   Same pattern on line 20 (`FILES_TOUCHED`) and line 89 (`DOMAIN_CHANGES`).

2. **Line 100–114 cascade**: once today's metrics file is malformed, `PREV_SESSIONS=$(jq -r '.sessions // 0' ...)` returns empty string. `SESSIONS=$((PREV_SESSIONS + 1))` fails with arithmetic error, leaves `SESSIONS` empty → next write emits `"sessions": ,`. Corruption compounds.

## Proposed fix

Replace the `|| echo "0"` idiom with `|| true` and a bash default:

```bash
ERRORS_ADDED=$(grep -c "| $DATE |" CLAUDE_ERRORS.md 2>/dev/null || true)
ERRORS_ADDED=${ERRORS_ADDED:-0}
# also: strip any accidental whitespace/newlines
ERRORS_ADDED=${ERRORS_ADDED//[!0-9]/}
ERRORS_ADDED=${ERRORS_ADDED:-0}
```

And in the merge branch, validate `PREV_*` are numeric before arithmetic:

```bash
PREV_SESSIONS=$(jq -r '.sessions // 0' "$METRICS_FILE" 2>/dev/null)
[[ "$PREV_SESSIONS" =~ ^[0-9]+$ ]] || PREV_SESSIONS=0
```

Retroactive cleanup: delete existing malformed files so the next session starts fresh:
```bash
find ~/.claude/metrics -name "*.json" -exec rm {} \;
```

## Why it matters

- `/forge insights` relies on these metrics for trend analysis
- Rule coverage trend, hook-block counts, error rate all depend on this hook
- Silent corruption for weeks — nobody noticed because `cat` shows recognizable JSON and the insights skill quietly falls back to retroactive mode

## Affected files

- `template/hooks/session-report.sh`
- `.claude/hooks/session-report.sh` (symlink/copy in dotforge itself)
- Propagate to all 12 registered projects after fix (via `/forge sync`)
