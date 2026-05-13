---
id: practice-2026-05-13-worktree-baseref-fresh-default
title: worktree.baseRef setting flipped default back to "fresh" (v2.1.133)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [worktree, settings, breaking, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
New setting `worktree.baseRef` controls the base of `--worktree`, `EnterWorktree`, and agent-isolation worktrees:

- `"fresh"` (default in v2.1.133+) — branches from `origin/<default>`
- `"head"` (was default in v2.1.128–v2.1.132) — branches from local `HEAD`

```json
{ "worktree": { "baseRef": "head" } }
```

**Subtle breaking**: between v2.1.128 and v2.1.132, `EnterWorktree` carried unpushed local commits into the new worktree. v2.1.133 reverts that behavior — new worktrees now start clean from origin unless the user opts back in.

## Evidence
CHANGELOG v2.1.133: "Added `worktree.baseRef` setting (`fresh` | `head`) to choose whether `--worktree`, `EnterWorktree`, and agent-isolation worktrees branch from `origin/<default>` or local `HEAD`. **Note:** the default `fresh` changes `EnterWorktree`'s base back to `origin/<default>` (it has been local `HEAD` since 2.1.128) — set `worktree.baseRef: \"head\"` to keep unpushed commits in new worktrees".

Anyone who got used to the v2.1.128 behavior and runs Agent Teams will see worktree teammates missing recent work.

## Impact on dotforge
- `.claude/rules/domain/parallel-sessions.md` — document `worktree.baseRef` next to `--worktree`; flag the default flip as a versioned note
- `.claude/rules/agents.md` — Agent Teams section: clarify that `isolation: "worktree"` defaults to `origin/<default>` since v2.1.133
- `template/settings.json.tmpl` — consider documenting the setting with a commented-out default

## Decision
Pending
