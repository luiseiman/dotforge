---
name: project-rename-pattern
description: Pattern for bulk project renames across docs — correct substitution order to avoid partial matches
type: feedback
---

Use Python `re.sub` with ordered replacements for bulk renaming. Order matters: most-specific patterns first (GitHub URL, env vars, snake_case fields) before simple kebab-case. This avoids partial match issues where `claude-kit/stacks` would otherwise be missed if `claude-kit` → `dotforge` ran first and left `dotforge/stacks` unchanged.

**Why:** sed -i with multiple -e patterns can collide; Python re.sub with explicit pattern list is safer and auditable.

**How to apply:** When a rename task covers >5 files, write a Python script with an explicit `replacements` list, run it, then grep to verify zero residual matches.
