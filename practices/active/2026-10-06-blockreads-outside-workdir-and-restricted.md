---
id: practice-2026-10-06-blockreads-outside-workdir-and-restricted
title: permissions.blockReadsOutsideWorkingDirectories and --restricted mode (v2.1.248, v2.1.257+)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291 + docs/en/cli"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [permissions, security, sandbox, production-tier, cli]
tested_in: []
incorporated_in: [".claude/rules/domain/permission-model.md", ".claude/rules/domain/cli-flags.md"]
replaced_by: null
effectiveness: monitoring
error_type: security
---

## Description
- `permissions.blockReadsOutsideWorkingDirectories` (v2.1.257): denies reads outside working dirs; auto mode prompts on first outside read. 12+ follow-up fixes through v2.1.290 cover compound Bash, `cd`+`git` chains, memory dirs, symlinked CLAUDE.md/rules/AGENTS.md, pasted image paths, `sandbox.credentials.files` on git config.
- `--restricted` / `CLAUDE_CODE_RESTRICTED=1` (v2.1.248): removes command/code-running tools and WebFetch unless named in `--tools`; confines file tools to working dirs; loads only managed settings + `--settings`; refuses `bypassPermissions`; refuses cloud sessions. For eval harnesses on shared machines.
- `--permission-prompts none` (v2.1.259): in `-p` mode, anything that would prompt is denied while the active mode keeps deciding (compare `dontAsk`).
- Native dangerous-`rm` guard now runs in auto AND bypass modes (v2.1.261/281): `rm` on `/`, `~`, `$VAR`, `"$(pwd)"`, `bash -c` scripts flagged; unanswered prompt denied after 2 min. Opt-outs: `CLAUDE_CODE_DISABLE_DANGEROUS_RM_TIMEOUT=1`, `CLAUDE_CODE_DISABLE_SUBSTITUTION_RM_PROMPT=1`.

## Evidence
0 grep hits in dotforge for `blockReadsOutsideWorkingDirectories`, `--restricted`, `--permission-prompts`. `template/hooks/block-destructive.sh` now overlaps the native `rm` guard — native-first boundary question.

## Impact on dotforge
- `.claude/rules/domain/permission-model.md`: new setting + `--restricted` as a hardening mode + native rm guard section
- `stacks/trading/`, `stacks/supabase/`, `stacks/docker-deploy/` `settings.json.partial`: evaluate adding `blockReadsOutsideWorkingDirectories: true` for production tier
- `.claude/rules/domain/cli-flags.md`: `--restricted`, `--permission-prompts`
- `.claude/rules/domain/native-vs-dotforge-boundary.md`: block-destructive.sh vs native rm guard (keep for non-rm patterns: force-push, DROP, chmod 777)

## Decision
Accepted 2026-10-07 — incorporated in dotforge v4.5.0 (/forge update, security block).
