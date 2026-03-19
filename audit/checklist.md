# Checklist de Auditoría claude-kit

## Obligatorio (cada item: 0-2 puntos, total máximo: 10)

### 1. CLAUDE.md (0-2)
- 0: No existe
- 1: Existe pero <20 líneas o solo boilerplate
- 2: Completo — incluye stack, arquitectura, comandos build/test, convenciones

### 2. .claude/settings.json (0-2)
- 0: No existe
- 1: Existe pero sin deny list o con permisos excesivos
- 2: Permisos explícitos + deny list de seguridad (.env, *.key, *.pem)

### 3. Rules contextuales (0-2)
- 0: No existen (.claude/rules/ vacío o ausente)
- 1: Existen pero sin frontmatter globs (se aplican siempre)
- 2: Rules con globs específicos por área del proyecto

### 4. Hook block-destructive (0-2)
- 0: No existe
- 1: Existe pero no está configurado en settings.json hooks
- 2: Existe, es ejecutable, y está wired en settings.json PreToolUse

### 5. Comandos build/test documentados (0-2)
- 0: No hay forma de saber cómo buildear/testear
- 1: Están en README pero no en CLAUDE.md
- 2: Documentados en CLAUDE.md con comandos exactos y funcionan

## Recomendado (cada item: 0-1 punto, total máximo: 5)

### 6. CLAUDE_ERRORS.md
- 0: No existe
- 1: Existe con formato para registrar errores

### 7. Hook de lint automático
- 0: No hay lint post-write
- 1: Hook de lint configurado para el stack del proyecto

### 8. Comandos custom (.claude/commands/)
- 0: No hay comandos custom
- 1: Al menos 1 comando custom relevante

### 9. Memory del proyecto
- 0: No hay archivos en .claude/projects/*/memory/
- 1: Existe memoria con contexto útil del proyecto

### 10. Agentes de orquestación
- 0: No hay .claude/agents/ ni regla agents.md
- 1: Agentes instalados + regla de orquestación activa

### 11. .gitignore protege secrets
- 0: No hay .gitignore o no protege .env/secrets
- 1: .gitignore incluye .env, *.key, *.pem, credentials
