# Análisis de Impacto — Roadmap claude-kit

> Mapeo detallado de qué archivos y componentes se ven afectados por cada item del roadmap.
> Complemento de [roadmap-explained.md](roadmap-explained.md) (beneficios) y [roadmap.md](roadmap.md) (técnico).

---

## v1.2.3 — Hardening & Quick Wins

### 1. Prompt injection detection en audit

**Archivos impactados:**
- `audit/checklist.md` — Agregar item 12 (recomendado, 0-1). Hoy tiene 11 items.
- `audit/scoring.md` — Recalcular fórmula. Hoy: obligatorios×0.7 + recomendados×0.5 = max 10.0. Con un recomendado más (7 en vez de 6), los pesos cambian y hay que ajustar coeficientes.
- `skills/audit-project/SKILL.md` — Agregar paso de scan de contenido. Hoy el audit solo verifica *presencia* de archivos; ahora necesita leer el *contenido* de `rules/*.md` y `CLAUDE.md` buscando patrones regex (`ignore previous`, `<system>`, base64, etc).
- `registry/projects.yml` — Los scores históricos fueron calculados con 11 items. Si re-auditás, el score puede cambiar.

**Riesgo:** Scores históricos dejan de ser comparables.
**Impacto: BAJO.** Es aditivo. No rompe nada existente.

---

### 2. Hook profiles (minimal / standard / strict)

**Archivos impactados:**
- `template/hooks/block-destructive.sh` — Reescritura significativa. Hoy es lista fija de 12 patrones con `grep -qiE`. Agregar lectura de `$FORGE_HOOK_PROFILE` y condicionar patrones por perfil.
- `template/settings.json.tmpl` — Agregar `FORGE_HOOK_PROFILE` como variable de entorno.
- `skills/bootstrap-project/SKILL.md` — Agregar paso que pregunta qué profile usar y lo guarda en `settings.local.json`.
- `.claude/hooks/block-destructive.sh` (propio de claude-kit) — Mantener sincronizado con template.
- `skills/sync-template/SKILL.md` — Respetar la variable de profile del proyecto destino, no sobreescribirla.
- `tests/test-hooks.sh` — Expandir para cubrir los 3 profiles.

**Impacto: MEDIO.** El hook `block-destructive.sh` es el componente de seguridad más crítico (si falla, el audit capea el score a 6.0). Tocarlo requiere testing riguroso.

---

### 3. Error classification en CLAUDE_ERRORS.md

**Archivos impactados:**
- `CLAUDE_ERRORS.md` (propio) — Agregar columna `Type` a las 6 entradas existentes. Reclasificar retroactivamente.
- `template/rules/memory.md` — Actualizar formato documentado. Hoy: "columns Date | Area | Error | Cause | Fix | Rule"; pasa a incluir `| Type`.
- `.claude/rules/memory.md` (propio) — Ídem.
- `audit/checklist.md` item 6 — Agregar validación de que columna Type existe.
- `skills/audit-project/SKILL.md` — Actualizar verificación del item 6.

**Riesgo:** Proyectos ya bootstrapeados con formato viejo necesitan migración.
**Impacto: BAJO.** Es agregar una columna a una tabla markdown.

---

### 4. Git worktree en Agent Teams

**Archivos impactados:**
- `template/rules/agents.md` — Agregar instrucción `isolation: "worktree"` en sección Agent Teams.
- `.claude/rules/agents.md` (propio) — Ídem.
- `agents/implementer.md` — Agregar mención de worktree cuando opera como teammate.

**Impacto: BAJO.** Cambios puramente textuales en rules. `isolation: "worktree"` ya es feature nativo de Claude Code Agent tool.

---

### 5. TDD warning hook

**Archivos impactados:**
- **Nuevo:** `template/hooks/warn-missing-test.sh` — Hook (PostToolUse, Write matcher).
- `template/settings.json.tmpl` — Agregar hook condicionado a profile `strict`.
- `skills/bootstrap-project/SKILL.md` — Copiar hook solo si profile es `strict`.
- `stacks/*/settings.json.partial` — Posiblemente ajustar paths de test según stack (Python: `tests/`, React: `__tests__/`).

