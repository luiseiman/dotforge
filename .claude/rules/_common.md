---
globs: "**/*.md,**/*.sh,**/*.yml,**/*.json,**/*.tmpl,**/*.py,**/*.ts,**/*.tsx,**/*.swift"
---

# Code Rules

## Git
- Atomic commits: one logical change per commit
- Messages in imperative mood, first line <72 chars
- Never commit .env, secrets, keys, credentials
- No force push to main/master without explicit confirmation
- Branch naming: feature/, fix/, refactor/, chore/
- Customize commit/PR trailers via `attribution.commit` and `attribution.pr` in `settings.json` — supersedes the deprecated `includeCoAuthoredBy` boolean
- `attribution.sessionUrl: false` (v2.1.187+) — omit the claude.ai session link from commit and PR bodies. Privacy/exfil control for projects that publish to public GitHub; the link can leak internal session URLs. Default true. Set false at managed scope for strictest control
- `"attribution": false` (boolean, v2.1.281+) hides all attribution — but **older CLIs skip the entire settings file** that holds the boolean. In committed `.claude/settings.json` always use the object form (`{"commit": "", "pr": "", "sessionUrl": false}`); the boolean is safe only in `~/.claude/settings.json` on a machine you control. The attribution reminder no longer overrides a CLAUDE.md or memory rule against attribution (v2.1.269)
- For self-hosted GitHub/GitLab/Bitbucket, set `prUrlTemplate` to point the footer PR badge at the right host
- Before opening a PR, confirm CI is green on the base branch (`gh run list --branch main --limit 5`). A preexisting red required check blocks every PR and masks degraded workflows — fix or flag it first, don't stack new work on a blocked pipeline

## Naming
- Descriptive variable/function names, no cryptic abbreviations
- Constants in UPPER_SNAKE_CASE
- No single-letter variables except iterators (i, j, k) and lambdas

## Testing
- New functionality → test required
- Descriptive test names: test_<what>_<condition>_<expected_result>
- Do not mock what can be tested for real

## Errors
- Never empty catch — always log or re-raise
- Do not expose stack traces to end users

## Security
- Sanitize all user inputs
- No hardcoded credentials — use environment variables
- Parameterized queries (no string interpolation)
- Rate limiting on public endpoints

## Scope
- Modify only strictly necessary files
- Do not add unrequested features

## Prompt Language
- All Claude-consumed content (rules, agent prompts, skill steps, system prompts) MUST be in English
- User-facing content (docs, CLAUDE.md project descriptions, changelog) may be in Spanish
- Prompts must be compact: high information density, no filler words, no hedging
- One instruction per line, imperative mood, no "please" or "you should consider"
- If a rule can be expressed in fewer words without losing meaning, rewrite it shorter

## Practice Capture
If a task required workarounds, multiple fix attempts, real trade-offs, or revealed missing rules:
suggest `💡 Run /cap "<summary>"` at end of response. Skip for trivial/routine tasks.

## Context Continuity
After significant tasks (>3 files, architectural decisions): update `.claude/session/last-compact.md` with active constraints. Auto-re-injected after compaction.
