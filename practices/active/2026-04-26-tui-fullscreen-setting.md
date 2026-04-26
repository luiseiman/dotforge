---
id: practice-2026-04-26-tui-fullscreen-setting
title: tui setting and /tui command for flicker-free rendering (v2.1.110)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [settings, ui, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
New `tui` setting in `settings.json` accepts `"fullscreen"` or `"default"`. The `/tui` slash command toggles between modes mid-session without losing the conversation. Fullscreen mode renders without flicker — useful in long sessions and inside tmux/zellij. Available since v2.1.110.

## Evidence
CHANGELOG v2.1.110: "Added `/tui` command and `tui` setting — run `/tui fullscreen` to switch to flicker-free rendering in the same conversation".

dotforge's `.claude/rules/domain/context-control-patterns.md` references focus mode and `Ctrl+O`/`/focus`, but never the fullscreen TUI mode.

## Impact on dotforge
- `template/settings.json.tmpl` — optional default depending on user preference (likely keep at `default` to avoid surprising users)
- `.claude/rules/domain/context-control-patterns.md` — add brief subsection on TUI modes (fullscreen vs default, when to use each)
- `docs/best-practices.md` — mention `/tui fullscreen` for long-running interactive sessions

## Decision
Pending
