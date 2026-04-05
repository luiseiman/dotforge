# Stack Detection

Shared detection logic. Referenced by bootstrap, audit, sync, and reset skills.

## Detection Rules

Scan the current project directory for these indicators:

| Indicator | Stack |
|-----------|-------|
| `pyproject.toml`/`requirements.txt`/`Pipfile` with `fastapi` in deps | **python-fastapi** |
| `package.json` with react/vite/next | **react-vite-ts** |
| `Package.swift`, `*.xcodeproj`, `*.xcworkspace` | **swift-swiftui** |
| `supabase/`, `supabase.ts`, `@supabase/supabase-js` in package.json | **supabase** |
| `*.db`, `*.sqlite`, `*.ipynb`, `*.csv`, `*.xlsx` prominent | **data-analysis** |
| `docker-compose*`, `Dockerfile*` | **docker-deploy** |
| `app.yaml`, `cloudbuild.yaml`, `gcloud` in scripts | **gcp-cloud-run** |
| `redis` in requirements.txt/pyproject.toml | **redis** |

> Note: Projects with `redis` in deps should install the redis stack separately — python-fastapi no longer includes Redis rules.
| `package.json` with express/fastify (no react/vite/next) | **node-express** |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `*.java` with Spring imports | **java-spring** |
| `cdk.json`, `template.yaml` (SAM), `samconfig.toml`, `cloudformation/` | **aws-deploy** |
| `go.mod`, `go.sum`, `**/*.go` | **go-api** |
| `.devcontainer/`, `devcontainer.json` | **devcontainer** |
| `.claude/hookify.*.md` files present | **hookify** |
| User declares or `trading` keyword in project description | **trading** |
| `pytest.ini`, `pyproject.toml` with `[tool.pytest]`, `vitest.config.*`, `jest.config.*`, or `tests/`/`__tests__`/`spec/`/`test/` directories with ≥2 test files | **tdd** |

A project can match multiple stacks. If none detected, ask the user.

## Detection priority

When indicators conflict:
- `pyproject.toml` alone does NOT imply python-fastapi — verify `fastapi` is in dependencies
- `Dockerfile` + `app.yaml`/`cloudbuild.yaml` → **gcp-cloud-run** takes priority over docker-deploy
- `package.json` with both react and express → both **react-vite-ts** AND **node-express** (additive)
- `*.py` files do NOT auto-trigger data-analysis — requires notebooks, CSV, or SQL files
- `pyproject.toml` alone does NOT trigger tdd — verify `[tool.pytest]` section is present
- A single `test_*.py` file does NOT trigger tdd — require a dedicated test directory or config file
