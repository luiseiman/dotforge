# Architecture Components

Internal reference for claude-kit contributors. Maps all components and their interactions.

## Component Map

```
┌─────────────────────────────────────────────────────────────────┐
│                         claude-kit                               │
├──────────┬──────────┬──────────┬──────────┬──────────┬──────────┤
│ template │  stacks  │  skills  │  agents  │practices │  audit   │
│          │  (15)    │  (16)    │  (7)     │          │          │
├──────────┴──────────┴──────────┴──────────┴──────────┴──────────┤
│                        global/                                   │
│              (~/.claude/ management via sync.sh)                  │
├─────────────────────────────────────────────────────────────────┤
│                    integrations/                                  │
│              (cross-tool bridges: OpenClaw)                       │
├─────────────────────────────────────────────────────────────────┤
│                      registry/                                   │
│              (cross-project tracking)                             │
└─────────────────────────────────────────────────────────────────┘
```

## Template (base scaffold)

Files in `template/` are the starting point for every project.

| Component | Path | Purpose |
|-----------|------|---------|
| CLAUDE.md | `template/CLAUDE.md.tmpl` | Project instructions with `<!-- forge:section -->` markers |
| settings.json | `template/settings.json.tmpl` | Permissions, deny list, hook wiring |
| Rules (3) | `template/rules/` | `_common.md` (code rules), `agents.md` (orchestration), `memory.md` (memory policy) |
| Hooks (6) | `template/hooks/` | `block-destructive.sh`, `lint-on-save.sh`, `session-report.sh`, `warn-missing-test.sh`, `check-updates.sh`, `detect-stack-drift.sh` |

**Data flow:** `/forge bootstrap` copies template → project `.claude/`, replaces `<!-- forge:section -->` markers, layers stacks on top.

## Stacks (15 technology modules)

Each stack is additive — layered on top of template during bootstrap.

| Stack | Contents | Detection |
|-------|----------|-----------|
| python-fastapi | rules/backend.md, rules/tests.md, settings.json.partial | `requirements.txt` or `pyproject.toml` with fastapi |
| react-vite-ts | rules/frontend.md, settings.json.partial | `package.json` with react + vite |
| swift-swiftui | rules/ios.md, settings.json.partial | `Package.swift` or `*.xcodeproj` |
| supabase | rules/supabase.md, settings.json.partial | `supabase/` dir or `.env` with SUPABASE |
| docker-deploy | rules/docker.md, settings.json.partial | `Dockerfile` or `docker-compose.yml` |
| data-analysis | rules/data.md, settings.json.partial | `*.ipynb` or pandas/numpy in deps |
| gcp-cloud-run | rules/gcp.md, settings.json.partial | `app.yaml` or `cloudbuild.yaml` |
| redis | rules/redis.md, settings.json.partial | redis in deps |
| node-express | rules/node.md, settings.json.partial | `package.json` with express/fastify |
| java-spring | rules/java.md, settings.json.partial | `pom.xml` or `build.gradle` with spring |
| aws-deploy | rules/aws.md, settings.json.partial | `cdk.json`, `template.yaml`, or `samconfig.toml` |
| go-api | rules/go.md, settings.json.partial | `go.mod` |
| devcontainer | rules/devcontainer.md, settings.json.partial | `.devcontainer/` dir |
| hookify | rules/hooks.md, settings.json.partial | Custom hook framework |
| trading | rules/trading.md, settings.json.partial | Custom trading stack |

Detection logic centralized in `stacks/detect.md`.

**Composition:** Multiple stacks can be applied to one project. `settings.json.partial` files are merged by union (allow lists, deny lists).

## Skills (16 /forge subcommands)

Each skill is a `SKILL.md` file with name/description frontmatter, installed as symlink in `~/.claude/skills/`.

| Skill | Command | Category |
|-------|---------|----------|
| audit-project | `/forge audit` | Assessment |
| bootstrap-project | `/forge bootstrap` | Setup |
| sync-template | `/forge sync` | Maintenance |
| diff-project | `/forge diff` | Maintenance |
| reset-project | `/forge reset` | Maintenance |
| export-config | `/forge export` | Distribution |
| capture-practice | `/forge capture` | Practices |
| update-practices | `/forge update` | Practices |
| watch-upstream | `/forge watch` | Practices |
| scout-repos | `/forge scout` | Practices |
| session-insights | `/forge insights` | Analytics |
| rule-effectiveness | `/forge rule-check` | Analytics |
| benchmark | `/forge benchmark` | Analytics |
| init-project | `/forge init` | Setup |
| plugin-generator | `/forge plugin` | Distribution |
| mcp-add | `/forge mcp add` | Setup |

