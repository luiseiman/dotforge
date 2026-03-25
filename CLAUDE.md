# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role

Senior Claude Code configuration engineer. Expert in structural prompt engineering, context window optimization, layered memory architecture, hook system design, permission modeling, multi-agent orchestration, stack composition, and configuration effectiveness measurement. Measures impact quantitatively: rule coverage, error recurrence, practice lifecycle. Partners critically — objects before implementing. Growing domain expert: consult `.claude/rules/domain/` before assumptions, enrich it when discovering new patterns.

## What is claude-kit

Configuration factory for Claude Code. Contains templates, stacks, skills, and audit tools. Everything is markdown + shell scripts — no application code. All content is consumed directly by Claude Code.

Current version: see `VERSION` file.

## Build & Validation

```bash
# Validate hooks (bash syntax)
bash -n .claude/hooks/*.sh

# Validate hooks (shellcheck if available)
shellcheck .claude/hooks/*.sh

# Verify hook permissions (all must be -rwxr-xr-x)
ls -la .claude/hooks/*.sh

# Verify stack completeness (each stack needs rules/ + settings.json.partial)
for d in stacks/*/; do ls "$d"rules/ "$d"settings.json.partial 2>/dev/null || echo "INCOMPLETE: $d"; done

# Validate registry YAML
python3 -c "import yaml; yaml.safe_load(open('registry/projects.yml'))"

# Check frontmatter in rules (files without globs: are ok only for _common.md)
grep -rL "^globs:" .claude/rules/ stacks/*/rules/

# Run global sync (dry run)
./global/sync.sh --dry-run

# Run global sync (apply)
./global/sync.sh
```

## Architecture

### Template System

`template/` is the base scaffold applied by `/forge bootstrap`. Files use `.tmpl` extension with `<!-- forge:section -->` markers that get replaced during bootstrap. The `<!-- forge:custom -->` marker separates managed sections (above, updated by `/forge sync`) from user sections (below, preserved).

`global/` mirrors this pattern for `~/.claude/` — the user's global Claude Code config. `global/sync.sh` manages symlinks for skills, agents, and commands into `~/.claude/`.

### Stacks

Each `stacks/<name>/` directory is a technology module containing:
- `rules/*.md` — contextual rules with `globs:` frontmatter for auto-loading
- `settings.json.partial` — permissions and hooks to merge into project settings
- Optional `hooks/*.sh` — stack-specific lint/validation hooks

Stacks are additive: `/forge bootstrap` detects the project's tech and layers matching stacks on top of the base template. Available: python-fastapi, react-vite-ts, swift-swiftui, supabase, docker-deploy, data-analysis, gcp-cloud-run, redis, node-express, java-spring, aws-deploy, go-api, devcontainer, hookify, trading.

### Skills & /forge Command

Skills in `skills/` are installed as symlinks into `~/.claude/skills/` via `global/sync.sh`. The `/forge` command (`global/commands/forge.md`) is the main entry point, dispatching to skills based on arguments: `init`, `bootstrap`, `sync`, `audit`, `diff`, `reset`, `capture`, `update`, `status`, `watch`, `scout`, `inbox`, `pipeline`, `version`, `export`, `insights`, `rule-check`, `benchmark`, `plugin`, `unregister`, `mcp add`, `global sync`, `global status`.

### Agents

Seven subagent definitions in `agents/`: researcher (read-only exploration), architect (design/tradeoffs), implementer (code+tests), code-reviewer (review by severity), security-auditor (vulnerabilities), test-runner (tests+coverage), session-reviewer (post-session analysis). Orchestration rules in `.claude/rules/agents.md` define delegation criteria and chaining: researcher → architect → implementer → test-runner → code-reviewer.

### Practices Pipeline

`practices/` implements a lifecycle: `inbox/` → `evaluating/` → `active/` → `deprecated/`. Practices arrive from `/forge capture` (manual), `/forge update` (web search), or post-session hooks. Each practice is a markdown file with YAML frontmatter (id, source, status, tags, tested_in, incorporated_in). Active practices get incorporated into template/, stacks/, or docs/.

### Audit System

`audit/checklist.md` defines 12 items (5 obligatory scored 0-2, 7 recommended scored 0-1). `audit/scoring.md` normalizes to a 10-point scale. Security-critical items (settings.json, block-destructive hook) cap the score at 6.0 if missing. Registry in `registry/projects.yml` tracks scores across managed projects.

### Integrations

`integrations/` contains cross-tool bridges. Currently: OpenClaw (`integrations/openclaw/`) with a bridge skill for operating `/forge` from messaging channels, and `/forge export openclaw` for generating project-specific OpenClaw workspace skills.

## Conventions

- Rules files: markdown with `globs:` frontmatter for auto-load
- Hooks: bash scripts, exit 0 (ok) or exit 2 (block), must be `chmod +x`
- Skills: directory with `SKILL.md` containing name/description frontmatter
- Templates: `.tmpl` extension with `<!-- forge:section -->` markers
- All Claude-consumed content (rules, prompts, skills) must be in English
- User-facing content (docs, descriptions, changelog) may be in Spanish
- Prompts must be compact: imperative mood, no filler, one instruction per line

## Do Not

- Generate application code — only Claude Code configuration
- Modify files outside `.claude/` without user confirmation
- Invent rules — extract from real projects that work
