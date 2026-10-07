# Checklist de Auditoría dotforge

El audit tiene **dos dimensiones independientes**:

- **A — Salud Nativa** (score 0-10): ¿el proyecto usa bien Claude Code nativo + seguridad? Es el score que importa para cualquier proyecto, use o no la maquinaria dotforge.
- **B — Adopción dotforge** (informativo 0-4): ¿cuánto adoptó la gobernanza dotforge? **NO penaliza** la Salud Nativa. Un proyecto native-first puro saca 0/4 acá sin perder un punto en A.

---

# Dimensión A — Salud Nativa (score 0-10)

## Obligatorio (cada item: 0-2 puntos, total máximo: 10)

### 1. Instrucciones de proyecto — CLAUDE.md o AGENTS.md (0-2)
- 0: No existe ni `CLAUDE.md` ni `AGENTS.md`
- 1: Existe pero <20 líneas útiles O falta alguna sección clave
- 2: Completo — incluye **todas** estas secciones: stack/tecnologías, arquitectura/estructura, comandos build/test exactos, convenciones

**Verificación:** Evaluar el archivo que Claude Code carga realmente (v2.1.277+): `CLAUDE.md` si existe; si `CLAUDE.md` contiene una línea `@AGENTS.md`, evaluar ambos concatenados; si no hay `CLAUDE.md`, evaluar `AGENTS.md` (Claude lo lee nativamente con el setting por defecto `claude-md-or-agents-md`). Un `CLAUDE.md` symlink a `AGENTS.md` cuenta como `CLAUDE.md`. No contar líneas vacías ni comentarios. Buscar presencia explícita de: nombre del stack, al menos 1 comando build/test, estructura de directorios o descripción de arquitectura. `/init` nativo genera la base; score 2 exige que esté completo. Advertir (sin penalizar) si existen `CLAUDE.md` y `AGENTS.md` sin import — Claude ignora `AGENTS.md` y las copias derivan.

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
- 1: Están en README pero no en el archivo de instrucciones, o están pero son incorrectos
- 2: Documentados en el archivo de instrucciones (`CLAUDE.md`, o `AGENTS.md` cuando es el que Claude carga — mismas reglas que el item 1) con comandos exactos que corresponden al stack detectado

## Recomendado (cada item: 0-1 punto, total máximo: 10)

### 6. .gitignore protege secrets
- 0: No hay .gitignore o no protege .env/secrets
- 1: .gitignore incluye .env, *.key, *.pem, credentials

### 7. Prompt injection scan
- 0: Rules or CLAUDE.md contain suspicious patterns (prompt injection risk)
- 1: No suspicious patterns detected

**Verification:** Scan `.claude/rules/`, `CLAUDE.md`, `AGENTS.md`, and any `*.md` in `.claude/` for patterns: `ignore previous`, `system:`, `<system>`, `</system>`, `<instructions>`, encoded payloads (base64 inline blocks), `IGNORE ALL`, `disregard`, `override instructions`. If any match → score 0 with explicit warning.

### 8. Auto mode safety (0-1)
- 0: Auto mode active (explicit `"auto"` OR `defaultMode` absent — auto is the session default since Claude Code v2.1.284) without deny list covering .env, *.key, *.pem, *credentials*
- 1: Auto mode active WITH complete deny list, OR `defaultMode` explicitly set to a non-auto mode

**Verification:** Read `permissions.defaultMode` in settings.json. Absent → treat as auto (v2.1.284+ default). `"auto"` or absent → verify deny list covers secrets (≥3 of the 4 patterns). Explicit non-auto value → pass. Missing settings.json → 0 (no deny list at all). Note: project/local `"auto"`/`"bypassPermissions"` are ignored by Claude Code (v2.1.257) — the effective mode comes from user/managed scope; the audit still scores the shared file as written because the deny list is what protects an auto-mode session.

### 9. OS-level sandboxing (0-1)
- 0: Project handles secrets (env vars, credentials, API keys, cloud configs) with no `sandbox.enabled` in settings.json
- 1: `sandbox.enabled: true` with at least `network.allowedDomains` OR `filesystem.denyRead` covering sensitive paths — OR project demonstrably handles no secrets (automatic pass)

**Verification:** Parse `settings.json` for `sandbox.enabled`. If true, verify at least one filesystem or network restriction. If false, scan for secret indicators (`.env*`, `credentials*`, `*.key`, `*.pem`, cloud CLIs). Projects without secrets auto-pass. Not applicable on Windows native (WSL2 only). See `.claude/rules/domain/sandboxing.md`.

