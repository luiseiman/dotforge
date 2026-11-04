---
id: practice-2026-11-04-ci-validators-ported-from-ecc
title: Port five cheap CI validators: unicode smuggling, cross-refs, agent frontmatter, README counts, personal paths
source: "/forge scout — affaan-m/ECC v2.2.3 (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [ci, validation, security, ecc]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
ECC `scripts/ci/` ships validators that would have caught two defects found in dotforge on 2026-10-07:
1. `check-unicode-safety.js` — reject zero-width, bidi, variation-selector and Unicode Tag-block characters in `.md/.sh/.json` (ASCII-smuggling prompt injection)
2. `validate-commands.js:125-172` — every `/cmd`, `agents/x.md`, `skills/x/` reference in a command resolves (strip code blocks first)
3. `validate-agents.js` — agent frontmatter has `model` ∈ {haiku, sonnet, opus, fable} and `tools` as a scalar; unknown keys flagged (would have caught `allowed-tools:` being ignored on 7 agents)
4. `catalog.js --check` — counts stated in README/AGENTS.md match files on disk (dotforge README said 18 stacks / 21 skills; actual 17 / 19)
5. `validate-no-personal-paths.js` + `validate-workflow-security.js` — no `/Users/<name>` paths in shipped files; no `pull_request_target` workflow checks out PR head

None measure tokens; see the separate metadata-budget practice.

## Evidence
ECC `scripts/ci/*.js`, `package.json` `test:validators`. dotforge `tests/run_all.sh` (19 suites) has lint-rules and skills-index but none of the five.

## Impact on dotforge
- New `tests/validate-config.py` (python3, no deps) implementing the five checks over `agents/`, `skills/`, `global/commands/`, `template/`, `README.md`
- Wire into `tests/run_all.sh` and `.github/workflows/ci.yml`
- Frontmatter check must encode the sub-agents doc: `tools`/`disallowedTools` valid, `allowed-tools` invalid on agents (skills only)

## Decision
Pending
