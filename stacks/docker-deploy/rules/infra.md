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

## Runtime diagnosis
- For runtime-faithful reproduction, exec into the container: `docker exec -i <container> python3 <<'EOF' ... EOF`. Uses the service's real env, keys, and installed deps — avoids local drift (missing modules, different `.env`, wrong key)
- Reference in-container secrets via `os.environ` from inside the exec; never thread secrets through your shell (they land in your history/logs)

## Config drift detection
- A long-lived container holds the env it was started with in memory. `.env` changes on disk do NOT affect a running container — nothing breaks until recreate
- When something works "until the first rebuild," suspect config drift between the running container's in-memory env and the current `.env` on disk BEFORE blaming the code diff
- After `docker compose up --build` on a previously long-running service: verify env inside the new container (decode/inspect keys) as part of the post-deploy smoke check
