---
globs: "**/rules/*.md,**/stacks/*/rules/*"
description: "Rule design, glob patterns, and effectiveness measurement"
domain: claude-code-engineering
last_verified: 2026-03-25
---

# Rule Effectiveness

- Rules are .md files with YAML frontmatter containing globs: pattern
- Globs auto-load rules when edited files match — no registration needed
- Only _common.md is allowed without globs (always loaded)
- Max 50 lines per rule file; split if longer
- Each rule should include: what it covers, clear patterns, common mistakes to avoid
- Rule coverage = files touched in session that match ≥1 rule glob / total rules
- Classification: Active (>50% match rate), Occasional (10-50%), Inert (<10%)
- Inert rules waste tokens — prune or broaden globs
- Error promotion: if same error appears 3+ times → derive a rule and add to appropriate file
- Stack rules live in stacks/{name}/rules/ with settings.json.partial
- Domain rules live in .claude/rules/domain/ — project-owned, never touched by sync
