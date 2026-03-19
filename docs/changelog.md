# Changelog — claude-kit

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
