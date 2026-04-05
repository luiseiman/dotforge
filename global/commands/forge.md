---
name: forge
description: dotforge configuration factory — bootstrap, audit, sync, and manage Claude Code projects
---

You are the dotforge operator, the configuration factory for Claude Code.
The dotforge project lives in `$DOTFORGE_DIR/`.

## Registry

The registry file for reading AND writing project data is always:
`$DOTFORGE_DIR/registry/projects.local.yml`

If it doesn't exist, create it by copying the header from `registry/projects.yml` with `projects: []`.
NEVER write project data to `registry/projects.yml` (that's the template shipped with the repo).

## Preconditions

BEFORE dispatching any action, verify the preconditions in the table.
If not met, show the error message and DO NOT execute the skill.

| Action | Requires | On failure |
|--------|----------|------------|
| `bootstrap` | — | — |
| `audit` | — | If `.claude/.forge-manifest.json` missing, warn that score has no comparison baseline (but execute anyway) |
| `sync` | `CLAUDE.md` + `.claude/settings.json` | "This project has no dotforge config. Run `/forge bootstrap` first." |
| `diff` | `.claude/.forge-manifest.json` | "No previous sync manifest found. Run `/forge bootstrap` to initialize or `/forge audit` to evaluate current state." |
| `reset` | `.claude/` directory exists | "No configuration to reset. Run `/forge bootstrap` to initialize." |
| `export` | `CLAUDE.md` + `.claude/settings.json` | "No configuration to export. Run `/forge bootstrap` first." |
| `insights` | `CLAUDE_ERRORS.md` or `.claude/agent-memory/` | "No history to analyze. Use the project for a while and try again." |
| `plugin` | `CLAUDE.md` + `.claude/settings.json` | "No configuration to convert into a plugin. Run `/forge bootstrap` first." |
| `rule-check` | `.claude/rules/` with at least 1 rule | "No rules to evaluate. Run `/forge bootstrap` first." |
| `benchmark` | `.claude/settings.json` + `CLAUDE.md` + clean git repo | "Requires project with dotforge config and clean working tree." |
| `mcp add <server>` | target `settings.json` exists (project) OR `--global` flag | If no settings.json: "No settings.json found. Run `/forge bootstrap` first, or use `--global` to install globally." |
| `domain extract` | `CLAUDE.md` or `.claude/` | "No configured project found. Run `/forge init` or `/forge bootstrap` first." |
| `domain list` | `.claude/rules/domain/` | "No domain rules found. Run `/forge domain extract` to generate from existing sources." |
| `domain sync-vault` | `.claude/rules/domain/` with at least 1 file with `domain_source: vault://` | "No vault-linked domain rules found." |
| `learn` | project source code exists | "No source code found to scan." |
| `capture` | — | — |
| `update` | — | — |
| `watch` | — | — |
| `scout` | — | — |
| `inbox` | — | — |
| `pipeline` | — | — |
| `status` | — | — |
| `global sync` | — | — |
| `global status` | — | — |
| `version` | — | — |

## Action by $ARGUMENTS

### `audit`
Run the `/audit-project` skill on the current project.
Read `$DOTFORGE_DIR/audit/checklist.md` and `scoring.md` as reference.

### `sync`
Run the `/sync-template` skill on the current project.
Compare against `$DOTFORGE_DIR/template/` + detected stacks.

### `init`
Run the `/init-project` skill on the current project.
auto-detects stacks, asks 4 quick questions to understand the project, generates complete config.
Output: single line with detected stacks and score.

### `bootstrap` or `bootstrap --profile <minimal|standard|full>`
Run the `/bootstrap-project` skill on the current project.
Use `$DOTFORGE_DIR/template/` as base.
Pass the selected profile (default: `standard`).

### `global sync`
Update dotforge and sync `~/.claude/`:

0. **Auto-update**: If `$DOTFORGE_DIR` is a git repo, run `git -C "$DOTFORGE_DIR" pull --ff-only 2>&1`. Show result:
   - If updated: `✓ dotforge updated: {old_hash}..{new_hash}`
   - If already up to date: `✓ dotforge already up to date`
   - If pull fails (dirty tree, conflicts): `⚠ Auto-update failed: {reason}. Run 'cd $DOTFORGE_DIR && git pull' manually.`

1. **CLAUDE.md**: compare `~/.claude/CLAUDE.md` against `global/CLAUDE.md.tmpl`.
   - Sections BEFORE `<!-- forge:custom -->` are updated from the template.
   - Sections AFTER `<!-- forge:custom -->` are preserved intact.
   - If `<!-- forge:custom -->` doesn't exist, add the marker and preserve everything not in the template.

2. **settings.json**: merge deny list from `global/settings.json.tmpl` with `~/.claude/settings.json`.
   - Deny list: union of sets (add missing, never remove).
   - Allow list: preserve what the user has.
   - Hooks: preserve existing, add detect-claude-changes if not present.
   - Resolve `$DOTFORGE_DIR` in the template to the actual dotforge directory before merging.
   - NEVER touch `skipDangerousModePermissionPrompt` — user decision only.

3. **Symlinks**: run `global/sync.sh` for skills, agents, commands.

4. Show summary of changes.

### `global status`
Show state of `~/.claude/` vs template:
```
═══ GLOBAL STATUS ═══
CLAUDE.md:    ✓/✗ synced
settings.json: deny list N items (template: M)
Skills:       N/M installed
Agents:       N/M installed
Commands:     forge.md (symlink/file/missing)
```

### `export <cursor|codex|windsurf|openclaw>`
Run the `/export-config` skill with the specified target.
Export the current project's dotforge config to a format compatible with another tool.

### `diff`
Run the `/diff-project` skill on the current project.
Compare the project's config against the current dotforge version.
Show what changed since last sync and recommend whether to sync.

### `reset`
Run the `/reset-project` skill on the current project.
Restore `.claude/` from the dotforge template, with mandatory backup and rollback option.

### `status`
Read `$DOTFORGE_DIR/registry/projects.local.yml` (if exists) or `$DOTFORGE_DIR/registry/projects.yml` as fallback, and show:
```
═══ dotforge REGISTRY ═══
Project          Stack                    Score   Trend     Last audit
──────────────────────────────────────────────────────────────────────────
my-api           python-fastapi, docker   9.5     ▁▃▇ ↑    2026-03-19
my-frontend      react-vite-ts            7.2     ▇▅▃ ↓    2026-03-18
...
```

**Trend visualization:**
- Show ASCII sparkline from last 5 audit scores in `history[]`
- Arrow: ↑ (improving: last > first), → (stable: delta < 0.5), ↓ (declining: last < first)

**Alerts:**
- If any project's score dropped >1.5 points between last two audits: show `⚠️ ALERT: {{project}} score dropped {{delta}} points`
- If any project has score < 7.0 and dotforge has a newer version than their last sync: show `💡 {{project}}: run /forge sync (current: v{{their_version}}, available: v{{latest}})`

### `rule-check`
Run the `/rule-effectiveness` skill on the current project.
Cross-reference globs from `.claude/rules/*.md` against `git log --name-only` to classify rules as active (>50% match), occasional (10-50%), or inert (<10%).
Report rule coverage and directories without coverage.

### `benchmark`
Run the `/benchmark` skill on the current project.
Compare full vs minimal config by running the same standard task in two isolated worktrees.
Load task from `$DOTFORGE_DIR/tests/benchmark-tasks/{stack}.yml` based on detected stack.
**Requires explicit user confirmation** (runs Claude Code twice).

### `plugin [output-dir]`
Run the `/plugin-generator` skill on the current project.
Generate a Claude Code plugin package from the project's dotforge config.
Output is a directory ready for `claude --plugin-dir` or marketplace submission.
If output-dir not specified, defaults to `./dotforge-plugin/`.

### `insights`
Run the `/session-insights` skill on the current project.
Analyze usage patterns, frequent errors, most-edited files, and score trends.
Generate recommendations and feed the practices pipeline automatically.

### `unregister <project-name>`
Remove a project from the local registry (`$DOTFORGE_DIR/registry/projects.local.yml`).
1. Read the registry file
2. Find the project by name (case-insensitive)
3. If not found, show: "Project '{{name}}' not found in registry."
4. If found, show project details (name, path, stacks, score) and ask for confirmation
5. On confirm: remove the entry from the YAML, save file
6. Show: "✓ {{name}} removed from registry. Config in the project directory is untouched."

This does NOT delete `.claude/` from the project — only removes it from tracking.

### `mcp add <server> [--global]`
Run the `/mcp-add` skill with the specified server.
Install an MCP server template from `$DOTFORGE_DIR/mcp/<server>/` into the current project's config
(or global with `--global`): merge mcpServers into settings.json, add permissions, and copy rules.md.
Available servers: `github`, `postgres`, `supabase`, `redis`, `slack`.

### `capture <description>`
Run the `/capture-practice` skill with the provided description.
Record a discovered insight or practice in practices/inbox/.
Example: `/forge capture "hooks should ignore files in migrations/"`

### `update`
Run the `/update-practices` skill.
Pipeline: process inbox → evaluate → incorporate → suggest propagation.

### `watch`
Run the `/watch-upstream` skill.
Search for updates in official Anthropic/Claude Code docs.
Compare against current template and rules. Report deltas.
DO NOT auto-incorporate — report only.

### `scout`
Run the `/scout-repos` skill.
Read repos from `$DOTFORGE_DIR/practices/sources.yml`.
Compare their `.claude/` configs against template.
Report interesting patterns. DO NOT auto-incorporate.

### `inbox`
List pending practices in `$DOTFORGE_DIR/practices/inbox/`.
Show title, date, source_type, and tags for each one.

### `pipeline`
Show practices pipeline status:
```
═══ PRACTICES PIPELINE ═══
Inbox:      {{N}} pending
Evaluating: {{N}} under review
Active:     {{N}} incorporated
Deprecated: {{N}} retired
Last update: {{date}}
```
Read from practices/inbox/, evaluating/, active/, deprecated/.

### `learn`
Run the `/learn-project` skill on the current project.
Scan source code to detect patterns (ORM, auth, testing, naming, deployment) and propose domain rules based on what the code actually does. Unlike `domain extract` (which reads dotforge memory), `learn` reads the CODE directly.

### `domain extract`
Run the `/domain-extract` skill on the current project.
Analyze existing sources (CLAUDE.md, auto-memory, CLAUDE_ERRORS.md, agent-memory, rules, git log) and propose domain rules for user approval.

### `domain list`
List `.claude/rules/domain/` with status of each file (domain tag, globs, last_verified, staleness).
If directory doesn't exist: "No domain rules found. Run `/forge domain extract` to generate from existing sources."

### `domain sync-vault`
Run the `/domain-extract` skill with sync-vault flag.
For domain rules with `domain_source: vault://path` in frontmatter, compare against the vault note and propose updates.

### `version`
Read `$DOTFORGE_DIR/VERSION` and display.

### No arguments
Show help:
```
/forge <command>

Commands:
  init          Quick setup — auto-detects stacks, asks 4 questions, generates complete config
  audit         Audit current project against template
  sync          Sync config against template
  bootstrap     Initialize .claude/ in new project [--profile minimal|standard|full]
  export        Export config to cursor|codex|windsurf|openclaw
  diff          What changed since last sync
  reset         Restore .claude/ from template (with backup)
  global sync   Sync ~/.claude/ against global template
  global status State of ~/.claude/ vs template
  status        View project registry, scores, and trends
  rule-check    Detect inert rules by crossing globs against git history
  benchmark     Compare full vs minimal config on standardized tasks
  plugin        Generate plugin package for Claude Code marketplace
  insights      Analyze past sessions and generate recommendations
  unregister    Remove project from registry (does not delete config)
  mcp add       Install MCP server template in project or global [--global]
  learn           Scan code to detect patterns and propose domain rules
  domain extract  Extract domain knowledge from existing project sources
  domain list     List domain rules with status
  domain sync-vault  Sync domain rules with vault notes
  capture       Record discovered insight or practice
  update        Practices update pipeline
  watch         Check for updates in Anthropic docs
  scout         Review curated repos
  inbox         View pending practices
  pipeline      Practices lifecycle status
  version       Show dotforge version
```
