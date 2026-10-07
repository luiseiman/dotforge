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

Stacks are additive: `/forge bootstrap` detects the project's tech and layers matching stacks on top of the base template. Available (17): python-fastapi, react-vite-ts, swift-swiftui, supabase, docker-deploy, data-analysis, gcp-cloud-run, redis, node-express, java-spring, aws-deploy, go-api, devcontainer, hookify, trading, tdd, vps-ssh. `stacks/detect.md` is the detection table.

### Skills & /forge Command

Skills in `skills/` are installed as symlinks into `~/.claude/skills/` via `global/sync.sh`. The `/forge` command (`global/commands/forge.md`) is the main entry point, dispatching to skills based on arguments: `init`, `bootstrap`, `sync`, `sync-all`, `audit`, `diff`, `reset`, `capture`, `update`, `status`, `watch`, `scout`, `inbox`, `pipeline`, `version`, `export`, `insights`, `rule-check`, `plugin`, `unregister`, `mcp add`, `learn`, `domain extract|sync-vault|list`, `behavior <subcommand>`, `global sync`, `global status`. Standalone commands outside the dispatcher: `forge-ultracode-check`, `forge-compact-task`, `forge-context-status`, `cap`.

### Agents

Seven subagent definitions in `agents/`: researcher (read-only exploration), architect (design/tradeoffs), implementer (code+tests), code-reviewer (review by severity), security-auditor (vulnerabilities), test-runner (tests+coverage), session-reviewer (post-session analysis). Orchestration rules in `.claude/rules/agents.md` define delegation criteria and chaining: researcher → architect → implementer → test-runner → code-reviewer.

### Practices Pipeline

`practices/` implements a lifecycle: `inbox/` → `evaluating/` → `active/` → `deprecated/`. Practices arrive from `/forge capture` (manual), `/forge update` (web search), or post-session hooks. Each practice is a markdown file with YAML frontmatter (id, source, status, tags, tested_in, incorporated_in). Active practices get incorporated into template/, stacks/, or docs/.

### Audit System

Two-dimension model (v4.x). **Dimension A — Native Health** (`score`, 0-10): 5 obligatory items (0-2) + 10 recommended (0-1), normalized as `obligatory*0.7 + recommended*0.3`. Security-critical items (settings.json, block-destructive hook) cap it at 6.0 if missing. Measures good use of native Claude Code (auto-memory as index, permission cascade, attribution, sandbox, deny rules). **Dimension B — dotforge Adoption** (`forge_adoption`, 0-4): behaviors/workflows/domain-rules/sync-recency. **Informational — does NOT affect Native Health.** A native-first project scoring B=0 with A=10 is a desirable outcome (see `.claude/rules/domain/native-vs-dotforge-boundary.md`). `audit/checklist.md` + `audit/scoring.md` are the source of truth; the registry tracks both across managed projects — always `registry/projects.local.yml` (gitignored, per machine); `registry/projects.yml` is the shipped template and a read-only fallback. Item 9 (sandbox) is deliberately 0 for dotforge itself: its job is cross-project (`sync-all` writes to every repo under `~/Documents`, `global/sync.sh` to `~/.claude`), so a sandbox would need those paths in `allowWrite` and protect nothing. **Two scoring engines reimplement the checklist independently — `audit/score.sh` (bash, CI gate) and `scripts/audit_all.py` (Python, 12-project re-auditor). Any checklist change must update BOTH plus `audit.yml` and the docs (`README.md`, `docs/usage-guide.md`, `docs/guia-uso.md`); grep all consumers before planning the edit.**

### Integrations

`integrations/` contains cross-tool bridges. Currently: OpenClaw (`integrations/openclaw/`) with a bridge skill for operating `/forge` from messaging channels, and `/forge export openclaw` for generating project-specific OpenClaw workspace skills.

### v3 Behavior Governance (shipped v3.0 → maintained; status as of v4.7)

`behaviors/`, `scripts/runtime/`, `scripts/compiler/`, `scripts/forge-behavior/`, and `skills/forge-behavior/` implement the behavior governance layer. Unlike the configuration layer (rules, stacks, skills, agents), behaviors enforce runtime policies on tool calls via compiled `PreToolUse` hooks that share a session-scoped state file, with graduated escalation (silent → nudge → warning → soft_block → hard_block).

Core pieces:

- `behaviors/<id>/behavior.yaml` — declarative policy (triggers, escalation, rendering). Schema: `docs/v3/SCHEMA.md`.
- `behaviors/index.yaml` — catalogue + on/off. Enabled: `no-destructive-git`, `verify-before-done`. Disabled: `search-first` (false positives, v3.6.1), `respect-todo-state` (todo tools removed on current models, v4.4.0), `plan-before-code` and `objection-format` (opt-in).
- `scripts/runtime/lib.sh` — shared bash API: mkdir-based lock, counters, flags, pending_blocks, session overrides, 24h TTL. Sourced by compiled hooks.
- `scripts/compiler/compile.sh` — YAML → one bash hook per trigger plus a `settings.json` snippet. Needs a `python3` with PyYAML (on macOS use `/usr/local/bin/python3`, not `/usr/bin/python3`). Output contract (v4.7.0): nudge/warning → `hookSpecificOutput.additionalContext` (model-visible) + `systemMessage` (user-visible); blocks → `permissionDecision: "deny"` + `permissionDecisionReason`. `systemMessage` alone never reaches the model — that was the pre-v4.7.0 defect.
- `scripts/forge-behavior/cli.sh` — `/forge behavior` CLI: `list`, `describe`, `status`, `on`/`off` (project or session scope), `strict`/`relaxed`.
- `.forge/runtime/state.json` — per-session counters, flags, pending_blocks. Gitignored, per-machine. The override audit trail (`.forge/audit/overrides.log`) was retired in v4.0.x after a portfolio scan found 0 overrides.
- Compiled hooks live in `.claude/hooks/generated/` and are committed; recompile after any `compile.sh` change (`for b in no-destructive-git verify-before-done; do bash scripts/compiler/compile.sh behaviors/$b/behavior.yaml .claude/hooks/generated; done`). Projects that adopted behaviors carry their own compiled copies — `/forge sync` must recompile them.

Specs of record under `docs/v3/`: `SPEC.md` (evaluation algorithm, level table), `SCHEMA.md`, `RUNTIME.md`, `COMPILER.md`, `DECISIONS.md`. Historical: `SCOPE.md`, `COMPETITIVE.md`, `AUDIT.md` (retired override log), `MIGRATION.md`. Verdict on scope: `.claude/rules/domain/native-vs-dotforge-boundary.md` — keep the escalation engine, no Claude Mods (`--target mod`) backend until the Mods API stabilizes (practice in `practices/inbox/`).

Tests: `bash tests/run_all.sh` runs every suite (hooks, rules lint, skills index, config self-test, v3 runtime 8 + compiler 1 + CLI 5 + 17 behavior scenarios) — same set as CI. `--quick` skips the behavior scenarios.

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
