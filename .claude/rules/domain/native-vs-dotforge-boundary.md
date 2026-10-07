---
globs: docs/v4/*.md, behaviors/*, stacks/*, skills/*, .claude/rules/domain/*.md
description: Native-first boundary — what dotforge keeps vs cedes to native Claude Code, and the method for deciding
domain: dotforge-meta
last_verified: 2026-10-07
---

# Native vs dotforge Boundary

## Governing principle

If Claude Code resolves it natively, ADOPT the native solution. dotforge only owns
what natively has no equivalent. Scope shrinks as Claude Code grows — that is correct.

## Method (mandatory before any scope decision)

Verify the CURRENT native state against official docs (code.claude.com/docs,
anthropics/claude-code) BEFORE classifying. A scope call on stale assumptions is wrong
by default — this is why `/forge watch` (keeping domain rules current) is the INPUT that
makes boundary decisions correct, not meta-work. Never cede a capability without
confirming the native feature actually covers the real case.

## Classification (verified 2026-06-03)

KEEP — no native equivalent:
- **Domain rules** — curated encyclopedia of CC internals + business domain. Core asset.
- **Cross-project propagation with merge** — `forge:section` markers + `/forge sync`.
  Native symlinks/global CLAUDE.md only COPY, never merge per-project customization.
- **Behaviors v3 — SPLIT verdict (validated 2026-06-04).** Portfolio scan: 0 overrides
  across all 12 projects over ~7 weeks (behaviors live since v3.0, 2026-04-13), including
  production (TRADINGBOT, cotiza). Only 4/12 adopted behaviors at all.
  - KEEP the **graduated escalation engine** (silent→nudge→warning→soft_block). It is
    exercised and works — the happy path is "verify", not "override" (observed live:
    `verify-before-done` soft_blocked a push, resolved by running tests). `hookify` is
    only binary warn/block; the graduated escalation is a real, used delta.
  - RETIRE/SIMPLIFY the **auditable override trail** — the v3-vs-hookify differential is
    empirically refuted (0 uses). The v4 override-capture loop (`process-override-log.sh`,
    audit item B3, SessionStart wiring) processes a log that is always empty: machinery
    for an event that does not occur. Dead weight, not delta.
- **Registry + audit cross-project** — REORIENT: audit must measure good use of NATIVE
  features (auto-memory active, sandbox set, deny rules present, /init run), not presence
  of dotforge machinery.

CEDE — native covers it:
- Individual learning capture → native auto-memory (per-project, `~/.claude/projects/<p>/memory/`)
- Identical shared rules (no merge needed) → native symlinks in `.claude/rules/` + global CLAUDE.md
- Workflows / orchestration → `/workflows`, Agent Teams, `/deep-research` (already ceded v4)
- Base CLAUDE.md generation → `/init`
- One-shot code review → `/code-review` (`/review` alias, `--comment` on GitHub PRs + GitLab MRs, `--fix`, `--max-findings <n>|all`; medium effort also reports cleanup + CLAUDE.md-convention findings since v2.1.290)
- Model routing as a system → `/effort` (keep only as documentation)

## Anti-pattern

Building atop native internals that may change (compiled hooks depend on the hook API
shape). Every breaking upstream change forces a re-tune. Keep the native-dependent
surface minimal and validate delta demand before expanding it.
