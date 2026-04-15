---
id: granular-ask-permissions
source: scout:shanraisshan/claude-code-best-practice
status: active
captured: 2026-04-13
tags: [permissions, settings, safety, template]
tested_in: []
incorporated_in: [v3.1.0]
---

# Granular `ask:` permission list for template settings

## Observation

`shanraisshan/claude-code-best-practice/.claude/settings.json` defines a broad
`ask:` list that intercepts legitimate-but-risky commands without denying them
outright. Our current `template/settings.json.tmpl` only uses `allow:` + `deny:`
— nothing in `ask:`. This leaves a gap: commands like `rm <file>`, `chmod`,
`npm install`, `docker run`, `kubectl apply`, `gcloud …` run under default
semantics (either auto-allowed via a broad rule or prompted only on unknowns).

## Pattern observed

```json
"ask": [
  "Bash(rm *)", "Bash(rmdir *)", "Bash(shred *)", "Bash(unlink *)",
  "Bash(dd *)", "Bash(mkfs *)", "Bash(fdisk *)",
  "Bash(chmod *)", "Bash(chown *)",
  "Bash(npm *)", "Bash(pip *)", "Bash(pip3 *)", "Bash(yarn *)", "Bash(pnpm *)",
  "Bash(docker *)", "Bash(kubectl *)", "Bash(firebase *)", "Bash(gcloud *)",
  "Bash(wget *)",
  "Bash(kill *)", "Bash(killall *)", "Bash(pkill *)"
]
```

## Why it could matter for dotforge

- Complements `block-destructive.sh`: `deny:` catches catastrophic patterns
  (`rm -rf /`), `ask:` catches "probably-fine-but-confirm" (`rm foo.txt`,
  `chmod +x …`, `npm install <pkg>`).
- Package-manager installs are a supply-chain surface — asking once per session
  is cheap insurance.
- Cloud CLIs (`gcloud`, `kubectl`, `firebase`) touch shared infra: confirming
  is consistent with the "shared-state actions warrant confirmation" rule in
  Claude Code's defaults.
- Our audit currently caps score at 6.0 when `block-destructive` is missing —
  `ask:` is a second, softer defense layer that would raise the floor.

## Open questions before incorporating

1. Does `ask:` in default mode interact well with our `auto` mode users? Auto
   mode strips broad allow rules but `ask:` should survive — verify.
2. Per-stack overrides: stacks like `docker-deploy` or `gcp-cloud-run` may want
   to *allow* `docker *` / `gcloud *` after bootstrap (they're core workflow
   tools). `ask:` in base + `allow:` override in stack partial — confirm merge
   semantics preserve stack-level allow over base-level ask.
3. `npm *` / `pip *` under a stack like `react-vite-ts` or `python-fastapi` —
   same question: is the friction acceptable, or does the stack override?
4. Should the list be opt-in via a profile (`--profile strict`) rather than
   default?

## Proposed action

- Not incorporate blindly. First: resolve (1)-(3) empirically in a test
  project. Then: draft a `strict` profile variant of `settings.json.tmpl` that
  adds the `ask:` block; leave `standard` profile unchanged.
- Promote to `evaluating/` once the profile split is prototyped.

## Source

https://github.com/shanraisshan/claude-code-best-practice/blob/main/.claude/settings.json
