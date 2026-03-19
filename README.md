# claude-kit

Configuration factory for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Templates, stacks, skills, agents, audit system, and a practices pipeline — all markdown + shell scripts.

Bootstrap any project with a complete `.claude/` setup in seconds. Audit it. Keep it in sync as claude-kit evolves.

## Quick Start

```bash
# 1. Clone
git clone https://github.com/luiseiman/claude-kit.git
cd claude-kit

# 2. Install globally (symlinks skills, agents, commands into ~/.claude/)
export CLAUDE_KIT_DIR="$(pwd)"
./global/sync.sh

# 3. In any project directory:
/forge bootstrap    # Initialize .claude/ with full config
/forge audit        # Audit configuration and get a score (0-10)
/forge sync         # Update against current template
```

## What it does

`/forge bootstrap` detects your project's tech stack and generates:

- **CLAUDE.md** — project instructions with build/test commands
- **.claude/settings.json** — permissions (allow/deny), hooks
- **.claude/rules/** — contextual rules auto-loaded by glob patterns
- **.claude/hooks/** — block destructive commands, lint on save
- **.claude/commands/** — audit, debug, health, review
- **.claude/agents/** — 6 specialized subagents with orchestration
- **CLAUDE_ERRORS.md** — error log for cross-session learning

Multi-stack projects get all matching stack configs merged automatically.

## Architecture

```
claude-kit/
├── template/       # Base scaffold (CLAUDE.md.tmpl, settings, hooks, rules, commands)
├── stacks/         # Technology modules (8 stacks, additive)
├── agents/         # 6 subagents (researcher, architect, implementer, ...)
├── skills/         # 9 skills installed as ~/.claude/skills/ symlinks
├── audit/          # Checklist (11 items) + scoring normalized to 10
├── practices/      # Pipeline: inbox → evaluating → active → deprecated
├── global/         # Global ~/.claude/ management (CLAUDE.md, settings, sync.sh)
├── registry/       # Project tracking with scores and history
├── hooks/          # Global post-session change detection hook
├── docs/           # Guides, patterns, security checklist
└── tests/          # Hook test suite
```

## Stacks

Each stack provides contextual rules, permissions, and optional hooks. Stacks are auto-detected and additive.

| Stack | Detects | Rules |
|-------|---------|-------|
| **python-fastapi** | `pyproject.toml`, `requirements.txt` | backend.md, tests.md |
| **react-vite-ts** | `package.json` with react/vite | frontend.md |
| **swift-swiftui** | `Package.swift`, `*.xcodeproj` | ios.md |
| **supabase** | `supabase/`, `@supabase/supabase-js` | database.md |
| **docker-deploy** | `Dockerfile`, `docker-compose*` | infra.md |
| **data-analysis** | `*.ipynb`, `*.csv`, `*.xlsx` | data.md |
| **gcp-cloud-run** | `app.yaml`, `cloudbuild.yaml` | gcp.md |
| **redis** | `redis` in dependencies | redis.md |

Creating a new stack: see [docs/creating-stacks.md](docs/creating-stacks.md).

## Skills

All skills are invoked through the `/forge` command:

| Command | What it does |
|---------|-------------|
| `/forge bootstrap` | Initialize `.claude/` in a new project |
| `/forge sync` | Update config against current template (merge, not overwrite) |
| `/forge audit` | Audit configuration + calculate score (0-10) |
| `/forge diff` | Show what changed in claude-kit since last sync |
| `/forge reset` | Restore `.claude/` from template with backup |
| `/forge capture` | Register a practice in `practices/inbox/` |
| `/forge update` | Process practices: inbox → evaluate → incorporate |
| `/forge watch` | Search for upstream changes in Anthropic docs |
| `/forge scout` | Review curated repos for useful patterns |
| `/forge global sync` | Sync global `~/.claude/` config |
| `/forge global status` | Show global config status |

## Agents

Six specialized subagents, deployed to every bootstrapped project:

| Agent | Role | Memory |
|-------|------|--------|
| **researcher** | Read-only codebase exploration | transactional |
| **architect** | Design decisions, tradeoff analysis | persistent |
| **implementer** | Code + tests | persistent |
| **code-reviewer** | Review by severity (critical/warning/suggestion) | persistent |
| **security-auditor** | Vulnerability scanning | persistent |
| **test-runner** | Run tests + report coverage | transactional |

Orchestration follows a decision tree: researcher → architect → implementer → test-runner → code-reviewer. See [agents/](agents/) for definitions.

## Audit System

`/forge audit` scores your project's Claude Code configuration on a 10-point scale:

- **5 obligatory items** (scored 0-2): settings.json, block-destructive hook, CLAUDE.md, rules, deny list
- **6 recommended items** (scored 0-1): lint hook, commands, error log, agents, manifest, global hook
- **Security cap**: missing settings.json or block-destructive hook caps score at 6.0

Scores are tracked in `registry/projects.yml` with history for trending over time.

## Practices Pipeline

A continuous improvement system for discovering and incorporating Claude Code configuration patterns:

```
inbox/ → evaluating/ → active/ → deprecated/
```

Practices arrive from: `/forge capture` (manual), `/forge update` (web search), `/forge watch` (upstream docs), `/forge scout` (curated repos), audit gaps, or post-session hooks.

See [practices/README.md](practices/README.md) for the lifecycle and format.

## Documentation

- [Best Practices](docs/best-practices.md) — Claude Code configuration patterns
- [Security Checklist](docs/security-checklist.md) — 31 items for pre-deploy review
- [Prompting Patterns](docs/prompting-patterns.md) — 10 reproducible patterns
- [Creating Stacks](docs/creating-stacks.md) — How to add a new technology stack
- [Anatomy of CLAUDE.md](docs/anatomy-claude-md.md) — Deep dive into project instructions
- [Memory Strategy](docs/memory-strategy.md) — 5-layer memory policy for agents
- [Troubleshooting](docs/troubleshooting.md) — Common problems and diagnostics
- [Changelog](docs/changelog.md) — Version history (v0.1.0 → v1.2.2)
- [Roadmap](docs/roadmap.md) — Future plans

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- `bash` (hooks are shell scripts)
- `python3` with `pyyaml` (for registry validation, optional)

## Configuration

claude-kit uses a single environment variable:

```bash
export CLAUDE_KIT_DIR="/path/to/claude-kit"
```

This is set automatically by `global/sync.sh`. All skills and hooks resolve paths through this variable.

## License

[MIT](LICENSE)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