**Dispatch:** `global/commands/forge.md` receives arguments and delegates to the matching skill.

## Agents (7 specialized subagents)

Defined in `agents/*.md`, installed as symlinks in `~/.claude/agents/`.

| Agent | Role | Memory |
|-------|------|--------|
| researcher | Read-only codebase exploration | Transactional (no persistence) |
| architect | Design decisions, tradeoff analysis | `.claude/agent-memory/architect/` |
| implementer | Code + tests | `.claude/agent-memory/implementer/` |
| code-reviewer | Review by severity | `.claude/agent-memory/code-reviewer/` |
| security-auditor | Vulnerability scanning | `.claude/agent-memory/security-auditor/` |
| test-runner | Tests + coverage | Transactional (no persistence) |
| session-reviewer | Post-session analysis, pattern detection | Transactional (no persistence) |

**Orchestration chain:** researcher → architect → implementer → test-runner → code-reviewer (defined in `template/rules/agents.md`).

## Practices Pipeline

```
Sources                    Lifecycle                    Output
─────────                  ─────────                    ──────
/forge capture ──┐
/forge update  ──┤         inbox/ ──→ evaluating/ ──→ active/ ──→ deprecated/
/forge watch   ──┤           │            │              │
/forge scout   ──┤        evaluate     test in 1     incorporate
post-session   ──┘        criteria     project       in template/
hook                                                  stacks/
                                                        │
                                           metrics.yml ◄─┘
                                           (effectiveness tracking)
```

## Audit System

```
audit/checklist.md          audit/scoring.md
(12 items)                  (formula + cap)
      │                           │
      ▼                           ▼
/forge audit ──→ score 0-10 ──→ registry/projects.yml
                                    │
                                    ▼
                              history[] (append-only)
                              metrics_summary (from session data)
```

**Items:** 5 obligatory (0-2 pts each, weight 70%) + 7 recommended (0-1 pts each, weight 30%).
**Security cap:** Score maxes at 6.0 if settings.json or block-destructive hook is missing.

## Global Layer (~/.claude/)

`global/sync.sh` manages symlinks from claude-kit into the user's global config:

```
~/.claude/
├── CLAUDE.md          ← from global/CLAUDE.md.tmpl
├── settings.json      ← from global/settings.json.tmpl
├── skills/            ← symlinks to skills/*/
├── agents/            ← symlinks to agents/*.md
└── commands/
    └── forge.md       ← symlink to global/commands/forge.md
```

## Registry

`registry/projects.yml` tracks all managed projects:
- Audit scores with history (append-only)
- Stack assignments
- Sync timestamps and claude-kit version
- Session metrics summary (from `~/.claude/metrics/`)

## Config Validation (v1.6.0)

See `docs/config-validation.md` for full documentation. Four layers:

| Layer | Tool | What it measures |
|-------|------|------------------|
| Structural | `tests/test-config.sh` | Config coherence (hooks exist, globs valid, deny complete) |
| Behavioral | `session-report.sh` | Session metrics (blocks, coverage, errors) |
| Coverage | `/forge rule-check` | Rule match rate against git history |
| Comparative | `/forge benchmark` | Full config vs minimal config on standard tasks |

## Integrations

`integrations/` contains cross-tool bridges that let other platforms use claude-kit.

### OpenClaw (`integrations/openclaw/`)

Two mechanisms:

1. **Bridge skill** (`integrations/openclaw/SKILL.md`) — standalone OpenClaw skill that proxies all `/forge` commands via `claude --print`. Install with `bash integrations/openclaw/install.sh` → symlinks into `~/.openclaw/skills/forge/`.

2. **Export** (`/forge export openclaw`) — generates a project-specific OpenClaw workspace skill at `~/.openclaw/skills/{project}/SKILL.md` with project context, rules, deny list, and claude CLI bridge. Part of the standard export-config skill.

| Mechanism | Scope | Content |
|-----------|-------|---------|
| Bridge skill | All projects | Proxies `/forge` commands, resolves project from registry |
| Export | Single project | Project-specific context, rules as instructions, CLI bridge |

### Adding new integrations

Each integration lives in `integrations/<tool>/` with:
- `SKILL.md` or equivalent config in the target tool's format
- `install.sh` for automated setup
- Documentation of what's preserved vs lost in the conversion