### 10. Hook de lint automático
- 0: No hay lint post-write
- 1: Hook de lint configurado para el stack del proyecto Y es ejecutable (`chmod +x`)

### 11. Auto-memory bien usado (0-1)
- 0: No hay memoria de proyecto, O MEMORY.md es un dump (>200 líneas o >25KB — se trunca, contenido invisible)
- 1: Memoria nativa bien estructurada: `MEMORY.md` es un índice conciso de punteros (<200 líneas Y <25KB), con archivos de memoria enlazados. Si el proyecto rastrea errores, `CLAUDE_ERRORS.md` existe con formato de tabla (columna Type: syntax|logic|integration|config|security)

**Verificación:** Contar líneas y bytes de `MEMORY.md`. Penalizar el anti-patrón de volcar contenido en el índice (regla nativa: solo las primeras 200 líneas / 25KB se inyectan por sesión). Ver `.claude/rules/domain/context-window-optimization.md`.

### 12. Permission cascade (0-1)
- 0: Overrides locales mezclados en `settings.json` versionado (rutas absolutas de máquina, allows ad-hoc) que ensucian el commit
- 1: `settings.local.json` usado para overrides per-máquina/per-usuario, O el proyecto no necesita overrides locales (auto-pass)

**Verificación:** Si hay rutas de máquina o permisos ad-hoc en `.claude/settings.json` versionado que deberían estar en `settings.local.json` → 0. Cascade nativo: Managed > Local > Project > User. Ver `.claude/rules/domain/permission-model.md`.

### 13. Attribution configurado (0-1)
- 0: Usa el `includeCoAuthoredBy` deprecado, O trailers de commit/PR inconsistentes con la intención del proyecto
- 1: `attribution.commit` / `attribution.pr` configurado en settings.json, O el co-author por defecto es aceptable para el proyecto (auto-pass)

**Verificación:** Buscar `includeCoAuthoredBy` (deprecado → recomendar migrar a `attribution.*`). Auto-pass si el default alcanza. Para GitHub/GitLab/Bitbucket self-hosted, verificar `prUrlTemplate`. Ver `.claude/rules/_common.md` § Git.

### 14. Comandos custom (.claude/commands/)
- 0: No hay comandos custom
- 1: Al menos 1 comando custom relevante al proyecto

### 15. Agentes de orquestación
- 0: No hay .claude/agents/ ni regla agents.md
- 1: Agentes instalados + regla de orquestación activa en .claude/rules/

**Tier adjustments (dimensión A):**
- `simple` (<5K LOC, 1 stack, sin CI): items 14-15 con score 0 no penalizan (N/A)
- `complex` (>50K LOC, 3+ stacks, monorepo): items 14-15 semi-obligatorios (cada uno 0-2 en vez de 0-1)

---

# Dimensión B — Adopción dotforge (informativo, 0-4)

**No afecta el score de Salud Nativa.** Mide cuánto adoptó el proyecto la maquinaria de gobernanza dotforge. Reportar como `Adopción: N/4` con label (0=None, 1-2=Partial, 3=Most, 4=Full). Sirve para decidir propagación, no para juzgar calidad.

### B1. Behaviors v3 compilados y wired
- 0: Sin behaviors enforced — declaración en `behaviors/index.yaml` sola NO cuenta
- 1: Al menos un behavior compilado a `.claude/hooks/generated/*__pretooluse__*.sh` Y referenciado en `settings.json`

**Verificación:** `ls .claude/hooks/generated 2>/dev/null` y `grep generated .claude/settings.json`.

### B2. Workflow availability (v4)
- 0: No hay `workflows/` o está vacío
- 1: `workflows/` con al menos un `.js` que contiene `export const meta`

**Verificación:** `grep -q "export const meta" workflows/*.js`. Señal de gobernanza, no de calidad — los bash skills siguen siendo el workhorse. Ver `docs/v4/SPEC.md`.

### B3. Domain rules
- 0: No hay `.claude/rules/domain/`
- 1: Al menos un domain rule presente y fresco (`last_verified` <90 días)

**Verificación:** Contar archivos en `.claude/rules/domain/`. Reportar cuántos están stale (>90 días). Si hay lógica de negocio pero no domain rules, sugerir `/forge domain extract`.

### B4. Sync recency
- 0: `dotforge_version` del proyecto desfasado respecto a `VERSION` por ≥1 minor, o desconocido
- 1: Proyecto sincronizado a la versión actual de dotforge (`dotforge_version` == `VERSION`)

**Verificación:** Comparar `dotforge_version` del registry con `$DOTFORGE_DIR/VERSION`.
