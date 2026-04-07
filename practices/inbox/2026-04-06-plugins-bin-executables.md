---
id: practice-2026-04-06-plugins-bin-executables
title: "Plugins can ship executables under bin/"
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-04-06
status: inbox
tags: [plugins, distribution, extensibility]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Descripción
As of v2.1.91, plugin packages can include a `bin/` directory with executables that are made available in PATH during skill/hook execution. This allows plugins to ship compiled helpers, scripts, or CLIs alongside their markdown instructions without requiring the user to install dependencies separately.

## Evidencia
Official changelog v2.1.91: "Plugins can ship executables under `bin/` directory."

## Impacto en claude-kit
- `skills/` and `template/` — document bin/ convention for plugin-packaged tools
- `docs/best-practices.md` — add note in Skills section about bundling executables
- `plugin-generator` skill — should scaffold bin/ directory when relevant

## Decisión
Pendiente
