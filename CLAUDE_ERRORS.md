> **[English](#known-errors--dotforge)** | **[Español](#errores-conocidos--dotforge)**

# Known Errors — dotforge

Error log and lessons learned to avoid repeating mistakes.

| Date | Area | Type | Error | Cause | Fix | Rule |
|------|------|------|-------|-------|-----|------|
| 2026-11-04 | hooks | integration | `block-destructive.sh`, `lint-on-save.sh`, `warn-missing-test.sh`, `detect-stack-drift.sh` and all stack lint hooks never fired in real sessions (v0.1.0–v4.8.0) | Read `$TOOL_INPUT` env var; Claude Code delivers hook input only as JSON on stdin, so the command was always empty → exit 0. `tests/test-hooks.sh` injected the env var and masked it | Read `$(cat)` and parse `.tool_input.command` / `.tool_input.file_path`; tests feed stdin with the real payload | Hook tests must invoke the hook exactly as Claude Code does (stdin payload, no env). Verify a security hook live before counting it in the audit |
| 2026-11-04 | hooks | logic | `pre-compact-warning.sh` reported 230% context after the first compaction | Estimated tokens as transcript bytes / 5; the transcript file never shrinks on compaction | Read `message.usage` (`input + cache_creation + cache_read`) of the last non-sidechain assistant turn; window from model id | Never derive context usage from transcript size |
| 2026-03-19 | audit | logic | Checklist counted CLAUDE.md lines instead of verifying sections | Shallow validation | Rewrite checklist to verify section content (Stack, Build, Arch) | Verify content, not existence |
| 2026-03-19 | scoring | logic | No security cap — inflated score when hooks or deny list missing | Permissive formula | Add cap: if item 2 or 4 = 0, max score = 6.0 | Security cap is mandatory |
| 2026-03-19 | stacks | config | docker-deploy and supabase missing settings.json.partial | Incomplete stacks since v0.1 | Create settings.json.partial with per-stack permissions | Every stack needs rules/ + settings.json.partial |
| 2026-03-19 | agents | config | agents.md referenced nonexistent tasks/lessons.md | Phantom reference from original template | Change to CLAUDE_ERRORS.md | Never reference files that don't exist in the template |
| 2026-03-19 | agents | integration | `resume` parameter deprecated in Agent tool | Upstream breaking change | Replace with SendMessage({to: agentId}) | Run /forge watch periodically |
| 2026-03-19 | sync | logic | _common.md duplicated with global CLAUDE.md | No deduplication between layers | Separate: global = behavior, _common.md = code rules | Don't repeat rules across layers |

---

# Errores Conocidos — dotforge

Registro de errores y lecciones aprendidas para no repetir los mismos fallos.

| Fecha | Área | Tipo | Error | Causa | Fix | Regla |
|-------|------|------|-------|-------|-----|-------|
| 2026-11-04 | hooks | integration | `block-destructive.sh`, `lint-on-save.sh`, `warn-missing-test.sh`, `detect-stack-drift.sh` y los lint hooks de stacks nunca dispararon en sesiones reales (v0.1.0–v4.8.0) | Leían la variable `$TOOL_INPUT`; Claude Code entrega el input solo por stdin, el comando quedaba vacío → exit 0. `tests/test-hooks.sh` inyectaba la variable y lo enmascaró | Leer `$(cat)` y parsear `.tool_input.command` / `.tool_input.file_path`; los tests alimentan stdin con el payload real | Los tests de hooks deben invocarlos exactamente como Claude Code (payload por stdin, sin env). Verificar un hook de seguridad en vivo antes de contarlo en el audit |
| 2026-11-04 | hooks | logic | `pre-compact-warning.sh` reportaba 230% de contexto tras la primera compactación | Estimaba tokens como bytes del transcript / 5; el archivo nunca se achica al compactar | Leer `message.usage` del último turno assistant no-sidechain; ventana según el modelo | Nunca derivar el uso de contexto del tamaño del transcript |
| 2026-03-19 | audit | logic | El checklist contaba líneas de CLAUDE.md en vez de verificar secciones | Validación superficial | Reescribir checklist para verificar contenido de secciones (Stack, Build, Arch) | Verificar contenido, no existencia |
| 2026-03-19 | scoring | logic | Sin cap de seguridad — puntaje inflado cuando faltan hooks o deny list | Fórmula permisiva | Agregar cap: si item 2 o 4 = 0, puntaje máximo = 6.0 | El cap de seguridad es obligatorio |
| 2026-03-19 | stacks | config | docker-deploy y supabase sin settings.json.partial | Stacks incompletos desde v0.1 | Crear settings.json.partial con permisos por stack | Todo stack necesita rules/ + settings.json.partial |
| 2026-03-19 | agents | config | agents.md referenciaba tasks/lessons.md inexistente | Referencia fantasma del template original | Cambiar a CLAUDE_ERRORS.md | Nunca referenciar archivos que no existen en el template |
| 2026-03-19 | agents | integration | Parámetro `resume` deprecado en Agent tool | Cambio incompatible upstream | Reemplazar con SendMessage({to: agentId}) | Ejecutar /forge watch periódicamente |
| 2026-03-19 | sync | logic | _common.md duplicado con CLAUDE.md global | Sin deduplicación entre capas | Separar: global = comportamiento, _common.md = reglas de código | No repetir reglas entre capas |
