---
id: block-destructive-compound-bash
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-04-15
tags: [security, hooks, block-destructive, audit, high-priority]
tested_in: []
incorporated_in: [v3.1.0]
---

# Audit block-destructive.sh against compound-bash bypass (CVE-class fix in v2.1.98)

## Observation

Changelog v2.1.98 (2026-04-09) explicitly mentions:
> Fixed Bash tool permission bypass vulnerability
> Fixed compound Bash commands bypassing permission prompts

This means before v2.1.98, commands like `ls && rm -rf /tmp/foo` or
`echo ok; rm -rf *` could slip past pattern-based hooks that only matched the
first token. The Claude Code core was patched, but **dotforge's
`template/hooks/block-destructive.sh`** uses its own pattern matching and may
have the same blind spot.

## Required verification

1. Read `template/hooks/block-destructive.sh`
2. Confirm it matches destructive patterns ANYWHERE in the command string,
   not just at the start
3. Test cases that MUST be blocked:
   - `ls && rm -rf /`
   - `echo ok; rm -rf *`
   - `cd /tmp && git push --force origin main`
   - `(cd / && DROP TABLE users)`
   - `true || rm -rf $HOME`
4. If any pass, harden the regex / split on `&&`, `||`, `;`, `|`, `\``, `$()`

## Action

After verification:
- If hook is already safe → document it in a comment block in the script
- If gap found → patch + add tests under `tests/hooks/` + bump dotforge version

## Affected files
- `template/hooks/block-destructive.sh` (and any stack-specific copies)
- Possibly `tests/hooks/block-destructive.test.sh` (new)
