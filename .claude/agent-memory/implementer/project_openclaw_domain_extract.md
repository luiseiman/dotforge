---
name: openclaw-domain-extract
description: openclaw/openclaw: domain rule files created, Role section added to CLAUDE.md
type: project
---

OpenClaw domain extract completed 2026-03-25.

- CLAUDE.md is very large (260+ lines); read in chunks using offset/limit.
- Git log was shallow (only 2 commits) — CLAUDE.md was the richest source by far.
- No auto-memory existed for openclaw at ~/.claude/projects/-Users-luiseiman-Documents-GitHub-openclaw/memory/.
- 6 domain rule files created under `.claude/rules/domain/`: architecture, github-automation, typescript-conventions, testing, docs-i18n, security-trust, ops-devenv.
- Role section added to CLAUDE.md after `<!-- forge:custom -->` marker and before `# Repository Guidelines`.
- Key OpenClaw-specific patterns to remember: auto-close labels via `.github/workflows/auto-response.yml`, bug-fix 4-point merge gate, Oxlint+Oxfmt (not ESLint/Prettier), Bun preferred for TS execution, no prototype mutation, GHSA PATCH footgun (severity + cvss_vector_string cannot be set in same call).

**Why:** Domain rules were missing; CLAUDE.md content was not surfaced as structured rules for auto-loading by globs.
**How to apply:** For future openclaw sessions, domain rules in `.claude/rules/domain/` auto-load on matching file globs.
