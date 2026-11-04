---
id: practice-2026-11-04-config-protection-behavior
title: Behavior: block edits to existing linter/formatter configs so agents fix code instead of loosening rules
source: "/forge scout — affaan-m/ECC v2.2.3 (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: active
tags: [behaviors, v3, quality, hooks, ecc]
tested_in: []
incorporated_in: ["behaviors/protect-lint-config/", "behaviors/index.yaml", "template/hooks/block-destructive.sh", "tests/test-hooks.sh"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
ECC `scripts/hooks/config-protection.js` exits 2 on any Edit/Write to an existing lint/format config (ESLint, Prettier, ruff, biome, tsconfig strictness, swiftlint, etc.) — the agent must fix the code rather than relax the rule. Also `block-no-verify.js` hard-blocks `git commit --no-verify` and `core.hooksPath` overrides. Both are among the ~5 hooks in ECC that actually enforce anything, and both are cheap, deterministic and have no native Claude Code equivalent.

For dotforge this is a natural v3 behavior: trigger on `Edit|Write` with `file_path` matching a config allowlist, `default_level: soft_block` (reinvocation override allowed — sometimes the config change IS the task), escalation none. `--no-verify` already lives in `block-destructive.sh` deny list candidates.

## Evidence
ECC `scripts/hooks/config-protection.js`, `block-no-verify.js`; `hooks/hooks.json` wiring (PreToolUse `Edit|Write`). dotforge `behaviors/no-destructive-git` covers git only.

## Impact on dotforge
- `behaviors/protect-lint-config/behavior.yaml` (new, category core, default off → opt-in via `/forge behavior on`), compiled hooks, scenario tests
- `template/hooks/block-destructive.sh`: add `--no-verify` and `core.hooksPath=` patterns
- `docs/v3/` catalogue entry; `behaviors/index.yaml`

## Decision
Accepted 2026-11-04 — incorporated in dotforge v4.8.0 (/forge update, ECC scout batch 1).
