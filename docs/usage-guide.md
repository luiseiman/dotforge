# Usage Guide — claude-kit

**Version:** 2.7.0
**Date:** 2026-03-30

claude-kit is a configuration factory for Claude Code. It generates and maintains the `.claude/` folder of your projects: rules, hooks, permissions, agents, and commands. Everything is markdown + shell scripts — no application code.

---

## Table of contents

1. [Installation (step zero)](#1-installation-step-zero)
2. [New project (from scratch)](#2-new-project-from-scratch)
3. [Existing project (without claude-kit)](#3-existing-project-without-claude-kit)
4. [Project already using claude-kit (maintenance)](#4-project-already-using-claude-kit-maintenance)
5. [Command reference](#5-command-reference)
6. [Available stacks](#6-available-stacks)
7. [Audit system](#7-audit-system)
8. [Practices pipeline](#8-practices-pipeline)
9. [Bootstrap profiles](#9-bootstrap-profiles)
10. [Generated structure](#10-generated-structure)
11. [Config validation](#11-config-validation)
12. [FAQ](#12-faq)
13. [MCP server templates](#13-mcp-server-templates)
14. [Model routing](#14-model-routing)
15. [Domain knowledge commands](#15-domain-knowledge-commands)
16. [Context continuity](#16-context-continuity)

---

## 1. Installation (step zero)

Before using any `/forge` command, you need to install the global infrastructure in `~/.claude/`. This is done **once** per machine.

### Option A: Direct script

```bash
cd ~/Documents/GitHub/claude-kit   # or wherever you cloned claude-kit
./global/sync.sh
```

### Option B: From Claude Code

```
/forge global sync
```

### What does it install?

| Component | Location | Method |
|-----------|----------|--------|
| Skills (15) | `~/.claude/skills/` | Symlinks |
| Agents (7) | `~/.claude/agents/` | Symlinks |
| `/forge` command | `~/.claude/commands/forge.md` | Copy (Claude Code does not follow symlinks for commands) |
| Global CLAUDE.md | `~/.claude/CLAUDE.md` | Merge with `<!-- forge:custom -->` preservation |
| Global settings.json | `~/.claude/settings.json` | Merge of deny list + hooks |

**Cross-platform:** Linux, macOS, WSL, Git Bash. Uses copies as fallback if symlinks are not supported.

### Verify installation

```
/forge global status
```

Output:
```
=== GLOBAL STATUS ===
CLAUDE.md:     OK synced
settings.json: deny list 9 items (template: 9)
Skills:        15/15 installed
Agents:        7/7 installed
Commands:      forge.md (file)
```

---

## 2. New project (from scratch)

### Step by step

```bash
# 1. Create folder and initialize git
mkdir my-project
cd my-project
git init

# 2. Open Claude Code
claude

# 3. Inside Claude Code, run:
/forge bootstrap
```

### What happens during bootstrap?

1. **Detects stack** — scans project files (package.json, pyproject.toml, go.mod, etc.) to identify technologies. In an empty project, it asks which stacks you want.

2. **Asks for confirmation** — shows what it will create:
   ```
   Profile: standard
   Detected stack: react-vite-ts, supabase
   Will create:
   - CLAUDE.md (base template + stack rules)
   - .claude/settings.json (base permissions + stack)
   - .claude/rules/ (common rules + stack)
   - .claude/hooks/ (block-destructive + lint)
   - .claude/commands/ (audit, health, debug, review)
   - .claude/agents/ + orchestration
   - CLAUDE_ERRORS.md (empty, for error logging)

   Proceed? (yes/no)
   ```

3. **Generates files** — creates everything, merging permissions from each detected stack.

4. **Generates manifest** — `.claude/.forge-manifest.json` with SHA256 hashes of each file (baseline for future diffs and syncs).

### After bootstrap

1. **Customize CLAUDE.md** — edit the section below `<!-- forge:custom -->` with your project-specific description: architecture, endpoints, design decisions, etc. Everything above the marker is "managed" by forge (updated on syncs). Everything below is yours and is never touched.

2. **Verify** — run:
   ```
   /forge audit
   ```
   It gives you a score from 0-10 with specific gaps to fix.

---

## 3. Existing project (without claude-kit)

The process is **identical** to a new project. Bootstrap detects existing files to choose stacks automatically.

```bash
cd ~/Documents/GitHub/my-existing-project
claude
```

```
/forge bootstrap
```

### Differences from a new project

- **More precise stack detection** — it has real package.json, go.mod, etc. to analyze.
- **If a partial `.claude/` already exists** — bootstrap respects it and fills in what is missing.
- **If CLAUDE.md already exists** — it asks whether you want to preserve the existing content inside `<!-- forge:custom -->`.

### Post-bootstrap in an existing project

It is more important to customize CLAUDE.md with:
- Exact build/test commands for the project
- Architecture and directory structure
- Team-specific conventions
- Required environment variables

```
/forge audit
```

If the score is < 9, the report tells you exactly what is missing.

---

## 4. Project already using claude-kit (maintenance)

### Regular update cycle

```
/forge diff     # did anything change in claude-kit since my last sync?
/forge sync     # apply updates
/forge audit    # verify score post-sync
```

#### `/forge diff` — see what changed

Compares your local `.forge-manifest.json` against the current version of claude-kit. Shows:
- New files in the template that you do not have
- Files that changed in the template (rules, hooks, settings)
- Files that **you** modified locally (so they are not lost)
- Recommendation: sync yes/no

#### `/forge sync` — apply changes

Fundamental principle: **merge, not overwrite**. Never overwrites without confirmation.

1. Shows a complete dry-run (new, updated, unchanged, and ignored files)
2. You can approve all, none, or select individually
3. Always preserves:
   - `<!-- forge:custom -->` section of CLAUDE.md
   - `settings.local.json` (your personal configuration)
   - Files you modified locally (warns and asks)
4. Updates manifest and registry
5. Automatically runs audit at the end to show before/after score

#### `/forge audit` — verify state

Score 0-10 normalized against a 12-item checklist.

### Multi-project dashboard

```
/forge status
```

```
=== REGISTRY claude-kit ===
Project          Stack                    Score   Trend     Last audit
----------------------------------------------------------------------
my-api           python-fastapi, docker   9.5     ▁▃▇ ↑    2026-03-19
my-frontend      react-vite-ts            7.2     ▇▅▃ ↓    2026-03-18
```

Automatic alerts:
- Score that drops >1.5 points
- Projects with an old version of claude-kit

### Session analysis

```
/forge insights
```

Crosses CLAUDE_ERRORS.md + git log + agent-memory + registry to generate:
- Recurring error patterns
- Most edited files (hot files)
- Agent usage
- Score trend
- Actionable recommendations
- Top 3 findings go automatically to the practices pipeline

### Nuclear option: reset

```
/forge reset
```

Deletes `.claude/` and re-runs a full bootstrap. But:
- Mandatory backup in `.claude.backup-YYYY-MM-DD/`
- Preserves `settings.local.json` and `CLAUDE_ERRORS.md`
- Shows diff between backup and new
- Offers immediate rollback

---

## 5. Command reference

### Project commands

| Command | Description |
|---------|-------------|
| `/forge init` | Quick-start: auto-detect stack, 3 questions, personalized config |
| `/forge bootstrap` | Full interactive bootstrap with preview and confirmation |
| `/forge bootstrap --profile minimal` | Bootstrap with only the essentials |
| `/forge bootstrap --profile full` | Bootstrap with everything included |
| `/forge sync` | Update config while preserving customizations |
| `/forge audit` | Audit against checklist, score 0-10 |
| `/forge diff` | View pending changes since last sync |
| `/forge reset` | Restore from scratch (with backup) |
| `/forge insights` | Analyze past sessions |
| `/forge rule-check` | Detect inert rules (cross-reference globs vs git history) |
| `/forge benchmark` | Compare full config vs minimal on standardized tasks |
| `/forge plugin` | Generate Claude Code plugin package for marketplace |
| `/forge unregister` | Remove project from registry |
| `/forge export cursor` | Export config to Cursor |
| `/forge export codex` | Export config to Codex |
| `/forge export windsurf` | Export config to Windsurf |
| `/forge export openclaw` | Export config to OpenClaw |
| `/forge domain extract` | Extract domain rules from project code |
| `/forge domain sync-vault` | Sync domain rules to Obsidian vault |
| `/forge domain list` | List current domain rules with coverage |

### Global commands

| Command | Description |
|---------|-------------|
| `/forge global sync` | Install/update `~/.claude/` |
| `/forge global status` | State of `~/.claude/` vs template |
| `/forge status` | Multi-project dashboard with scores |
| `/forge version` | Show claude-kit version |

### Practices pipeline

| Command | Description |
|---------|-------------|
| `/forge capture "text"` | Record an insight in inbox (explicit) |
| `/forge capture` | Auto-detect mode: analyzes session context, proposes insight, asks Y/n/edit before saving |
| `/cap` | Shorthand alias for `/forge capture` (auto-detect mode) |
| `/forge update` | Process inbox -> evaluate -> incorporate |
| `/forge watch` | Check for updates in Anthropic docs |
| `/forge scout` | Review curated repos for patterns |
| `/forge inbox` | List pending practices |
| `/forge pipeline` | Practices lifecycle status |

---

## 6. Available stacks

15 stacks that are detected automatically and can be combined (multi-stack):

| Stack | Detection indicators |
|-------|---------------------|
| **python-fastapi** | `pyproject.toml`, `requirements.txt`, `Pipfile` |
| **react-vite-ts** | `package.json` with react/vite/next |
| **node-express** | `package.json` with express/fastify (without react/vite/next) |
| **swift-swiftui** | `Package.swift`, `*.xcodeproj`, `*.xcworkspace` |
| **java-spring** | `pom.xml`, `build.gradle`, `*.java` with Spring imports |
| **go-api** | `go.mod`, `go.sum`, `**/*.go` |
| **supabase** | `supabase/`, `supabase.ts`, `@supabase/supabase-js` in package.json |
| **docker-deploy** | `docker-compose*`, `Dockerfile*` |
| **gcp-cloud-run** | `app.yaml`, `cloudbuild.yaml`, `gcloud` in scripts |
| **aws-deploy** | `cdk.json`, `template.yaml` (SAM), `samconfig.toml` |
| **redis** | `redis` in requirements.txt/pyproject.toml |
| **data-analysis** | `*.ipynb`, `*.csv`, `*.xlsx` prominent |
| **devcontainer** | `.devcontainer/`, `devcontainer.json` |

Each stack provides:
- `rules/*.md` — contextual rules with `globs:` frontmatter
- `settings.json.partial` — stack-specific permissions and hooks
- (Optional) `hooks/*.sh` — stack-specific validation hooks

**Multi-stack:** if your project uses Python + Docker + Redis, all three stacks are detected and their permissions are merged (set union, no duplicates).

---

## 7. Audit system

### Checklist (12 items)

#### Required (0-2 points each, 70% weight)

| # | Item | 0 | 1 | 2 |
|---|------|---|---|---|
| 1 | **CLAUDE.md** | Does not exist | Exists but incomplete (<20 useful lines) | Complete: stack, architecture, build/test commands, conventions |
| 2 | **settings.json** | Does not exist | No deny list or excessive permissions | Explicit permissions + security deny list |
| 3 | **Contextual rules** | Do not exist | No `globs:` frontmatter | Rules with specific globs per area |
| 4 | **Hook block-destructive** | Does not exist | Exists but misconfigured | Exists + executable + wired in settings.json |
| 5 | **Build/test commands** | Not documented | In README but not in CLAUDE.md | Documented in CLAUDE.md with exact commands |

#### Recommended (0-1 point each, 30% weight)

| # | Item | Criteria |
|---|------|----------|
| 6 | CLAUDE_ERRORS.md | Exists with table format and valid types |
| 7 | Lint hook | Configured for the stack + executable |
| 8 | Custom commands | At least 1 relevant command |
| 9 | Project memory | Exists with useful context |
| 10 | Agents | Installed + active orchestration rule |
| 11 | .gitignore | Protects .env, *.key, *.pem, credentials |
| 12 | Prompt injection scan | No suspicious patterns in rules/CLAUDE.md |

### Scoring formula

```
score = required x 0.7 + recommended x (3.0 / 7)
```

- Perfect required items without recommended = **7.0** (Good)
- To reach 9+ you need at least 4 recommended items

### Security cap

If **settings.json** (item 2) or **hook block-destructive** (item 4) is missing, the maximum score is **6.0** — a project without basic security cannot be "Excellent".

### Levels

| Score | Level | Action |
|-------|-------|--------|
| 9-10 | Excellent | Only minor adjustments |
| 7-8.9 | Good | Some recommended items missing |
| 5-6.9 | Acceptable | Significant gaps, needs sync |
| 3-4.9 | Poor | Required items missing, partial bootstrap |
| 0-2.9 | Critical | Full bootstrap needed |

---

## 8. Practices pipeline

Practices are insights, patterns, and lessons learned that feed the evolution of claude-kit.

### Lifecycle

```
inbox/ -> evaluating/ -> active/ -> deprecated/
```

### Input sources

| Source | Command | Description |
|--------|---------|-------------|
| Manual | `/forge capture "text"` | Record an insight discovered during work |
| Automatic | Hook `detect-claude-changes.sh` | Detects changes in `.claude/` at the end of sessions |
| Web | `/forge watch` | News from official Anthropic docs |
| Repos | `/forge scout` | Patterns from curated repos in `practices/sources.yml` |
| Analysis | `/forge insights` | Top 3 findings from past sessions |
| Audit | `/forge audit` | Detected gaps automatically generate practices |

### Processing

```
/forge update
```

Runs 3 phases:
1. **Evaluate** — classifies inbox into accept/reject/postpone (criteria: actionable, new, generalizable)
2. **Incorporate** — applies accepted changes to claude-kit template/stacks/rules, bumps version
3. **Propagate** — lists projects that need sync (does NOT auto-propagate, only informs)

### Monitoring

```
/forge inbox      # list pending practices
/forge pipeline   # count by status
```

```
=== PRACTICES PIPELINE ===
Inbox:      3 pending practices
Evaluating: 1 under evaluation
Active:     12 incorporated
Deprecated: 2 retired
Last update: 2026-03-20
```

---

## 9. Bootstrap profiles

| Component | minimal | standard | full |
|-----------|---------|----------|------|
| CLAUDE.md + settings.json | Y | Y | Y |
| Hook block-destructive | Y | Y | Y |
| Rules (_common + stack) | Y | Y | Y |
| Hook lint-on-save | -- | Y | Y |
| Commands (audit, health, debug, review) | -- | Y | Y |
| Agents (7) + orchestration | -- | Y | Y |
| CLAUDE_ERRORS.md | -- | Y (empty) | Y (pre-populated) |
| Rule memory.md | -- | Y | Y |
| Hook warn-missing-test | -- | -- | Y |
| agent-memory/ (seed files) | -- | -- | Y |

**When to use each profile:**
- **minimal** — small projects, scripts, prototypes. The minimum needed for security and rules.
- **standard** (default) — most projects. Balance between coverage and complexity.
- **full** — large or critical projects where you want maximum coverage from day one.

---

## 10. Generated structure

After `/forge bootstrap` with the `standard` profile, your project looks like this:

```
my-project/
├── CLAUDE.md                          # Project context for Claude
├── CLAUDE_ERRORS.md                   # Evolutionary error log
├── .claude/
│   ├── settings.json                  # Permissions, deny list, hooks
│   ├── settings.local.json            # Your personal config (untouched during syncs)
│   ├── .forge-manifest.json           # SHA256 hashes (baseline for diff/sync)
│   ├── rules/
│   │   ├── _common.md                 # General rules (git, naming, testing, security)
│   │   ├── agents.md                  # Agent orchestration protocol
│   │   ├── memory.md                  # Memory policy
│   │   └── <stack>-*.md               # Stack-specific rules
│   ├── hooks/
│   │   ├── block-destructive.sh       # Blocks rm -rf, DROP, force push
│   │   └── lint-on-save.sh            # Automatic lint post-write/edit
│   ├── commands/
│   │   ├── audit.md                   # /audit — audit project
│   │   ├── health.md                  # /health — health check
│   │   ├── debug.md                   # /debug — assisted debugging
│   │   └── review.md                  # /review — code review
│   └── agents/
│       ├── researcher.md              # Read-only exploration
│       ├── architect.md               # Design and tradeoffs
│       ├── implementer.md             # Code + tests
│       ├── code-reviewer.md           # Review by severity
│       ├── security-auditor.md        # Vulnerabilities
│       └── test-runner.md             # Tests + coverage
└── ...                                # your code
```

### Key files

**CLAUDE.md** — the most important file. It is the context that Claude reads at the start of each session. Contains:
- Project name and stack
- Architecture and structure
- Exact build/test commands
- Team conventions
- Everything below `<!-- forge:custom -->` is yours

**settings.json** — granular permissions:
- `allow`: which tools Claude can use without asking (git, ls, read, etc.)
- `deny`: what is always forbidden (rm -rf, force push, reading .env)
- `hooks`: scripts that run before/after each action

**block-destructive.sh** — the most important hook. Intercepts Bash commands and blocks dangerous patterns. Three configurable profiles via `FORGE_HOOK_PROFILE`:
- `minimal`: only catastrophic operations (rm -rf /, force push main)
- `standard` (default): + DROP TABLE, git reset --hard, chmod 777
- `strict`: + curl|sh, eval, dd if=/dev/

---

## 11. Config validation

claude-kit doesn't just check if configuration exists — it measures if it's effective.

### Session metrics (automatic)

After bootstrap, every session automatically generates metrics in `~/.claude/metrics/{project}/`:

```json
{
  "sessions": 1,
  "errors_added": 0,
  "hook_blocks": 1,
  "lint_blocks": 3,
  "files_touched": 12,
  "rules_matched": 9,
  "rule_coverage": 0.75,
  "commits": 4
}
```

Hooks (`block-destructive.sh`, `lint-on-save.sh`) count blocks automatically. `session-report.sh` (Stop hook) reads, aggregates, and saves the data.

To also generate a human-readable `SESSION_REPORT.md`, set:
```bash
export FORGE_SESSION_REPORT=true
```

### Rule effectiveness

```
/forge rule-check
```

Cross-references rule globs against `git log` to classify each rule:

| Classification | Match rate | Action |
|---------------|-----------|--------|
| **Active** | > 50% | Keep — this rule fires regularly |
| **Occasional** | 10-50% | Evaluate — is it worth the context tokens? |
| **Inert** | < 10% | Candidate for removal |

Also reports **file coverage** — what percentage of files you touch fall under at least one rule, and which directories have no coverage.

### Benchmark

```
/forge benchmark
```

Runs the same standardized task in two isolated worktrees:
1. **Full config** — your complete `.claude/` setup
2. **Minimal config** — only `CLAUDE.md` + basic `settings.json`

Compares: files created, tests passing, lint issues, errors. Shows whether your configuration is actually making a difference.

Task definitions exist for python-fastapi, react-vite-ts, swift-swiftui, node-express, go-api, and a generic fallback.

**Cost:** runs Claude Code twice. Always opt-in with explicit confirmation.

### Config coherence

```bash
bash tests/test-config.sh
```

30 checks that validate internal consistency: hooks referenced in settings.json exist, rules have valid globs, deny list covers essentials, no contradictions.

---

## 12. FAQ

### Can I use claude-kit without the global CLAUDE.md?

Yes, but you lose the behavioral rules (communication, planning, critical partner). The global CLAUDE.md defines **how** Claude works. The project one defines **what** it works on.

### What happens if I modify a file managed by forge?

`/forge diff` detects it and `/forge sync` warns you before overwriting. You can accept or reject each file individually.

### How do I add a stack that does not exist?

Create a directory at `claude-kit/stacks/<name>/` with:
- `rules/*.md` — rules with `globs:` frontmatter
- `settings.json.partial` — permissions and hooks

See `docs/creating-stacks.md` for details.

### Can I export the config to Cursor/Codex?

```
/forge export cursor
/forge export codex
/forge export windsurf
/forge export openclaw
```

Hooks are converted to textual instructions (no enforcement outside Claude Code).

### How do I update claude-kit itself?

```bash
cd ~/Documents/GitHub/claude-kit
git pull
./global/sync.sh              # updates ~/.claude/
```

Then, in each project:
```
/forge diff    # see what changed
/forge sync    # apply
```

### What is the registry?

`registry/projects.yml` is a YAML file that tracks all bootstrapped projects: name, path, stacks, score, audit history. `/forge status` reads it to display the dashboard.

### Are agents mandatory?

No. With the `minimal` profile they are not installed. With `standard` and `full` they are, but Claude decides when to use them based on the orchestration rule in `.claude/rules/agents.md`.

---

## 13. MCP server templates

MCP servers extend Claude Code with tools for external services. claude-kit provides ready-to-use templates in `mcp/` covering configuration, permissions, and usage rules.

### Available templates

| Server | Package | Tools |
|--------|---------|-------|
| `github` | `@modelcontextprotocol/server-github` | Issues, PRs, code search, file contents |
| `postgres` | `@modelcontextprotocol/server-postgres` | Read-only SQL queries, schema inspection |
| `supabase` | `@supabase/mcp-server-supabase` | Projects, tables, migrations, branches, logs |
| `redis` | `mcp-server-redis` (community) | Key inspection, stream monitoring |
| `slack` | `@modelcontextprotocol/server-slack` | Messages, channels, search |

### Installation

**Step 1 — Register the server globally (once per machine):**
Copy the `mcpServers` entry from `mcp/<server>/config.json` into `~/.claude/settings.json`. Replace `${ENV_VAR}` with real values or set env vars in your shell profile.

**Step 2 — Install project rules:**
```bash
cp mcp/<server>/rules.md .claude/rules/mcp-<server>.md
```

Or let `/forge bootstrap` handle it automatically — it detects configured `mcpServers` in `~/.claude/settings.json` and offers to install matching rule templates.

### Security posture

Each template defines three tiers:
- **Auto-allowed**: read operations (list, get, search)
- **Prompt required**: write operations not in allow or deny lists
- **Always denied**: destructive operations (delete_project, merge_pull_request, flushdb)

See [mcp/README.md](../mcp/README.md) for full documentation.

---

## 14. Model routing

claude-kit includes explicit model selection criteria in `template/rules/model-routing.md`. Every bootstrapped project gets this rule, which guides both direct Claude work and subagent instantiation.

### Criteria

| Model | Use for |
|-------|---------|
| **haiku** | File search, grepping, running tests, repetitive transformations, short factual questions |
| **sonnet** | Feature implementation, bug fixing (known root cause), code review, standard debugging, docs |
| **opus** | Architecture decisions with real tradeoffs, security audits, ambiguous tasks, production-risk operations |

### Agent assignments

| Agent | Model | Reason |
|-------|-------|--------|
| researcher | haiku | Exploration — speed over depth |
| test-runner | haiku | Execute and report — no reasoning needed |
| implementer | sonnet | Standard implementation work |
| code-reviewer | sonnet | Focused review, single concern |
| session-reviewer | sonnet | Pattern analysis, not architecture |
| architect | opus | Tradeoffs with lasting consequences |
| security-auditor | opus | Missing a vulnerability has prod consequences |

### Escalation rule

Start with sonnet. Escalate to opus when: 2+ valid approaches with real consequences for choosing wrong, task touches security/data integrity/production systems, or after 2 attempts the approach is still unclear.

---

## Full visual flow

```
┌─────────────────────────────────────────────────┐
│                  INSTALLATION                    │
│  ./global/sync.sh  ->  ~/.claude/ configured     │
│  (once per machine)                              │
└──────────────────────┬──────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
┌──────────────────┐     ┌──────────────────────┐
│  NEW PROJECT     │     │  EXISTING PROJECT    │
│  or WITHOUT      │     │  WITH claude-kit     │
│  claude-kit      │     │                      │
├──────────────────┤     ├──────────────────────┤
│ /forge bootstrap │     │ /forge diff          │
│ /forge audit     │     │ /forge sync          │
│ edit CLAUDE.md   │     │ /forge audit         │
│   (forge:custom) │     │                      │
└────────┬─────────┘     └──────────┬───────────┘
         │                          │
         └──────────┬───────────────┘
                    ▼
         ┌──────────────────┐
         │  MAINTENANCE     │
         ├──────────────────┤
         │ /forge diff      │  <- any updates?
         │ /forge sync      │  <- apply
         │ /forge audit     │  <- verify
         │ /forge insights  │  <- optimize
         │ /forge status    │  <- dashboard
         └────────┬─────────┘
                  │
                  ▼
         ┌──────────────────┐
         │  LEARNING        │
         ├──────────────────┤
         │ /forge capture   │  <- record insight
         │ /forge watch     │  <- Anthropic docs
         │ /forge scout     │  <- curated repos
         │ /forge update    │  <- process inbox
         │ /forge pipeline  │  <- view status
         └──────────────────┘
```

---

## 15. Domain knowledge commands

Domain rules capture what a project does, not just how to code in it. They live in `.claude/rules/domain/` and are never overwritten by `/forge sync`.

### Commands

| Command | Description |
|---------|-------------|
| `/forge domain extract` | Analyzes code, CLAUDE.md, and git history to generate initial domain rules in `.claude/rules/domain/` |
| `/forge domain sync-vault` | Syncs domain rules to `decisions/` in your Obsidian vault (requires `$VAULT_PATH`) |
| `/forge domain list` | Lists existing domain rules with their globs and last_verified date |

### Domain rule frontmatter

```yaml
---
globs: "src/billing/**"
domain: billing
last_verified: 2026-03-30
domain_source: code-review   # code-review | git-history | manual | practice
---
```

### When to run `/forge domain extract`

- After bootstrap, before starting work — establishes the baseline
- After a major architectural change — captures the new reality
- When onboarding to an existing project — faster than reading all the code

Domain rules complement, not replace, CLAUDE.md. CLAUDE.md = prescriptive overview. Domain rules = accumulated specific knowledge that grows over time.

---

## 16. Context continuity

Claude Code compacts the context window when it fills up. The PostCompact + session-restore hook pair preserves task continuity across compaction events.

### How it works

```
1. Context fills → compaction triggered
2. post-compact.sh writes:
   - compact_summary (what was being done)
   - git state (current branch, last commits, dirty files)
   → .claude/session/last-compact.md

3. Next session starts (source="compact")
4. session-restore.sh reads last-compact.md
   → re-injects as context before the first user message
5. Claude resumes aware of the previous state
```

### Configuration

```bash
# Compact at 75% instead of 90% — more room for the summary
export CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=75
```

Add to `~/.zshrc` or `~/.bashrc` to persist.

### Proactive updates

Claude also updates `.claude/session/last-compact.md` after completing significant tasks — not only on compaction events. This is defined in `template/rules/_common.md`. The file is ephemeral (session-scoped) and is not committed to git.
