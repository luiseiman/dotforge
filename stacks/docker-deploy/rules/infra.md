---
globs: "docker-compose*,Dockerfile*,*.dockerfile"
---

# Docker / Deploy Rules

## Docker Compose
- `docker compose up --build` after changes (git pull does NOT update containers)
- `--no-cache` if changes don't appear after build
- Health checks required on critical services
- Named volumes for persistent data. Bind mounts for development only.

## Dockerfile
- Multi-stage builds for production (builder → runtime)
- `.dockerignore` up to date (node_modules, .git, .env, __pycache__)
- Pin versions: `python:3.12-slim` not `python:latest`
- COPY requirements/package.json first → install → COPY rest (layer caching)

## Production
- Environment variables via `.env` or secrets manager. NEVER in Dockerfile/compose.
- Logs to stdout/stderr (not to files)
- Restart policy: `unless-stopped` for services, `no` for one-shot
- Resource limits (mem_limit, cpus) in compose to prevent OOM

## Health checks
```yaml
healthcheck:
  test: ["CMD", "curl", "-sf", "http://localhost:PORT/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 40s
```

## Deploy checklist
1. Tests pass locally
2. Build without errors
3. Push to remote
4. Pull on server
5. Build + restart services
6. Verify containers running
7. Health check endpoints
8. Verify logs (first 30s)
