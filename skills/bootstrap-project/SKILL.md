---
name: bootstrap-project
description: Inicializa la configuración de Claude Code en un proyecto nuevo o existente usando la plantilla claude-kit.
---

# Bootstrap Proyecto

Inicializar `.claude/` completo en el proyecto actual usando la plantilla claude-kit.

## Paso 0: Determine profile

Check if $ARGUMENTS contains `--profile minimal`, `--profile standard`, or `--profile full`.
If not specified, use `standard` as default.

**Profiles control what gets installed:**

| Component | minimal | standard | full |
|-----------|---------|----------|------|
| CLAUDE.md | yes | yes | yes |
| settings.json | yes | yes | yes |
| block-destructive hook | yes | yes | yes |
| lint-on-save hook | no | yes | yes |
| session-report hook | no | yes | yes |
| warn-missing-test hook | no | no | yes (strict profile) |
| rules/ (_common + stack) | yes | yes | yes |
| commands/ | no | yes | yes |
| agents/ + orchestration | no | yes | yes |
| agent-memory/ | no | no | yes |
| CLAUDE_ERRORS.md | no | yes | yes (pre-populated) |
| memory.md rule | no | yes | yes |

Save the profile in `.claude/settings.local.json` under `env.FORGE_BOOTSTRAP_PROFILE`.

## Paso 1: Detectar stack

Use detection rules from `$CLAUDE_KIT_DIR/stacks/detect.md`.

## Paso 2: Confirmar con usuario

Mostrar:
```
Profile: {{profile}}
Stack detectado: {{stacks}}
Se creará:
- CLAUDE.md (plantilla base + stack rules)
- .claude/settings.json (permisos base + stack)
- .claude/rules/ (reglas comunes + stack)
- .claude/hooks/ (block-destructive + lint + session-report)  [minimal: solo block-destructive]
- .claude/commands/ (audit, health)                    [minimal: omitido]
- .claude/agents/ + orchestration                      [minimal: omitido]
- CLAUDE_ERRORS.md (vacío, para registro de errores)   [minimal: omitido]

¿Proceder? (sí/no)
```

