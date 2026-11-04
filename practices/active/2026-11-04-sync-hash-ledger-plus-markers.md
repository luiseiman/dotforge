---
id: practice-2026-11-04-sync-hash-ledger-plus-markers
title: /forge sync: add a per-file SHA-256 install ledger alongside forge:custom markers
source: "/forge scout — affaan-m/ECC v2.2.3 (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: active
tags: [sync, manifest, governance, ecc]
tested_in: []
incorporated_in: ["scripts/forge-doctor.sh", "tests/test-forge-doctor.sh", "skills/sync-template/SKILL.md", "skills/diff-project/SKILL.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
ECC records every installed file in `ecc-install-state.json` with `contentSha256`, the resolved module set and the repo commit. `doctor` then classifies each managed file as **intact / drifted / missing / user-owned**, `repair` re-copies only intact-or-missing files, and files ECC never installed are never overwritten (ownership guard, their issue #2964). dotforge `/forge sync` only has `<!-- forge:custom -->` markers inside CLAUDE.md and a `.forge-manifest.json` with coarse hashes — it cannot tell an untouched hook from a locally patched one, which is why dotforge itself ran 6 months behind its own `template/hooks/` without any signal.

Hybrid: keep the markers (partial customization inside a file — ECC cannot do this; one local edit makes the whole file "drifted" and `repair` clobbers it) and add a hash ledger so sync can (a) overwrite silently when the project file still equals the hash it installed, (b) stop and diff when it does not, (c) never touch files it did not create.

## Evidence
ECC `scripts/lib/install-lifecycle.js:1148-1197` (classification), `scripts/lib/install/ownership-guard.js`, `schemas/install-state.schema.json`. dotforge self-review 2026-10-07: `.claude/hooks/*.sh` drifted from template since April with no detection.

## Impact on dotforge
- `skills/sync-template/SKILL.md`, `skills/bootstrap-project/SKILL.md` Step 11 (manifest): record `sha256` per installed file in `.claude/.forge-manifest.json`
- `skills/diff-project/SKILL.md`, `skills/audit-project/SKILL.md`: report intact/drifted/missing per file
- `template/hooks/detect-stack-drift.sh` or a new `forge-doctor.sh`: cheap runtime check against the ledger

## Decision
Accepted 2026-11-04 — incorporated in dotforge v4.8.0 (/forge update, ECC scout batch 1).
