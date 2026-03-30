---
id: practice-2026-03-30-globs-vs-paths-frontmatter
title: "Rules frontmatter: globs (eager) vs paths (lazy) — correct usage patterns"
source: "watch-upstream — github.com/anthropics/claude-code/issues/17204"
source_type: research
discovered: 2026-03-30
status: active
tags: [rules, frontmatter, path-scoping, verified]
tested_in: [claude-kit]
incorporated_in: [.claude/rules/domain/rule-effectiveness.md, docs/best-practices.md, docs/usage-guide.md, docs/guia-uso.md]
replaced_by: null
effectiveness: not-applicable
error_type: null
---

## Description

Claude Code rules support two frontmatter fields for file matching: `globs:` (eager loading) and `paths:` (lazy loading with `alwaysApply: false`). Both work, but `paths:` has strict format requirements.

## Evidence

Issue #17204 (open) + reverse-engineering by @Johntycour (#19377) + verification by @maxjeltes:

| Format | Loading | Result |
|--------|---------|--------|
| `globs: **/*.ts, **/*.tsx` | Eager (always in context) | ✅ Works |
| `paths: **/*.ts` (unquoted CSV) + `alwaysApply: false` | Lazy (on file match) | ✅ Works |
| `paths: "**/*.ts"` (quoted) | — | ❌ Fails silently (parser bug) |
| `paths:` + YAML array | — | ❌ Fails silently (parser bug) |
| `globs:` without `alwaysApply: false` | Eager | ✅ Works (but NOT lazy) |

Root cause: The internal `_9A()` parser expects a plain string and splits by comma. YAML arrays produce JS Array objects, and quotes are not stripped — both cause silent failure.

Key insight: `globs:` alone does NOT lazy-load. `alwaysApply: false` is required for lazy loading, and only works with `paths:`.

Related bugs: #21858 (paths: ignored in ~/.claude/rules/), #16299 (paths: loads globally), #23569 (paths: ignored in worktrees).

## Implication for claude-kit

**claude-kit's use of `globs:` is CORRECT for eager loading.** For projects with many rules where context optimization matters, `paths:` as unquoted CSV + `alwaysApply: false` enables lazy loading.

## Working patterns

| Goal | Frontmatter |
|------|------------|
| Eager (always in context) | `globs: **/*.ts, **/*.tsx` |
| Lazy (on file match only) | `alwaysApply: false` + `paths: **/*.ts, **/*.tsx` |

## Incorporated

Updated `.claude/rules/domain/rule-effectiveness.md` with eager vs lazy loading documentation. Updated all docs (best-practices, usage-guide, guia-uso, creating-stacks, config-validation, CLAUDE.md, skills) to reflect both loading modes.
