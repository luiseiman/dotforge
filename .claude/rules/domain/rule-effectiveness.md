---
globs: "**/rules/*.md,**/stacks/*/rules/*"
description: "Rule design, glob patterns, and effectiveness measurement"
domain: claude-code-engineering
last_verified: 2026-03-30
---

# Rule Effectiveness

- Rules are .md files with YAML frontmatter for conditional loading
- Two frontmatter fields: `globs:` (eager loading) and `paths:` (lazy loading with `alwaysApply: false`)
- `globs:` — always works, loads rule eagerly at session start. Preferred for lightweight rules.
- `paths:` — works ONLY as unquoted CSV (`paths: src/**/*.ts, lib/**/*.ts`). NEVER use quoted strings or YAML arrays (fail silently). Requires `alwaysApply: false` for lazy loading.
- Lazy loading (`paths:` + `alwaysApply: false`): rule loads only when Claude touches a matching file — saves context in large projects
- Eager loading (`globs:` without `alwaysApply: false`): rule loads at session start — simpler, fine for small rule sets
- Only _common.md is allowed without frontmatter (always loaded)
- Max 50 lines per rule file; split if longer
- Each rule should include: what it covers, clear patterns, common mistakes to avoid
- Rule coverage = files touched in session that match ≥1 rule glob / total rules
- Classification: Active (>50% match rate), Occasional (10-50%), Inert (<10%)
- Inert rules waste tokens — prune or broaden globs
- Error promotion: if same error appears 3+ times → derive a rule and add to appropriate file
- Stack rules live in stacks/{name}/rules/ with settings.json.partial
- Domain rules live in .claude/rules/domain/ — project-owned, never touched by sync
