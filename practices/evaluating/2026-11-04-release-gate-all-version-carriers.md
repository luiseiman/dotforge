---
id: practice-2026-11-04-release-gate-all-version-carriers
title: Release gate: assert every version carrier + signed tag + green CI before publishing
source: "/forge scout — affaan-m/ECC v2.2.3 (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: evaluating
tags: [release, ci, versioning, ecc]
tested_in: []
incorporated_in: []
replaced_by: null
---

## Description
ECC `release.yml` refuses to publish unless the commit equals `origin/main`, the tag is signed, CI and CodeQL are green on that exact commit, and the version string agrees across 9 carriers (VERSION, package.json, lockfile, plugin.json, marketplace.json, codex/qoder plugin manifests, agent.yaml, the AGENTS.md version line, localized README headings). `tests/plugin-manifest.test.js` holds ~70 assertions on manifest/version consistency.

dotforge compared only VERSION vs plugin.json and shipped v4.1→v4.7 with plugin.json stuck at 4.0.0 — CI red for 4 months, unnoticed because releases were pushed without checking `gh run list`.

## Evidence
ECC `.github/workflows/release.yml`, `scripts/ci/verify-release-gates.js`, `tests/plugin-manifest.test.js`. dotforge fix commit 9fe1360 (2026-10-07).

## Impact on dotforge
- Pending worktree task "Add release script and full version check" (spawned 2026-10-07) should adopt the full carrier list: VERSION, .claude-plugin/plugin.json, marketplace.json (×2), install.sh, README badge, ROADMAP status line, stacks/tdd/plugin.json
- `.github/workflows/ci.yml` version step → loop over carriers; add `gh run list --branch main` green check to the release skill before `git push --follow-tags`
- `_common.md` § Git: extend "confirm CI is green" from PRs to release pushes

## Decision
Pending
