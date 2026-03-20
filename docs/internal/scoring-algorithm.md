# Scoring Algorithm

Internal reference for the audit scoring formula.

## Formula

```
score = obligatorio_sum * 0.7 + recomendado_sum * (3.0 / 7)
```

- **Max score:** 10.0
- **Obligatory items (5):** 0-2 points each → max 10 → weighted 70% → max 7.0
- **Recommended items (7):** 0-1 point each → max 7 → weighted 30% → max 3.0

## Security Cap

If either of these scores 0, the entire project score is **capped at 6.0**:
- Item 2: `settings.json` (deny list, permissions)
- Item 4: `block-destructive.sh` hook (destructive command protection)

**Rationale:** A project without basic security controls cannot score higher than "Acceptable" regardless of other configuration quality.

## Items

### Obligatory (0-2 points each)

| # | Item | 0 | 1 | 2 |
|---|------|---|---|---|
| 1 | CLAUDE.md | Missing | Exists but missing key sections | Has Stack, Build, Architecture sections |
| 2 | settings.json | Missing | Exists, incomplete deny list | Complete deny (.env, *.key, *.pem) + permissions |
| 3 | Contextual rules (.claude/rules/) | None | Exist but missing globs frontmatter | Rules with valid globs matching real files |
| 4 | block-destructive.sh | Missing | Exists but not executable or not wired | Executable + wired in settings.json |
| 5 | Build/test documentation | None | Partial (only build or only test) | Both build and test commands documented |

### Recommended (0-1 point each)

| # | Item | 0 | 1 |
|---|------|---|---|
| 6 | CLAUDE_ERRORS.md | Missing | Exists with correct table format |
| 7 | Lint hook (lint-on-save.sh) | Missing | Executable + wired |
| 8 | Custom commands (.claude/commands/) | None | At least 1 command |
| 9 | Memory configuration | No agent-memory/ or autoMemory | agent-memory/ dirs exist or autoMemory enabled |
| 10 | Agent orchestration (.claude/rules/agents.md) | Missing | Present with delegation rules |
| 11 | .gitignore covers .claude artifacts | No | Covers .claude/agent-memory/, SESSION_REPORT.md, etc. |
| 12 | Prompt injection scan | Not checked | Rules and CLAUDE.md clean of suspicious patterns |

## Examples

### Perfect score (10.0)
```
obligatorio: 2+2+2+2+2 = 10
recomendado: 1+1+1+1+1+1+1 = 7
score = 10 * 0.7 + 7 * (3.0/7) = 7.0 + 3.0 = 10.0
```

### Good project, no extras (7.0)
```
obligatorio: 2+2+2+2+2 = 10
recomendado: 0+0+0+0+0+0+0 = 0
score = 10 * 0.7 + 0 * (3.0/7) = 7.0 + 0.0 = 7.0
```

### Security cap triggered (max 6.0)
```
obligatorio: 2+0+2+2+2 = 8  (settings.json missing → cap applies)
recomendado: 1+1+1+1+1+1+1 = 7
raw_score = 8 * 0.7 + 7 * (3.0/7) = 5.6 + 3.0 = 8.6
final_score = min(8.6, 6.0) = 6.0
```

### Minimal viable (5.6)
```
obligatorio: 1+1+1+1+1 = 5  (everything partial)
recomendado: 1+1+0+0+0+0+0 = 2
score = 5 * 0.7 + 2 * (3.0/7) = 3.5 + 0.86 = 4.36
```

## Tier Adjustment

Projects are classified by tier (detected automatically or set manually):

| Tier | Expected score | Context |
|------|---------------|---------|
| simple | ≥ 5.0 | Scripts, single-file tools, experiments |
| standard | ≥ 7.0 | Typical projects with tests and CI |
| complex | ≥ 9.0 | Multi-stack, team projects, production systems |

Tier affects audit reporting (recommendations adjusted) but does NOT modify the score formula.
