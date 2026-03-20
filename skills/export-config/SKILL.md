---
name: export-config
description: Export claude-kit configuration to other AI code editors (Cursor, Codex, Windsurf).
---

# Export Configuration

Convert the current project's claude-kit configuration into formats compatible with other AI coding tools.

## Input
$ARGUMENTS contains the target format: `cursor`, `codex`, or `windsurf`.

If no argument provided, show available targets and ask.

## Step 1: Read current configuration

Read these files from the current project:
- `CLAUDE.md` — project instructions
- `.claude/rules/*.md` — contextual rules (strip YAML frontmatter)
- `.claude/settings.json` — permissions and hooks

If none exist, error: "No claude-kit configuration found. Run `/forge bootstrap` first."

## Step 2: Transform based on target

### `cursor` → `.cursorrules`

Generate a single `.cursorrules` file at project root:
1. Extract content from `CLAUDE.md` (skip forge markers)
2. Append all rules from `.claude/rules/*.md` (strip `globs:` frontmatter, keep content)
3. Convert deny list to text: "DO NOT: read/modify files matching: .env, *.key, *.pem, *credentials*"
4. Convert hooks to text instructions: "Before executing bash commands, check for destructive patterns: rm -rf, DROP TABLE, force push"
5. Wrap in a single markdown document

### `codex` → `AGENTS.md`

Generate `AGENTS.md` at project root:
1. Start with project context from `CLAUDE.md`
2. Append rules as "## Rules" section
3. Convert permissions to "## Permissions" section: list allowed and denied commands
4. Add "## Workflow" section from agent orchestration rules if present
5. Format as flat markdown (Codex expects simple instructions)

### `windsurf` → `.windsurfrules`

Generate `.windsurfrules` at project root:
1. Same content extraction as cursor
2. Windsurf format is similar to `.cursorrules` — single markdown file
3. Add Windsurf-specific header: "You are an AI assistant working on this project."
4. Append all rules and converted hooks/permissions

## Step 3: Handle conflicts

Before writing:
1. Check if target file already exists
2. If exists: show diff preview and ask user to confirm overwrite
3. If user declines: suggest alternative filename (e.g., `.cursorrules.claude-kit`)

## Step 4: Report

Show:
```
Export complete: {{target}}
  Output: {{filename}}
  Sources: CLAUDE.md, {{N}} rules, settings.json
  Note: hooks and deny list converted to text instructions (no enforcement outside Claude Code)
```

Warn: "Exported rules are advisory only. Hook enforcement (destructive command blocking) only works in Claude Code."

## Limitations

- Hooks cannot be enforced outside Claude Code — converted to text instructions
- Agent orchestration is Claude Code-specific — simplified to workflow instructions
- Stack-specific rules are included but glob-based auto-loading is Claude Code-only
