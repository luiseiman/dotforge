---
name: forge-global-sync
description: Sync global ~/.claude/ config (CLAUDE.md, settings.json, symlinks)
---

Run `/forge global sync`. Sync `~/.claude/CLAUDE.md` against template (preserving content below `<!-- forge:custom -->`), merge deny list into `~/.claude/settings.json`, and run `global/sync.sh` for symlinks.
