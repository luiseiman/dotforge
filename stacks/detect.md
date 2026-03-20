# Stack Detection

Shared detection logic. Referenced by bootstrap, audit, sync, and reset skills.

## Detection Rules

Scan the current project directory for these indicators:

| Indicator | Stack |
|-----------|-------|
| `pyproject.toml`, `requirements.txt`, `Pipfile` | **python-fastapi** |
| `package.json` with react/vite/next | **react-vite-ts** |
| `Package.swift`, `*.xcodeproj`, `*.xcworkspace` | **swift-swiftui** |
| `supabase/`, `supabase.ts`, `@supabase/supabase-js` in package.json | **supabase** |
| `*.db`, `*.sqlite`, `*.ipynb`, `*.csv`, `*.xlsx` prominent | **data-analysis** |
| `docker-compose*`, `Dockerfile*` | **docker-deploy** |
| `app.yaml`, `cloudbuild.yaml`, `gcloud` in scripts | **gcp-cloud-run** |
| `redis` in requirements.txt/pyproject.toml | **redis** |
| `package.json` with express/fastify (no react/vite/next) | **node-express** |
| `pom.xml`, `build.gradle`, `build.gradle.kts`, `*.java` with Spring imports | **java-spring** |
| `cdk.json`, `template.yaml` (SAM), `samconfig.toml`, `cloudformation/` | **aws-deploy** |
| `go.mod`, `go.sum`, `**/*.go` | **go-api** |
| `.devcontainer/`, `devcontainer.json` | **devcontainer** |

A project can match multiple stacks. If none detected, ask the user.
