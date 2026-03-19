# Changelog — claude-kit

## v1.0.0 (2026-03-19)

### Estable y completo
- 8 stacks con rules + settings.json.partial: python-fastapi, react-vite-ts, swift-swiftui, supabase, docker-deploy, data-analysis, gcp-cloud-run, redis
- 6 hooks ejecutables verificados (template + stacks + global)
- Auditoría con verificación de contenido, chmod, y cap de seguridad
- Sync inteligente con merge de arrays y protección de customizaciones
- Pipeline de prácticas funcional e2e (capture → update → incorporate)
- Documentación completa: README, troubleshooting, creating-stacks, best-practices, security-checklist, prompting-patterns
- Registry con version tracking y last_sync
- practices/inbox vacío (todo procesado)

---

## v0.9.0 (2026-03-19)

### Pipeline de prácticas funcional
- update-practices simplificado: 3 fases (evaluar → incorporar → propagar), eliminada web search automática y deprecación automática
- capture-practice: validación de duplicados contra active/ e inbox/ antes de crear
- detect-claude-changes.sh: instrucciones de instalación completas como comentario
- Flujo e2e: /forge capture → /forge update funciona en una sesión

---

## v0.8.0 (2026-03-19)

### Documentación y onboarding
- README.md con quick start (3 pasos), estructura, tabla de stacks y skills
- docs/troubleshooting.md — 4 problemas comunes con checklist de diagnóstico
- docs/creating-stacks.md — guía completa para crear stacks nuevos

---

## v0.7.0 (2026-03-19)

### Sync inteligente
- Sync reescrito con merge inteligente: unión de sets para allow/deny, preserva hooks y permisos custom
- Dry-run obligatorio antes de aplicar (muestra diff exacto)
- Nunca toca settings.local.json ni secciones `<!-- forge:custom -->`
- Actualiza registry con last_sync y claude_kit_version post-sync
- Score antes/después para verificar mejora
- Template CLAUDE.md.tmpl: nuevo marker `<!-- forge:custom -->` para secciones protegidas

---

## v0.6.0 (2026-03-19)

### Stacks faltantes
- Nuevo stack: **gcp-cloud-run** — rules (Cloud Run, Secret Manager, scaling, logging) + settings.partial
- Nuevo stack: **redis** — rules (Streams, consumer groups, keys, connection pool) + settings.partial
- Bootstrap y audit detectan los 8 stacks (python-fastapi, react-vite-ts, swift-swiftui, supabase, data-analysis, docker-deploy, gcp-cloud-run, redis)
- 8/8 stacks con rules + settings.json.partial completos

---

## v0.5.0 (2026-03-19)

### Auditoría que audite de verdad
- Checklist: CLAUDE.md ahora verifica secciones clave (stack, build, arquitectura), no solo líneas
- Checklist: hooks verifican chmod +x y wiring en settings.json
- Scoring: cap de 6.0 si falta settings.json o block-destructive (seguridad crítica)
- Skill audit-project: verifica ejecutabilidad de hooks, reporta claude_kit_version
- Registry: nuevos campos `claude_kit_version` y `last_sync` por proyecto
- Detección de stacks nuevos: gcp-cloud-run y redis

---

## v0.4.0 (2026-03-19)

### Completar lo roto
- settings.json.partial para docker-deploy (docker, docker-compose)
- settings.json.partial para supabase (supabase CLI)
- Hook lint-swift.sh para swift-swiftui (swiftlint + swift build fallback)
- Pipeline de prácticas: directorios evaluating/, active/, deprecated/ creados
- Práctica TRADINGBOT movida a active/ con incorporated_in completo
- Práctica gestion-de-mora descartada (solo config local)
- Bootstrap skill: soporte multi-stack explícito + sugerencia de hook global
- 6/6 stacks ahora tienen settings.json.partial

---

## v0.3.0 (2026-03-19)

### Multi-Agent Orchestration
- 6 agentes especializados: researcher, architect, implementer, code-reviewer, security-auditor, test-runner
- Regla de orquestación global (agents.md) con decision tree de delegación
- Agentes instalados globalmente via symlink (~/.claude/agents/)
- Cadenas de agentes: feature, bug fix, security audit, refactor
- Soporte para Agent Teams (experimental, requiere Opus)
- Template y bootstrap actualizados para incluir agentes
- Checklist de auditoría incluye verificación de agentes

---

## v0.2.0 (2026-03-19)

### Pipeline de prácticas
- practices/ con ciclo de vida: inbox → evaluating → active → deprecated
- Skill capture-practice para registrar insights manuales
- Skill update-practices reescrito con pipeline de 5 fases
- Comando /forge capture, /forge inbox, /forge pipeline
- Hook Stop global: detecta cambios en .claude/ y los registra en inbox
- Scheduled task forge-weekly-update (lunes 9:15 AM)

---

## v0.1.0 (2026-03-19)

### Inicial
- Template base: CLAUDE.md.tmpl, settings.json.tmpl, rules/_common.md
- Hooks: block-destructive.sh, lint-on-save.sh
- Stacks: python-fastapi, react-vite-ts, swift-swiftui, supabase, data-analysis, docker-deploy
- Skills: audit-project, bootstrap-project, sync-template, update-practices
- Comando global: /forge (audit, sync, bootstrap, status, update)
- Auditor: checklist.md, scoring.md
- Registry: 7 proyectos registrados
- Docs: best-practices, prompting-patterns, security-checklist, x-references, anatomy-claude-md
- Comandos template: review, debug, audit, health
