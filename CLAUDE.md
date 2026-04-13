# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role

Senior Claude Code configuration engineer. Expert in structural prompt engineering, context window optimization, layered memory architecture, hook system design, permission modeling, multi-agent orchestration, stack composition, and configuration effectiveness measurement. Measures impact quantitatively: rule coverage, error recurrence, practice lifecycle. Partners critically — objects before implementing. Growing domain expert: consult `.claude/rules/domain/` before assumptions, enrich it when discovering new patterns.

## What is dotforge

Configuration governance for Claude Code. Contains templates, stacks, skills, and audit tools. Everything is markdown + shell scripts — no application code. All content is consumed directly by Claude Code.

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

# Check frontmatter in rules (files without globs:/paths: are ok only for _common.md)
grep -rL "^globs:\|^paths:" .claude/rules/ stacks/*/rules/

# Run global sync (dry run)
./global/sync.sh --dry-run

# Run global sync (apply)
./global/sync.sh
```

## Architecture

### Template System

`template/` is the base scaffold applied by `/forge bootstrap`. Files use `.tmpl` extension with `<!-- forge:section -->` markers that get replaced during bootstrap. The `<!-- forge:custom -->` marker separates managed sections (above, updated by `/forge sync`) from user sections (below, preserved).

Key template files: `rules/domain-learning.md` (globs:**/* rule that instructs Claude to persist domain discoveries to `.claude/rules/domain/`), `hooks/post-compact.sh` (PostCompact hook — writes compact summary + git state to `.claude/session/last-compact.md`), `hooks/session-restore.sh` (SessionStart hook — re-injects last-compact.md when resuming after compaction).

`global/` mirrors this pattern for `~/.claude/` — the user's global Claude Code config. `global/sync.sh` manages symlinks for skills, agents, and commands into `~/.claude/`.

### Stacks

Each `stacks/<name>/` directory is a technology module containing:
- `rules/*.md` — contextual rules with `globs:` (eager) or `paths:` + `alwaysApply: false` (lazy) frontmatter
- `settings.json.partial` — permissions and hooks to merge into project settings
- Optional `hooks/*.sh` — stack-specific lint/validation hooks

Stacks are additive: `/forge bootstrap` detects the project's tech and layers matching stacks on top of the base template. Available: python-fastapi, react-vite-ts, swift-swiftui, supabase, docker-deploy, data-analysis, gcp-cloud-run, redis, node-express, java-spring, aws-deploy, go-api, devcontainer, hookify, trading, tdd.

### Skills & /forge Command

Skills in `skills/` are installed as symlinks into `~/.claude/skills/` via `global/sync.sh`. The `/forge` command (`global/commands/forge.md`) is the main entry point, dispatching to skills based on arguments: `init`, `bootstrap`, `sync`, `audit`, `diff`, `reset`, `capture`, `update`, `status`, `watch`, `scout`, `inbox`, `pipeline`, `version`, `export`, `insights`, `rule-check`, `benchmark`, `plugin`, `unregister`, `mcp add`, `domain extract|sync-vault|list`, `global sync`, `global status`.

### Agents

Seven subagent definitions in `agents/`: researcher (read-only exploration), architect (design/tradeoffs), implementer (code+tests), code-reviewer (review by severity), security-auditor (vulnerabilities), test-runner (tests+coverage), session-reviewer (post-session analysis). Orchestration rules in `.claude/rules/agents.md` define delegation criteria and chaining: researcher → architect → implementer → test-runner → code-reviewer.

### Practices Pipeline

`practices/` implements a lifecycle: `inbox/` → `evaluating/` → `active/` → `deprecated/`. Practices arrive from `/forge capture` (manual), `/forge update` (web search), or post-session hooks. Each practice is a markdown file with YAML frontmatter (id, source, status, tags, tested_in, incorporated_in). Active practices get incorporated into template/, stacks/, or docs/.

### Audit System

`audit/checklist.md` defines 12 items (5 obligatory scored 0-2, 7 recommended scored 0-1). `audit/scoring.md` normalizes to a 10-point scale. Security-critical items (settings.json, block-destructive hook) cap the score at 6.0 if missing. Registry in `registry/projects.yml` tracks scores across managed projects.

### Integrations

`integrations/` contains cross-tool bridges. Currently: OpenClaw (`integrations/openclaw/`) with a bridge skill for operating `/forge` from messaging channels, and `/forge export openclaw` for generating project-specific OpenClaw workspace skills.

### v3 Behavior Governance (alpha — Phase 1 complete)

`behaviors/`, `scripts/runtime/`, `scripts/compiler/`, `scripts/forge-behavior/`, and `skills/forge-behavior/` together implement the v3 behavior governance layer. Unlike the v2 configuration layer (rules, stacks, skills, agents), v3 behaviors enforce runtime policies on tool calls via compiled `PreToolUse` hooks that share a session-scoped state file.

Core pieces:

- `behaviors/<id>/behavior.yaml` — declarative policy (triggers, escalation, rendering). Schema: `docs/v3/SCHEMA.md`.
- `behaviors/index.yaml` — active behavior catalogue, evaluation order.
- `scripts/runtime/lib.sh` — shared bash API: mkdir-based lock, counters, flags, pending_blocks, overrides. Sourced by compiled hooks. Tested via `scripts/runtime/tests/run_all.sh`.
- `scripts/compiler/compile.sh` — YAML → bash hook per trigger, plus `settings.json` snippet. Tested via `scripts/compiler/tests/run_all.sh`.
- `scripts/forge-behavior/cli.sh` — `/forge behavior` CLI: `status`, `on`/`off` (project or session scope), `strict`/`relaxed`. Tested via `scripts/forge-behavior/tests/run_all.sh`.
- `.forge/runtime/state.json` — per-session counters, flags, pending_blocks. Gitignored, per-machine.
- `.forge/audit/overrides.log` — permanent append-only soft_block override audit trail. Committed to git.

Specs of record live under `docs/v3/`: `SPEC.md` (evaluation algorithm, level table), `SCHEMA.md` (behavior.yaml v1), `RUNTIME.md` (state shape, locking, flags §4, TTL §7, reinvocation override detection §12), `AUDIT.md` (override log format), `COMPILER.md` (generation rules), `SCOPE.md` (Phase 1–3 milestones), `DECISIONS.md` (design decisions), `COMPETITIVE.md` (differentiation).

Phase 1 (this alpha): runtime + compiler + search-first end-to-end + override detection + `/forge behavior` CLI. 18 unit/integration tests green, full live smoke test executed in a real Claude Code session.

Phase 2: catalogue (verify-before-done, no-destructive-git, respect-todo-state, plan-before-code, objection-format), `/forge audit` behaviors-coverage dimension, scope: project for session-clear-resistant behaviors, reorder check_flag template to surface override detection ahead of flag consume.

Phase 3: README rewrite, CHANGELOG v3, migration guide, benchmark, marketplace update, tag v3.0.0.

## Conventions

- Rules files: markdown with `globs:` (eager) or `paths:` CSV + `alwaysApply: false` (lazy) frontmatter
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
