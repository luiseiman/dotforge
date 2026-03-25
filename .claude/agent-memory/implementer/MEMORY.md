# Implementer Agent Memory

- [hooks-settings-schema](feedback_hooks_schema.md) — Claude Code settings.json hooks require object format {type, command}, not strings
- [forge-sync-pattern](project_sync_pattern.md) — Pattern for /forge sync: manifest files dict is informational, only update version/date; preserve any rule not in manifest
- [practices-write-tool](feedback_practices_write.md) — Write tool requires prior Read; use bash cat heredoc for new files in practices/
- [soma2-domain-extract](project_soma2_domain_extract.md) — Sources read, 8 domain rule files created, Role section added to CLAUDE.md
- [soma-domain-extract](project_soma_domain_extract.md) — SOMA (luiseiman/SOMA): 7 domain rule files created, Role section added. Auto-memory at ~/.claude/projects/-Users-luiseiman-Documents-GitHub-SOMA/memory/ is the richest source (arquitectura.md)
- [derup-domain-extract](project_derup_domain_extract.md) — derup ER modeler: 5 domain rule files created, Role section added. CLAUDE_ERRORS.md was richest source. Custom SVG canvas (not React Flow). lint has known violations — use build.
- [openclaw-domain-extract](project_openclaw_domain_extract.md) — openclaw/openclaw: 6 domain rule files created, Role section added. CLAUDE.md (260+ lines) was the only real source; no auto-memory existed. Key: Oxlint+Oxfmt, Bun for TS, 4-point bug-fix merge gate, GHSA PATCH footgun.
- [glob-specificity-fix](feedback_glob_specificity.md) — Wildcard `**/*.md` in domain rule globs defeats purpose; always verify real paths with ls before writing globs.
