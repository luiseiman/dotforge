> **[English](#known-errors--claude-kit)** | **[Español](#errores-conocidos--claude-kit)**

# Known Errors — claude-kit

Error log and lessons learned to avoid repeating mistakes.

| Date | Area | Error | Cause | Fix | Rule |
|------|------|-------|-------|-----|------|
| 2026-03-19 | audit | Checklist counted CLAUDE.md lines instead of verifying sections | Shallow validation | Rewrite checklist to verify section content (Stack, Build, Arch) | Verify content, not existence |
| 2026-03-19 | scoring | No security cap — inflated score when hooks or deny list missing | Permissive formula | Add cap: if item 2 or 4 = 0, max score = 6.0 | Security cap is mandatory |
| 2026-03-19 | stacks | docker-deploy and supabase missing settings.json.partial | Incomplete stacks since v0.1 | Create settings.json.partial with per-stack permissions | Every stack needs rules/ + settings.json.partial |
| 2026-03-19 | agents | agents.md referenced nonexistent tasks/lessons.md | Phantom reference from original template | Change to CLAUDE_ERRORS.md | Never reference files that don't exist in the template |
| 2026-03-19 | agents | `resume` parameter deprecated in Agent tool | Upstream breaking change | Replace with SendMessage({to: agentId}) | Run /forge watch periodically |
| 2026-03-19 | sync | _common.md duplicated with global CLAUDE.md | No deduplication between layers | Separate: global = behavior, _common.md = code rules | Don't repeat rules across layers |

---

# Errores Conocidos — claude-kit

Registro de errores y lecciones aprendidas para no repetir los mismos fallos.

| Fecha | Área | Error | Causa | Fix | Regla |
|-------|------|-------|-------|-----|-------|
| 2026-03-19 | audit | El checklist contaba líneas de CLAUDE.md en vez de verificar secciones | Validación superficial | Reescribir checklist para verificar contenido de secciones (Stack, Build, Arch) | Verificar contenido, no existencia |
| 2026-03-19 | scoring | Sin cap de seguridad — puntaje inflado cuando faltan hooks o deny list | Fórmula permisiva | Agregar cap: si item 2 o 4 = 0, puntaje máximo = 6.0 | El cap de seguridad es obligatorio |
| 2026-03-19 | stacks | docker-deploy y supabase sin settings.json.partial | Stacks incompletos desde v0.1 | Crear settings.json.partial con permisos por stack | Todo stack necesita rules/ + settings.json.partial |
| 2026-03-19 | agents | agents.md referenciaba tasks/lessons.md inexistente | Referencia fantasma del template original | Cambiar a CLAUDE_ERRORS.md | Nunca referenciar archivos que no existen en el template |
| 2026-03-19 | agents | Parámetro `resume` deprecado en Agent tool | Cambio incompatible upstream | Reemplazar con SendMessage({to: agentId}) | Ejecutar /forge watch periódicamente |
| 2026-03-19 | sync | _common.md duplicado con CLAUDE.md global | Sin deduplicación entre capas | Separar: global = comportamiento, _common.md = reglas de código | No repetir reglas entre capas |
