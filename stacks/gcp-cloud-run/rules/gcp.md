---
globs: "Dockerfile*,cloudbuild*,app.yaml,.gcloudignore"
---

# GCP Cloud Run Rules

## Requirements
- Dockerfile required (Cloud Run is container-based)
- Configurable port via `PORT` env var (Cloud Run assigns it, default 8080)
- Health check endpoint GET `/health` or `/` responding 200

## Entrypoint
- CMD in Dockerfile: use exec form `["python", "main.py"]` not shell form
- Single process per container (no supervisord, no multiple workers)
- Startup time <10s to avoid cold start penalties

## Secrets and config
- Environment variables via Cloud Run config or Secret Manager. NEVER in the image.
- `.gcloudignore` up to date (similar to .dockerignore + .git + .env + __pycache__)
- Sensitive secrets → Secret Manager with `--set-secrets` on deploy

## Logging
- Logs to stdout/stderr (Cloud Logging captures them automatically)
- JSON structured logging preferred: `{"severity": "INFO", "message": "..."}`
- Do not write to log files (filesystem is ephemeral)

## Deploy
```bash
gcloud run deploy SERVICE_NAME \
  --source . \
  --region REGION \
  --allow-unauthenticated \  # only if public
  --set-env-vars KEY=VALUE \
  --min-instances 0 \
  --max-instances 10
```

## Scaling
- `--min-instances 0` to save cost (accepts cold starts)
- `--min-instances 1` for low latency (costs more)
- `--concurrency` default 80; reduce for CPU-intensive apps
- `--memory` default 512Mi; increase for heavy apps

## Common errors
- Not listening on `0.0.0.0` → container receives no traffic
- Not reading `PORT` from env → Cloud Run injects a port different from 8080
- Dockerfile without `.dockerignore` → 2GB image with node_modules/.git
- Request timeout exceeded (default 300s) → check if more time is needed or if it's a bug
