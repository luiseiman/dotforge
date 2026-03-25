---
name: forge-sync-pattern
description: Pattern for executing /forge sync — how to detect what changed vs what to preserve
type: project
---

When syncing a project from an old claude-kit version to a new one:

1. Read the manifest `files` dict — it records hashes of template-managed files at last sync time. Files NOT in the manifest are project-custom and must always be preserved.
2. Compare project rule content against template source to detect divergence. Identical = safe to replace. Different = local customization, preserve.
3. For settings.json deny list: union merge (add missing template entries, never remove project-specific ones). Allow list: never touch.
4. New hooks from template go into settings.json PostToolUse/PreToolUse — check if already present by command path before adding.
5. Manifest files dict does NOT need to be updated entry-by-entry during sync — only update `claude_kit_version`, `last_sync`, `synced_at`.

**Why:** The manifest `files` dict is informational for future syncs (detecting drift). Regenerating hashes during sync requires reading each file and computing sha256 — not worth it unless the sync skill explicitly tracks this. Current practice: update only the version/date fields.

**How to apply:** In future sync tasks, focus on content comparison not hash comparison for the preservation decision.
