# Errores Conocidos — claude-kit

Registro de errores y lecciones aprendidas para evitar repetirlos.

| Fecha | Área | Error | Causa | Fix | Regla |
|-------|------|-------|-------|-----|-------|
| 2026-03-19 | audit | Checklist contaba líneas de CLAUDE.md en vez de verificar secciones | Validación superficial | Reescribir checklist para verificar contenido de secciones (Stack, Build, Arch) | Verificar contenido, no existencia |
| 2026-03-19 | scoring | Sin security cap — score inflado si faltaban hooks o deny list | Fórmula permisiva | Agregar cap: si item 2 o 4 = 0, max score = 6.0 | Security cap obligatorio |
| 2026-03-19 | stacks | docker-deploy y supabase sin settings.json.partial | Stacks incompletos desde v0.1 | Crear settings.json.partial con permisos por stack | Todo stack necesita rules/ + settings.json.partial |
| 2026-03-19 | agents | agents.md referenciaba tasks/lessons.md inexistente | Referencia fantasma desde template original | Cambiar a CLAUDE_ERRORS.md | No referenciar archivos que no existen en la plantilla |
| 2026-03-19 | agents | Parámetro `resume` deprecado en Agent tool | Upstream breaking change | Reemplazar por SendMessage({to: agentId}) | Correr /forge watch periódicamente |
| 2026-03-19 | sync | _common.md se duplicaba con CLAUDE.md global | Sin deduplicación entre capas | Separar: global = comportamiento, _common.md = código | No repetir reglas entre capas |
