---
id: practice-2026-04-06-edit-tool-shorter-anchors
title: "Edit tool uses shorter old_string anchors — reduces output tokens"
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-04-06
status: inbox
tags: [performance, tokens, edit-tool]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Descripción
v2.1.91 changed the Edit tool to use shorter `old_string` anchors when computing diffs, reducing output token consumption for edits. No action needed from users — this is an internal efficiency improvement. However, prompting strategies that assumed long `old_string` context (e.g., asking Claude to include surrounding lines) may no longer be necessary.

## Evidencia
Official changelog v2.1.91: "Edit tool now uses shorter `old_string` anchors, reducing output tokens."

## Impacto en claude-kit
- `docs/best-practices.md` — minor: remove or update any recommendation to include extra context in old_string for edit precision
- No template changes needed

## Decisión
Pendiente
