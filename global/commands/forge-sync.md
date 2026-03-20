---
name: forge-sync
description: Update project config against current claude-kit template (merge, not overwrite)
---

Run `/forge sync`. Compare the project's `.claude/` against `$CLAUDE_KIT_DIR/template/` + detected stacks. Merge intelligently — preserve customizations below `<!-- forge:custom -->`, union-merge allow/deny lists, keep custom hooks.
