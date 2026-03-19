---
id: practice-2026-03-19-tradingbot-session-changes
title: "Cambios en .claude/ detectados en TRADINGBOT"
source: "hook post-sesión — TRADINGBOT"
source_type: experience
discovered: 2026-03-19
status: evaluated
tags: [auto-detected, TRADINGBOT]
tested_in: TRADINGBOT
incorporated_in: []
replaced_by: null
---

## Descripción
Se detectaron 10 archivo(s) modificados en .claude/ del proyecto TRADINGBOT durante la sesión.

## Archivos modificados
.claude/hooks/block-destructive.sh
.claude/hooks/lint-python.sh
.claude/hooks/lint-ts.sh
.claude/rules/agents.md
.claude/rules/backend.md
.claude/rules/frontend.md
.claude/rules/strategies.md
.claude/rules/tests.md
.claude/settings.json
.claude/settings.local.json

## Evaluación necesaria
Revisar si estos cambios contienen patrones, reglas, o configuraciones que deberían generalizarse a claude-kit.

## Decisión
Evaluado 2026-03-19. Se extrajeron 6 prácticas generalizables:
1. Permisos git granulares en settings.json (no wildcard)
2. Globs recursivos en deny (**/.env vs .env)
3. Deny adicionales de defensa en profundidad
4. tsc --noEmit como hook complementario a eslint
5. Factory pattern + tests.md dedicado para Python
6. WebSocket/proxy patterns en frontend rules

Incorporados en: template/settings.json.tmpl, stacks/react-vite-ts/hooks/lint-ts.sh,
stacks/python-fastapi/rules/backend.md, stacks/python-fastapi/rules/tests.md (nuevo),
stacks/react-vite-ts/rules/frontend.md, template/hooks/lint-on-save.sh

Descartados: rules/strategies.md (100% dominio trading), agents.md simplificado (subset sin valor nuevo)
