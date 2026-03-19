---
globs: "docker-compose*,Dockerfile*,*.dockerfile"
---

# Docker / Deploy Rules

## Docker Compose
- `docker compose up --build` después de cambios (git pull NO actualiza containers)
- `--no-cache` si cambios no aparecen después de build
- Health checks obligatorios en servicios críticos
- Named volumes para datos persistentes. Bind mounts solo para desarrollo.

## Dockerfile
- Multi-stage builds para producción (builder → runtime)
- `.dockerignore` actualizado (node_modules, .git, .env, __pycache__)
- Pin versions: `python:3.12-slim` no `python:latest`
- COPY requirements/package.json primero → install → COPY rest (cache de layers)

## Producción
- Variables de entorno via `.env` o secrets manager. NUNCA en Dockerfile/compose.
- Logs a stdout/stderr (no a archivos)
- Restart policy: `unless-stopped` para servicios, `no` para one-shot
- Resource limits (mem_limit, cpus) en compose para evitar OOM

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
1. Tests pasan localmente
2. Build sin errores
3. Push a remote
4. Pull en servidor
5. Build + restart servicios
6. Verificar containers running
7. Health check endpoints
8. Verificar logs (primeros 30s)
