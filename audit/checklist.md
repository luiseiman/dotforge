# Checklist de Auditoría dotforge

## Obligatorio (cada item: 0-2 puntos, total máximo: 10)

### 1. CLAUDE.md (0-2)
- 0: No existe
- 1: Existe pero <20 líneas útiles O falta alguna sección clave
- 2: Completo — incluye **todas** estas secciones: stack/tecnologías, arquitectura/estructura, comandos build/test exactos, convenciones

**Verificación:** No contar líneas vacías ni comentarios. Buscar presencia explícita de: nombre del stack, al menos 1 comando build/test, estructura de directorios o descripción de arquitectura.

### 2. .claude/settings.json (0-2)
- 0: No existe
- 1: Existe pero sin deny list o con permisos excesivos (Bash(*) o allow vacío)
- 2: Permisos explícitos por herramienta + deny list de seguridad (.env, *.key, *.pem, *credentials*)

### 3. Rules contextuales (0-2)
- 0: No existen (.claude/rules/ vacío o ausente)
- 1: Existen pero sin frontmatter globs (se aplican siempre a todo)
- 2: Rules con globs específicos por área del proyecto

### 4. Hook block-destructive (0-2)
- 0: No existe
- 1: Existe pero falla alguno: no es ejecutable (`chmod +x`), no está wired en settings.json hooks, o no cubre los 3 patrones básicos (rm -rf, DROP, force push)
- 2: Existe, es ejecutable (`-x`), está wired en settings.json PreToolUse, y cubre patrones básicos

**Verificación:** Correr `test -x .claude/hooks/block-destructive.sh` y verificar que settings.json tiene referencia en hooks.

### 5. Comandos build/test documentados (0-2)
- 0: No hay forma de saber cómo buildear/testear
- 1: Están en README pero no en CLAUDE.md, o están en CLAUDE.md pero son incorrectos
- 2: Documentados en CLAUDE.md con comandos exactos que corresponden al stack detectado

## Recomendado (cada item: 0-1 punto, total máximo: 10)

### 6. CLAUDE_ERRORS.md
- 0: No existe
- 1: Existe con formato para registrar errores (tabla con columna Type: syntax|logic|integration|config|security)

### 7. Hook de lint automático
- 0: No hay lint post-write
- 1: Hook de lint configurado para el stack del proyecto Y es ejecutable (`chmod +x`)

### 8. Comandos custom (.claude/commands/)
- 0: No hay comandos custom
- 1: Al menos 1 comando custom relevante al proyecto

### 9. Memory del proyecto
- 0: No hay archivos de memoria
- 1: Existe memoria con contexto útil del proyecto

### 10. Agentes de orquestación
- 0: No hay .claude/agents/ ni regla agents.md
- 1: Agentes instalados + regla de orquestación activa en .claude/rules/

### 11. .gitignore protege secrets
- 0: No hay .gitignore o no protege .env/secrets
- 1: .gitignore incluye .env, *.key, *.pem, credentials

### 12. Prompt injection scan
- 0: Rules or CLAUDE.md contain suspicious patterns (prompt injection risk)
- 1: No suspicious patterns detected

**Verification:** Scan `.claude/rules/`, `CLAUDE.md`, and any `*.md` in `.claude/` for patterns: `ignore previous`, `system:`, `<system>`, `</system>`, `<instructions>`, encoded payloads (base64 inline blocks), `IGNORE ALL`, `disregard`, `override instructions`. If any match → score 0 with explicit warning.

### 13. Auto mode safety (0-1)
- 0: Auto mode enabled without deny list covering .env, *.key, *.pem, *credentials*
- 1: Auto mode enabled WITH complete deny list OR auto mode not enabled

**Verification:** Check if `permissions.defaultMode` is set to `"auto"` in settings.json. If yes, verify deny list covers secrets. If auto mode is not enabled (default), automatic pass.

### 14. Behaviors coverage (v3) (0-1)
- 0: No v3 behaviors enabled in the project
- 1: At least one v3 behavior enabled via `behaviors/index.yaml`, compiled hooks under `.claude/hooks/generated/`, or behavior hook references in `settings.json`

**Verification:** Check `behaviors/index.yaml` for entries with `enabled: true`, or count generated behavior hooks matching `*__pretooluse__*.sh`. A project that has not opted into the v3 behavior governance layer scores 0 — this does not apply the security cap.

### 15. OS-level sandboxing (0-1)
- 0: Project handles secrets (env vars, credentials, API keys, cloud configs) with no `sandbox.enabled` in settings.json
- 1: `sandbox.enabled: true` with at least `network.allowedDomains` OR `filesystem.denyRead` covering the project's sensitive paths — OR project demonstrably handles no secrets (automatic pass)

**Verification:** Parse `settings.json` for `sandbox.enabled`. If true, verify at least one filesystem or network restriction is configured. If false, scan project for indicators of secret handling: presence of `.env*`, `credentials*`, `*.key`, `*.pem`, or references to cloud CLIs (`gcloud`, `aws`, `kubectl`) in scripts. Projects without secrets auto-pass. Not applicable on Windows native (WSL2 only). See `.claude/rules/domain/sandboxing.md`.
