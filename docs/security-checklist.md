> **[English](#security-checklist--pre-deploy)** | **[Español](#checklist-de-seguridad--pre-deploy)**

# Security Checklist — Pre-deploy

Verify BEFORE deploying any project.

## Inputs and validation
- [ ] User inputs sanitized (HTML, SQL, shell)
- [ ] Type and range validation on API endpoints
- [ ] File uploads: verify MIME type, max size, safe filename
- [ ] URLs: validate scheme (no javascript:, data:)

## Secrets and credentials
- [ ] No hardcoded credentials in code
- [ ] .env in .gitignore
- [ ] API keys in environment variables or secrets manager
- [ ] Tokens with minimum necessary permissions (least privilege)
- [ ] Secrets rotated if ever exposed

## Database
- [ ] Parameterized queries (never string interpolation)
- [ ] RLS enabled on tables with user data (Supabase)
- [ ] Backups configured
- [ ] Connections with TLS

## Authentication and authorization
- [ ] Auth on all endpoints that require it
- [ ] Tokens with expiration
- [ ] Rate limiting on login and public endpoints
- [ ] CORS configured (no wildcard * in production)

## API and network
- [ ] HTTPS in production
- [ ] Security headers (HSTS, X-Content-Type-Options, etc.)
- [ ] Errors don't expose stack traces or internal info to user
- [ ] Timeouts configured on external requests

## Logs and monitoring
- [ ] Logs don't contain passwords, tokens, or PII
- [ ] Critical errors alert (not just log)
- [ ] Health checks on critical services

## Dependencies
- [ ] No known vulnerabilities (`npm audit`, `pip audit`)
- [ ] Pinned versions (no latest/*)
- [ ] Lock files (package-lock.json, poetry.lock) committed

## Docker (if applicable)
- [ ] Don't run as root inside the container
- [ ] .dockerignore includes .env, .git, node_modules
- [ ] Base images with specific version (not :latest)
- [ ] Secrets NOT in build args or layers

## Claude Code permissions

### Permission Modes
Claude Code supports 6 permission modes that control when operations require confirmation:
- **default**: prompt on every potentially destructive operation
- **acceptEdits**: auto-accept file edits, prompt on destructive operations
- **plan**: read-only enforcement, no write/bash/agent operations
- **auto** (YOLO): minimal prompts, broad allow rules — **see stripping rules below**
- **dontAsk**: rarely used; disable prompts entirely (dangerous)
- **bypassPermissions**: skip all permission checks (local dev only)

### Auto-Mode (YOLO) Safety
- [ ] Verify auto-mode stripping rules: broad interpreter patterns (python, python3, node, etc.), package runners (npx, npm run, yarn run, etc.), and shell patterns (bash, sh, zsh, eval, etc.) are SILENTLY REMOVED when auto mode activates
- [ ] Replace interpreter allow patterns with specific tool commands: use `pytest` instead of `python`, `uvicorn` instead of `python`, `vitest`/`jest` instead of `node`
- [ ] Document which permissions are stripped in auto-mode for team awareness
- [ ] Test critical workflows with auto-mode enabled to verify they still work

---

# Checklist de Seguridad — Pre-deploy

Verificar ANTES de deployar cualquier proyecto.

## Inputs y validación
- [ ] Inputs del usuario sanitizados (HTML, SQL, shell)
- [ ] Validación de tipos y rangos en API endpoints
- [ ] File uploads: verificar tipo MIME, tamaño máximo, nombre seguro
- [ ] URLs: validar scheme (no javascript:, data:)

## Secrets y credenciales
- [ ] Sin credenciales hardcodeadas en código
- [ ] .env en .gitignore
- [ ] API keys en variables de entorno o secrets manager
- [ ] Tokens con permisos mínimos necesarios (least privilege)
- [ ] Secrets rotados si fueron expuestos alguna vez

## Base de datos
- [ ] Queries parametrizadas (nunca string interpolation)
- [ ] RLS habilitado en tablas con datos de usuario (Supabase)
- [ ] Backups configurados
- [ ] Conexiones con TLS

## Autenticación y autorización
- [ ] Auth en todos los endpoints que lo requieran
- [ ] Tokens con expiración
- [ ] Rate limiting en login y endpoints públicos
- [ ] CORS configurado (no wildcard * en producción)

## API y red
- [ ] HTTPS en producción
- [ ] Headers de seguridad (HSTS, X-Content-Type-Options, etc.)
- [ ] Errores no exponen stack traces ni info interna al usuario
- [ ] Timeouts configurados en requests externos

## Logs y monitoreo
- [ ] Logs no contienen passwords, tokens, ni PII
- [ ] Errores críticos alertan (no solo loguean)
- [ ] Health checks en servicios críticos

## Dependencies
- [ ] Sin vulnerabilidades conocidas (`npm audit`, `pip audit`)
- [ ] Versiones pinneadas (no latest/*)
- [ ] Lock files (package-lock.json, poetry.lock) commiteados

## Docker (si aplica)
- [ ] No correr como root dentro del container
- [ ] .dockerignore incluye .env, .git, node_modules
- [ ] Imágenes base con versión específica (no :latest)
- [ ] Secrets NO en build args ni en layers

## Permisos de Claude Code

### Modos de Permisos
Claude Code soporta 6 modos de permisos que controlan cuándo se requiere confirmación:
- **default**: confirmar en toda operación potencialmente destructiva
- **acceptEdits**: auto-aceptar edits de archivo, confirmar operaciones destructivas
- **plan**: read-only, sin operaciones write/bash/agent
- **auto** (YOLO): prompts mínimos, reglas de allow amplias — **ver reglas de stripping abajo**
- **dontAsk**: raramente usado; deshabilitar prompts completamente (peligroso)
- **bypassPermissions**: saltear todos los checks de permiso (local dev únicamente)

### Modo Auto (YOLO) — Seguridad
- [ ] Verificar reglas de stripping en modo auto: patrones amplios de intérpretes (python, python3, node, etc.), ejecutores de paquetes (npx, npm run, yarn run, etc.) y shells (bash, sh, zsh, eval, etc.) se ELIMINAN SILENCIOSAMENTE al activar modo auto
- [ ] Reemplazar patrones de allow con intérpretes por comandos específicos de herramientas: usar `pytest` en vez de `python`, `uvicorn` en vez de `python`, `vitest`/`jest` en vez de `node`
- [ ] Documentar qué permisos se eliminan en modo auto para conciencia del equipo
- [ ] Probar workflows críticos con modo auto activado para verificar que siguen funcionando