Adapt the list shown based on the profile (hide components that won't be installed).

## Paso 3: Generar CLAUDE.md

Usar `$CLAUDE_KIT_DIR/template/CLAUDE.md.tmpl` como base.
Reemplazar marcadores:
- `{{PROJECT_NAME}}` → nombre del directorio actual
- `<!-- forge:stack -->` → tecnologías detectadas
- `<!-- forge:commands -->` → comandos de build/test detectados (package.json scripts, Makefile targets, etc.)

## Paso 4: Generar settings.json

1. Cargar `$CLAUDE_KIT_DIR/template/settings.json.tmpl` como base
2. Para **cada** stack detectado, leer `$CLAUDE_KIT_DIR/stacks/{stack}/settings.json.partial`
3. Merge: combinar los arrays `allow` de **todos** los partials con la base (unión de sets, sin duplicados)
4. Merge: combinar los arrays `deny` igualmente
5. Escribir en `.claude/settings.json`

**Multi-stack:** Si se detectan múltiples stacks (ej: python-fastapi + react-vite-ts + docker-deploy), mergear TODOS los partials. Orden no importa — es unión de sets.

## Paso 4b: Validar JSON

Antes de escribir `settings.json`, validar que el JSON generado es válido:

```bash
python3 -c 'import json; json.load(open(".claude/settings.json"))' 2>&1
```

O si aún no se escribió, validar el contenido en memoria/string:
```bash
echo '<json_content>' | python3 -c 'import json,sys; json.load(sys.stdin)'
```

Si la validación falla, mostrar el error exacto y NO escribir el archivo. Corregir el JSON antes de continuar.

## Paso 5: Copiar hooks

1. Copiar `$CLAUDE_KIT_DIR/template/hooks/block-destructive.sh` → `.claude/hooks/` (ALL profiles)
2. If profile is `standard` or `full`: copiar `$CLAUDE_KIT_DIR/template/hooks/lint-on-save.sh`
3. If profile is `standard` or `full`: copiar `$CLAUDE_KIT_DIR/template/hooks/session-report.sh`
4. If profile is `standard` or `full`: copiar `$CLAUDE_KIT_DIR/template/hooks/detect-stack-drift.sh`
5. If profile is `full`: copiar `$CLAUDE_KIT_DIR/template/hooks/warn-missing-test.sh`
5. `chmod +x` all copied hooks

## Paso 6: Copiar rules

1. Copiar `$CLAUDE_KIT_DIR/template/rules/_common.md` → `.claude/rules/`
2. Para cada stack detectado, copiar rules de `$CLAUDE_KIT_DIR/stacks/{stack}/rules/` → `.claude/rules/`

## Paso 6b: Domain knowledge scaffolding

**Only if domain info was provided** (via `/forge init` Q4 or user explicitly requests it during bootstrap).

If any detected stack has a `domain:` field in its rules (e.g., `stacks/trading/rules/trading.md`):
1. Create `.claude/rules/domain/` directory
2. Copy domain-tagged rules from the stack into `.claude/rules/domain/` instead of `.claude/rules/`
3. Show: "Domain stack detected: {{domain}}. Domain rules copied to .claude/rules/domain/"

If the user provided domain description (from init Q4 context):
1. Create `.claude/rules/domain/` directory if not exists
2. Generate 1-3 seed domain rule files based on the described concepts:
   - Each file: frontmatter with `globs:` (domain-specific patterns), `domain:` tag, `last_verified:` (today)
   - Content: key facts, constraints, business rules — concise, imperative, <40 lines each
   - File names: kebab-case matching the domain area (e.g., `jira-api.md`, `agile-metrics.md`)
3. Show generated files to user for confirmation before writing

If neither condition is met, skip this paso entirely — no noise for projects without domain context.

**Important:** Domain rules in `.claude/rules/domain/` are project-owned. They are NOT tracked in the forge manifest and are NOT updated by `/forge sync`.

## Paso 7: Copiar comandos

**Skip if profile is `minimal`.**

Copiar `$CLAUDE_KIT_DIR/template/commands/` → `.claude/commands/`

## Paso 8: Copiar agentes y regla de orquestación

**Skip if profile is `minimal`.**

1. Copiar `$CLAUDE_KIT_DIR/agents/*.md` → `.claude/agents/`
2. Copiar `$CLAUDE_KIT_DIR/template/rules/agents.md` → `.claude/rules/agents.md`

Esto da al proyecto acceso a los 6 subagentes especializados (researcher, architect, implementer, code-reviewer, security-auditor, test-runner) y la regla de orquestación que define cuándo delegar.

## Paso 9: Crear CLAUDE_ERRORS.md

**Skip if profile is `minimal`.**

For `full` profile: pre-populate with the Type column format and example entry.
For `standard` profile: create empty template.

```markdown
# Errores conocidos — {{PROJECT_NAME}}

Registro evolutivo de errores y lecciones aprendidas. Consultar ANTES de trabajar en áreas con errores previos.

Jerarquía de verdad: código fuente > CLAUDE.md > CLAUDE_ERRORS.md > auto-memory

## Formato
| Fecha | Área | Tipo | Error | Causa raíz | Fix | Regla derivada |
|-------|------|------|-------|------------|-----|---------------|

Tipos válidos: `syntax`, `logic`, `integration`, `config`, `security`
```

## Paso 9b: Crear agent-memory/

**Only for `full` profile.** Standard creates the directory but not the seed files.

Create `.claude/agent-memory/` directory for agents with `memory: project` to persist learnings:

```bash
mkdir -p .claude/agent-memory
```

Create a seed file for each memory-enabled agent so the directory structure is ready:
```bash
for agent in implementer architect code-reviewer security-auditor; do
  touch ".claude/agent-memory/${agent}.md"
done
```

This enables implementer, architect, code-reviewer, and security-auditor to accumulate project-specific knowledge across sessions.

## Paso 10: Sugerir hook global

Si el usuario no tiene `detect-claude-changes.sh` instalado en `~/.claude/settings.json`, mostrar:

```
💡 Tip: Para captura automática de prácticas, instalar el hook global:
Copiar hooks/detect-claude-changes.sh a ~/.claude/hooks/
Agregar en ~/.claude/settings.json bajo hooks → Stop
Ver docs para detalles.
```

## Paso 11: Generar manifest

Crear `.claude/.forge-manifest.json` con el hash SHA256 de cada archivo creado durante el bootstrap:

```bash
shasum -a 256 <file> | cut -d' ' -f1
```

Formato:
```json
{
  "claude_kit_version": "<version de $CLAUDE_KIT_DIR/VERSION>",
  "synced_at": "<fecha actual YYYY-MM-DD>",
  "files": {
    ".claude/settings.json": {"hash": "sha256:<hash>", "source": "template+stacks"},
    ".claude/rules/_common.md": {"hash": "sha256:<hash>", "source": "template"},
    ".claude/hooks/block-destructive.sh": {"hash": "sha256:<hash>", "source": "template"},
    ".claude/hooks/lint-on-save.sh": {"hash": "sha256:<hash>", "source": "template"}
  }
}
```

- `source` indica de dónde vino el archivo: `"template"`, `"template+stacks"` (si es merge de base + stacks), o `"stacks/<nombre>"`.
- Incluir TODOS los archivos creados en `.claude/` (rules, hooks, commands, agents).
- NO incluir CLAUDE.md ni CLAUDE_ERRORS.md (están en la raíz, no en `.claude/`).

## Paso 12: Reportar

Mostrar resumen de archivos creados y sugerir ejecutar `/audit-project` para verificar.
