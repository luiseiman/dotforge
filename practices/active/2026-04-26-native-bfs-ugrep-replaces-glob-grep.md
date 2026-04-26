---
id: practice-2026-04-26-native-bfs-ugrep-replaces-glob-grep
title: Native macOS/Linux builds replace Glob/Grep tools with bfs/ugrep via Bash (v2.1.117)
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [tools, hooks, performance, upstream, breaking]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
On native macOS and Linux Claude Code builds, the standalone `Glob` and `Grep` tools are replaced by embedded `bfs` and `ugrep` binaries reachable through the `Bash` tool. Faster (no separate tool round-trip) but the tools no longer appear as separate matchable surfaces. Windows and npm-installed builds keep the original `Glob`/`Grep` tools.

Since v2.1.117.

## Evidence
CHANGELOG v2.1.117: "Native builds on macOS and Linux: the `Glob` and `Grep` tools are replaced by embedded `bfs` and `ugrep` available through the Bash tool — faster searches without a separate tool round-trip (Windows and npm-installed builds unchanged)".

## Impact on dotforge
- `.claude/rules/domain/auto-mode.md` — the tool concurrency table lists `Glob`/`Grep` as separate concurrent-safe tools; on native builds they fold into `Bash` and inherit Bash's "not concurrent-safe" classification
- Any hook with `matcher: "Glob"` or `matcher: "Grep"` will silently never fire on native builds (regression risk if dotforge ships such matchers)
- `template/settings.json.tmpl` and `stacks/*/settings.json.partial` — audit `permissions.allow`/`deny`/`ask` for `Glob(...)` or `Grep(...)` rules; they become inert on native builds
- `.claude/rules/domain/permission-model.md` — document that Glob/Grep specifiers are platform-dependent

## Decision
Pending
