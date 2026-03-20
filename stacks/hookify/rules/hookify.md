---
globs: ".claude/hookify.*.local.md"
---

# Hookify Dynamic Rules

## Rule File Format

Each `.claude/hookify.<rule-name>.local.md` is a dynamic hook rule:

```markdown
---
name: rule-name
enabled: true
event: bash|file|stop|prompt|all
action: warn|block
pattern: regex-pattern (shorthand for single-condition rule)
conditions:                    # (optional, for multi-condition rules)
  - field: command|file_path|new_text|old_text|user_prompt|transcript
    operator: regex_match|contains|equals|not_contains|starts_with|ends_with
    pattern: value
---

Message shown when rule triggers. Markdown supported.
```

## Creating Rules

Use `/hookify <description>` to create rules from natural language.
The skill analyzes the description and generates the appropriate .local.md file.

## Conventions

- File naming: `.claude/hookify.<short-name>.local.md`
- Files are .gitignored by default (`.local.md` suffix)
- To share rules with the team: rename to `.claude/hookify.<name>.md` (no .local)
- Keep patterns simple — complex regex is hard to debug
- Prefer `warn` over `block` unless the operation is truly dangerous
- Test rules by triggering the pattern and checking the warning appears
