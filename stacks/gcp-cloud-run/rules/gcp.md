---
globs: "Dockerfile*,cloudbuild*,app.yaml,.gcloudignore"
---

# GCP Cloud Run Rules

## Requisitos
- Dockerfile obligatorio (Cloud Run es container-based)
- Puerto configurable via env `PORT` (Cloud Run lo asigna, default 8080)
- Health check endpoint GET `/health` o `/` que responda 200

## Entrypoint
- CMD en Dockerfile: usar exec form `["python", "main.py"]` no shell form
- Single process por container (no supervisord, no multiple workers)
- Startup time <10s para evitar cold start penalties

## Secrets y config
- Variables de entorno via Cloud Run config o Secret Manager. NUNCA en imagen.
- `.gcloudignore` actualizado (similar a .dockerignore + .git + .env + __pycache__)
- Secrets sensibles → Secret Manager con `--set-secrets` en deploy

## Logging
- Logs a stdout/stderr (Cloud Logging los captura automáticamente)
- JSON structured logging preferido: `{"severity": "INFO", "message": "..."}`
- No escribir a archivos de log (filesystem es efímero)

## Deploy
```bash
gcloud run deploy SERVICE_NAME \
  --source . \
  --region REGION \
  --allow-unauthenticated \  # solo si es público
  --set-env-vars KEY=VALUE \
  --min-instances 0 \
  --max-instances 10
```

## Scaling
- `--min-instances 0` para ahorrar (acepta cold starts)
- `--min-instances 1` para latencia baja (cuesta más)
- `--concurrency` default 80; reducir si la app es CPU-intensive
- `--memory` default 512Mi; subir para apps pesadas

## Errores comunes
- No escuchar en `0.0.0.0` → container no recibe tráfico
- No leer `PORT` del env → Cloud Run inyecta un puerto distinto a 8080
- Dockerfile sin `.dockerignore` → imagen de 2GB con node_modules/.git
- Timeout de request excedido (default 300s) → revisar si necesita más o si es un bug