**Dependencia:** Requiere hook profiles (item 2) implementado primero.
**Impacto: BAJO.** Hook nuevo, exit 0 (warning, nunca bloquea).

---

## v1.3.0 — Stack Expansion & Cross-Tool

### 6. Cuatro stacks nuevos

**Archivos impactados:**
- **4 directorios nuevos:** `stacks/node-express/`, `stacks/java-spring/`, `stacks/aws-deploy/`, `stacks/go-api/`. Cada uno con `rules/*.md`, `settings.json.partial`, opcionalmente `hooks/*.sh`.
- `stacks/detect.md` — Agregar 4 reglas de detección (package.json+express → node-express; pom.xml/build.gradle → java-spring; cdk.json/samconfig → aws-deploy; go.mod → go-api).
- `skills/audit-project/SKILL.md` — Actualizar referencia a cantidad de stacks (8 → 12).

**Riesgo:** Conflicto de detección si proyecto tiene package.json con Express *y* React. Hay que permitir ambos stacks (son aditivos).
**Impacto: BAJO.** Los stacks son modulares por diseño.

---

### 7. Cross-tool export (`/forge export`)

**Archivos impactados:**
- **Nuevo skill:** `skills/export-config/SKILL.md`.
- `global/commands/forge.md` — Agregar `export` al dispatcher (16º subcomando).
- `global/sync.sh` — Agregar symlink del nuevo skill.

**Impacto: BAJO para lo existente, ALTO en complejidad propia.** Tiene que parsear rules, CLAUDE.md, settings.json y traducirlos a formatos externos (.cursorrules, AGENTS.md, .windsurfrules). Si esos formatos cambian, el export se rompe. Mayor superficie de mantenimiento externo del roadmap.

---

### 8. Bootstrap profiles (minimal / standard / full)

**Archivos impactados:**
- `skills/bootstrap-project/SKILL.md` — Reescritura significativa. Hoy es flujo lineal de 12 pasos. Hay que condicionarlo: minimal salta pasos 6-10 (agents, commands, agent-memory); full agrega extras.
- `template/CLAUDE.md.tmpl` — Secciones `<!-- forge:section -->` pasan a ser opcionales según profile.
- `skills/audit-project/SKILL.md` — Leer profile del proyecto y ajustar qué items evalúa.
- `audit/scoring.md` — Agregar variantes de cálculo por profile.
- `skills/sync-template/SKILL.md` — No agregar agents a proyecto `minimal`.
- `.forge-manifest.json` — Registrar profile elegido.

**Dependencia:** Habilita Project tier (item 9).
**Impacto: ALTO.** Toca los 3 skills más importantes (bootstrap, audit, sync) y la lógica de scoring. Cambio más transversal del roadmap.

---

### 9. Project tier en audit

**Archivos impactados:**
- `audit/checklist.md` — Items 6-11 (recomendados) pasan a ser condicionales según tier.
- `audit/scoring.md` — Agregar tier detection (LOC, stacks, CI config) y modificar qué items son obligatorios vs recomendados.
- `skills/audit-project/SKILL.md` — Agregar auto-detección de tier.
- `registry/projects.yml` — Agregar campo `tier` por proyecto.

**Riesgo:** Scores históricos pierden comparabilidad (de nuevo). Decidir si se muestra `8.0 (simple)` o se normaliza.
**Impacto: MEDIO.**

---

### 10. Stack devcontainer

**Archivos impactados:**
- **Nuevo:** `stacks/devcontainer/` con rules, settings.json.partial, y `devcontainer.json.tmpl`.
- `stacks/detect.md` — Agregar detección de `.devcontainer/` existente.

**Impacto: BAJO.** Stack modular. Precedente nuevo: stack de *infraestructura* (no de tecnología).

---

## v1.4.0 — Distribution & Plugin

### 11. Plugin packaging

**Archivos impactados:**
- **Nuevo:** `.claude-plugin/plugin.json` con metadata.
- Potencial reorganización para separar lo que va al plugin de lo que no.
- `global/sync.sh` — Sigue funcionando como alternativa.

