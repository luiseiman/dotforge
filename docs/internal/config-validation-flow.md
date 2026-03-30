# Config Validation Flow

Internal reference for the 4-phase validation system (v1.6.0).

## Data Flow Overview

```
                          PROJECT
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   .claude/rules/     .claude/hooks/      CLAUDE_ERRORS.md
   (globs in FM)      (block + lint)      (error history)
        │                   │                   │
        │              ┌────┴────┐              │
        │              ▼         ▼              │
        │         /tmp/dest  /tmp/lint          │
        │         -blocks-   -blocks-           │
        │         {hash}     {hash}             │
        │              │         │              │
        │              └────┬────┘              │
        │                   ▼                   │
        │          session-report.sh             │
        │          (Stop hook)                  │
        │                   │                   │
        ▼                   ▼                   ▼
   ┌─────────────────────────────────────────────┐
   │     ~/.claude/metrics/{slug}/{date}.json     │
   │     (structured session data)                │
   └──────────────────┬──────────────────────────┘
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
     /forge       /forge       /forge
     insights    rule-check   benchmark
     (trends)    (coverage)   (A/B test)
          │           │           │
          └───────────┼───────────┘
                      ▼
              registry/projects.yml
              (metrics_summary)
```

## Phase 0: Structural Validation

**Tool:** `tests/test-config.sh` (30 checks)
**When:** On demand, or as part of `/forge audit` (step 1c)

```
tests/test-config.sh
        │
        ├── Hook existence: settings.json hooks[] → file exists?
        ├── Hook permissions: chmod +x?
        ├── Rule frontmatter: globs: or paths: present?
        ├── Glob validity: globs match ≥1 real file?
        ├── JSON validity: settings.json parseable?
        ├── Deny list: covers .env, *.key, *.pem?
        ├── CLAUDE.md sections: Stack, Build, Architecture?
        └── No contradictions: allow + deny same pattern?
```

**Output:** Pass/fail per check, exit code 0 (all pass) or 1 (failures).

## Phase 1: Behavioral Metrics

**Tools:** Hook counters + `session-report.sh`
**When:** Automatically every session (Stop hook)

### Counter mechanism

```
block-destructive.sh (PreToolUse, Bash)
  │ on block:
  └──→ append "timestamp pattern" >> /tmp/claude-destructive-blocks-{hash}

lint-on-save.sh (PostToolUse, Write|Edit)
  │ on lint failure:
  └──→ append "timestamp filepath" >> /tmp/claude-lint-blocks-{hash}

{hash} = md5(PWD)[0:8]  — deterministic per project, persists across hook invocations
```

### Session report collection

```
session-report.sh (Stop event)
  │
  ├── Read + delete counter files → hook_blocks, lint_blocks
  ├── git diff HEAD~1 HEAD → files_touched, recent_files
  ├── git log --since="2h" → commits
  ├── grep CLAUDE_ERRORS.md → errors_added
  ├── Cross-reference files vs rule globs → rules_matched, rule_coverage
  │
  ├──→ Write JSON to ~/.claude/metrics/{slug}/{date}.json
  │    (merge incremental if same-day)
  │
  └──→ [opt-in] Append to SESSION_REPORT.md
```

### JSON schema

```json
{
  "project": "slug",
  "date": "YYYY-MM-DD",
  "sessions": 1,
  "errors_added": 0,
  "hook_blocks": 0,
  "lint_blocks": 0,
  "files_touched": 0,
  "rules_matched": 0,
  "rules_total": 0,
  "rule_coverage": 0.00,
  "commits": 0
}
```

## Phase 2: Rule Coverage Analysis

**Tool:** `/forge rule-check` (skill: rule-effectiveness)
**When:** On demand

```
.claude/rules/*.md ──→ extract globs/paths from frontmatter
                            │
git log --name-only ──→ files touched in last N sessions
                            │
                    cross-reference
                            │
                      ┌─────┼─────┐
                      ▼     ▼     ▼
                   Active  Occ.  Inert
                   >50%   10-50%  <10%
                      │     │     │
                      ▼     ▼     ▼
                   keep  evaluate  remove candidate
```

**Value:** Works immediately on existing projects (uses git log, no session metrics needed).

## Phase 3: Practice Effectiveness

**Tool:** `practices/metrics.yml` + `/forge update` (Fase 4)
**When:** During `/forge update` runs

```
Practice activated
  │
  ├── error_targeted: "description"
  ├── error_type: syntax|logic|integration|config|security
  ├── status: monitoring
  │
  ▼ (each /forge audit or /forge update)
  │
  ├── Read CLAUDE_ERRORS.md from applied projects
  ├── Check for errors matching error_type + description
  ├── Increment recurrence_checks
  │
  ├── recurrence_checks >= 5 AND no recurrence → status: validated ✅
  └── error recurred → status: failed ⚠️ (practice needs revision)
```

**Practices without a specific error target:** `status: not-applicable` (skipped in checks).

## Phase 4: Comparative Benchmark

**Tool:** `/forge benchmark` (skill: benchmark)
**When:** On demand only, requires explicit user confirmation

```
Current project HEAD
        │
        ├──→ worktree: /tmp/bench-full-{slug}
        │    (full .claude/ config)
        │         │
        │    claude --print "{task prompt}"
        │         │
        │    measure: files, tests, lint, errors
        │
        ├──→ worktree: /tmp/bench-minimal-{slug}
        │    (minimal CLAUDE.md + settings.json only)
        │         │
        │    claude --print "{task prompt}"
        │         │
        │    measure: files, tests, lint, errors
        │
        └──→ compare + report delta
             cleanup worktrees
```

**Task definitions:** `tests/benchmark-tasks/{stack}.yml` — one per stack, `generic.yml` as fallback.

## Retroactive Analysis

For projects without session metrics (pre-v1.6.0 or freshly synced):

```
/forge insights
  │
  ├── ~/.claude/metrics/{slug}/ exists?
  │     YES → use structured JSON data
  │     NO  → retroactive mode:
  │            ├── CLAUDE_ERRORS.md → error trends by date
  │            ├── git log --since="60d" → hot files, fix frequency
  │            ├── registry history → score progression
  │            └── rule globs vs git log → estimated coverage
  │
  └── Output marked: "⚠ Inferred from git history"
```
