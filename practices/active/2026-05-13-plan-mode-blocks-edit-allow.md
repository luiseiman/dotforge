---
id: practice-2026-05-13-plan-mode-blocks-edit-allow
title: Plan mode correctly blocks file writes even with Edit() allow rule (v2.1.136 fix)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [permissions, plan-mode, security-fix, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
Bug fix in v2.1.136: previously a `permissions.allow: ["Edit(*)"]` rule would bypass plan mode's read-only enforcement, letting the model write files while supposedly planning. Now plan mode's read-only constraint takes precedence over allow rules — Edit/Write are blocked in plan mode regardless of explicit allows.

## Evidence
CHANGELOG v2.1.136: "Fixed plan mode not blocking file writes when a matching `Edit(...)` allow rule exists".

This means the documented evaluation cascade in `.claude/rules/domain/permission-model.md` was technically misleading before — the cascade listed plan-mode as later than allow rules, but reality didn't enforce that. Now they match.

## Impact on dotforge
- `.claude/rules/domain/permission-model.md` — verify the documented evaluation cascade is now accurate; if dotforge's cascade order has plan-mode BEFORE allow rules, this fix confirms it. If AFTER, the doc needs flipping.
- Audit any project (especially `cotiza-api-cloud`, `TRADINGBOT`) that relies on plan mode for guardrails — pre-fix behavior may have been their actual experience; post-fix they should see plan mode strictly read-only.

## Decision
Pending