**Dependencia:** Requiere plugin system estable de Claude Code (ver práctica en inbox).
**Impacto: MEDIO.** Riesgo de mantener dos canales de distribución.

---

### 12. Stacks como plugins independientes

**Archivos impactados:**
- Cada `stacks/*/` necesitaría su propio `plugin.json`.
- Resolver composición: ¿quién mergea settings.json.partial de 3 stack-plugins?
- `skills/bootstrap-project/SKILL.md` — Detectar tanto stacks locales como stack-plugins instalados.

**Impacto: ALTO en diseño.** Rompe asunción fundamental: hoy stacks son carpetas en el repo. Con plugins independientes, tienen que ser descubribles externamente. Cambio arquitectónico.

---

## v1.5.0 — Intelligence & Analytics

### 13. `/forge insights`

**Archivos impactados:**
- **Nuevo skill:** `skills/session-insights/SKILL.md`.
- `global/commands/forge.md` — Agregar `insights` al dispatcher.
- `practices/inbox/` — El skill genera prácticas automáticamente acá.
- `global/sync.sh` — Symlink del nuevo skill.

**Dependencia:** Funciona mejor si Session Report (item 14) ya existe.
**Impacto: BAJO.** Skill nuevo que lee datos y genera reportes.

---

### 14. Session report en Stop hook

**Archivos impactados:**
- **Nuevo:** `template/hooks/session-report.sh` (Stop event).
- `template/settings.json.tmpl` — Agregar hook Stop con variable `FORGE_SESSION_REPORT`.
- `skills/bootstrap-project/SKILL.md` — Copiar hook si `FORGE_SESSION_REPORT=true`.

**Impacto: BAJO.** Hook nuevo, evento nuevo (Stop). Precedente: `detect-claude-changes.sh`.

---

### 15. Scoring trends y alertas

**Archivos impactados:**
- `registry/projects.yml` — Ya tiene campo `history`. Solo leerlo y procesarlo.
- `skills/audit-project/SKILL.md` — Agregar check de delta post-audit: si score bajó >1.5, emitir alerta.
- `global/commands/forge.md` subcomando `status` — Agregar sparkline ASCII.

**Impacto: BAJO.** Datos ya existen. Es lógica de presentación.

---

## Resumen de riesgo por área

| Componente | Items que lo tocan | Riesgo |
|---|---|---|
| `audit/checklist.md` + `scoring.md` | 1, 3, 8, 9 | **ALTO** — 4 items modifican scoring |
| `template/hooks/block-destructive.sh` | 2 | **ALTO** — seguridad crítica |
| `skills/bootstrap-project/SKILL.md` | 2, 5, 8, 10, 14 | **ALTO** — 5 items lo modifican |
| `skills/audit-project/SKILL.md` | 1, 3, 8, 9, 15 | **ALTO** — 5 items lo modifican |
| `skills/sync-template/SKILL.md` | 2, 8 | **MEDIO** |
| `template/rules/agents.md` | 4 | **BAJO** |
| `template/rules/memory.md` | 3 | **BAJO** |
| `stacks/detect.md` | 6, 10 | **BAJO** |
| `global/commands/forge.md` | 7, 13, 15 | **BAJO** — solo agregar subcomandos |
| `registry/projects.yml` | 9, 15 | **BAJO** — agregar campos |

---

## Dependencias entre items

```
Hook profiles (2) ──→ TDD warning hook (5)
                  ──→ Bootstrap profiles (8)
Bootstrap profiles (8) ──→ Project tier en audit (9)
Session report (14) ──→ /forge insights (13)
Plugin packaging (11) ──→ Stacks como plugins (12)
```

## Orden recomendado de implementación

1. **Items independientes primero:** 1, 3, 4, 6, 10 (no dependen de nada)
2. **Hook profiles (2)** — desbloquea 5 y 8
3. **TDD warning (5)** y **Bootstrap profiles (8)** en paralelo
4. **Project tier (9)** — depende de 8
5. **Export (7)** y **Session report (14)** — independientes
6. **Insights (13)** y **Trends (15)** — independientes, mejor después de 14
7. **Plugin packaging (11)** y **Stacks plugins (12)** — al final, dependen de estabilidad externa
