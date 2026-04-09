---
id: practice-2026-04-06-disable-skill-shell-execution
title: "disableSkillShellExecution setting for locked-down envs"
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-04-06
status: active
tags: [skills, security, settings]
tested_in: null
incorporated_in: [".claude/rules/domain/auto-mode.md"]
replaced_by: null
effectiveness: not-applicable
---

## Descripción
v2.1.91 added `disableSkillShellExecution` — a settings.json flag that prevents skills from executing inline shell commands. Useful for production/CI environments where skill execution should be read-only or audited.

## Evidencia
Official changelog v2.1.91 (April 2, 2026): "Added `disableSkillShellExecution` setting to disable inline shell execution."

## Impacto en claude-kit
- `template/settings.json` — document as optional flag with comment
- `docs/best-practices.md` — add to security section alongside existing YOLO-mode stripping note
- `stacks/*/` — CI/CD stack profiles should consider enabling this by default

## Decisión
Incorporado en auto-mode.md durante v2.9.0 upstream alignment.
