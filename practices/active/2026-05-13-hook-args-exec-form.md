---
id: practice-2026-05-13-hook-args-exec-form
title: Hooks accept args array (exec form) — spawns without shell, no quoting (v2.1.139)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [hooks, upstream, security]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
Hook config now accepts an `args: string[]` field (exec form) alongside `command`. When `args` is provided, the harness spawns the executable directly via `execve` without going through a shell. Path placeholders and arguments with spaces no longer need quoting.

```json
{
  "type": "command",
  "command": ".claude/hooks/validate.sh",
  "args": ["${tool_input.file_path}", "--strict"]
}
```

vs the older shell-interpolated form:
```json
{
  "type": "command",
  "command": ".claude/hooks/validate.sh \"${tool_input.file_path}\" --strict"
}
```

## Evidence
CHANGELOG v2.1.139: "Added hook `args: string[]` field (exec form) that spawns the command directly without a shell, so path placeholders never need quoting".

Eliminates an entire class of bugs: spaces in filenames, weird characters in tool inputs, shell injection via crafted payloads. Safer default for any hook that consumes `${tool_input.*}`.

## Impact on dotforge
- `.claude/rules/domain/hook-architecture.md` — document exec form alongside command form; recommend exec form when interpolating user-controlled values
- `template/settings.json.tmpl` — audit hooks that interpolate `${tool_input.*}` (currently none use substitution there, so no migration needed yet — but future template-shipped hooks should default to exec form)
- `docs/best-practices.md` — capture pattern for hook authors

## Decision
Pending
