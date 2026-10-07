---
id: practice-2026-10-06-permission-bypasses-fixed-v2221-v2290
title: Bash permission-detection bypasses fixed and prompts tightened (v2.1.221–v2.1.290) — extends the v2.1.145–149 section
source: "/forge watch — CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: evaluating
tags: [permissions, security, bash, prefix-detection]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
Fixed bypasses: zsh `[[ ]]` regex (v2.1.221); hidden/padded commands (v2.1.223); zsh conditional syntax (v2.1.238); dangling `&&`/`||` always prompts (v2.1.246); arithmetic assignment to integer vars (`OPTIND=1/0`, `RANDOM=2+2`) no longer auto-approved (v2.1.252); deny/ask rules apply behind `TZ="$HOME" rm …` and other variable prefixes under sandbox auto-allow (v2.1.288); PreToolUse `updatedInput` re-checked against all rules + safety checks (v2.1.290); `permissions.ask` inside compound/subshell in auto mode (v2.1.257); Read deny covers pasted image paths and symlinks (v2.1.274).
Forced prompts: `rg` / `git grep` with shell-expanded wildcards, zsh-specific variable names, `ps`, `pyright`, variable-name prefixes on `declare`/`export`/`readonly`, `tee` (v2.1.268–290).
Rule hygiene: startup warning for allow rules with wildcard before the subcommand, e.g. `Bash(git * main)` — also matches options inserted before the subcommand (v2.1.246); rules with text after `)` reported invalid (v2.1.260); `!`-prefixed deny/ask rule applies only within its own settings source (v2.1.269); `/commit-push-pr` git/gh with `--force`/`--amend`/`--no-verify` no longer auto-approved (v2.1.229); classifier cannot be fooled by `status.showUntrackedFiles=no` (v2.1.237); auto mode blocks transcript tampering and asks before `rm -rf` on unresolved variables (W28).

## Evidence
`permission-model.md:66-72` has a "bypasses fixed in v2.1.145-149" section only. Grep of `template/`, `stacks/`, `global/` found no wildcard-before-subcommand rules (only `PYTHONPATH=* pytest *`, `open *.xcodeproj`) — but `/forge audit` has no check for it.

## Impact on dotforge
- `.claude/rules/domain/permission-model.md`: new "bypasses fixed v2.1.221–290" section + rule-hygiene list
- `skills/audit-project/SKILL.md` + `audit/checklist.md` + `audit/score.sh` + `scripts/audit_all.py`: lint allow rules for wildcard-before-subcommand and trailing text after `)`
- `template/hooks/block-destructive.sh`: `--amend`/`--no-verify` now natively gated in `/commit-push-pr` only — keep hook for general Bash

## Decision
Pending
