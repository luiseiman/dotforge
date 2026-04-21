---
id: new-cli-flags-automation
source: watch:code.claude.com/docs/en/cli-reference
status: inbox
captured: 2026-04-21
tags: [cli, automation, headless, medium-priority, v2.1.113]
tested_in: []
incorporated_in: []
---

# New CLI flags relevant to dotforge automation and benchmark

## Observation

v2.1.108→v2.1.114 added CLI flags that matter for scripted/headless workflows and the `benchmark` skill:

- `--effort low|medium|high|xhigh|max` — pin effort at startup (v2.1.113)
- `--exclude-dynamic-system-prompt-sections` — improves prompt-cache reuse across users/machines for scripted multi-user workloads
- `--max-budget-usd N` — hard cost cap (print mode)
- `--max-turns N` — hard turn cap (print mode)
- `--json-schema '{...}'` — validated structured JSON output (print mode)
- `--fallback-model <id>` — auto-fallback when default overloaded (print mode)
- `--no-session-persistence` — don't save session to disk (print mode)
- `--include-hook-events` — stream all hook events (requires `--output-format stream-json`)
- `--replay-user-messages` — echo stdin back for acknowledgment
- `--init-only` / `--maintenance` — run init/maintenance hooks and exit

## Why it matters for dotforge

- `skills/benchmark/SKILL.md` uses `claude --print` for A/B tests. Now can pin `--effort`, cap with `--max-budget-usd`/`--max-turns` for deterministic cost-bounded benchmarks.
- `--exclude-dynamic-system-prompt-sections` relevant for the CI pattern in `.github/workflows/` if any.
- `domain/parallel-sessions.md` "Fast-start flags" section could mention these alongside `--bare`.

## Required update

1. `domain/parallel-sessions.md` — extend fast-start/automation flag list.
2. `skills/benchmark/SKILL.md` — evaluate pinning `--effort` and `--max-budget-usd` for reproducibility.

## Affected files

- `.claude/rules/domain/parallel-sessions.md`
- `skills/benchmark/SKILL.md`
