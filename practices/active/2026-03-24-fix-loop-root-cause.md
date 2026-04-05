---
id: practice-2026-03-24-fix-loop-root-cause
name: fix-loop-root-cause
description: Multiple fix commits for same symptom signals unresolved root cause
type: process
source: session-discovery
source_type: audit-gap
tags: [debugging, root-cause, process, python]
date: 2026-03-23
project: cotiza-api-cloud
status: active
tested_in: [cotiza-api-cloud]
incorporated_in: [stacks/python-fastapi/rules/backend.md]
effectiveness: monitoring
error_type: logic
---

## Pattern

When 2+ consecutive fix commits address the same symptom (e.g., service restart loop),
the real root cause is likely deeper (import error, config bug) rather than in the business logic.

## Rule

Before writing a fix for a behavior bug (loop, crash, unexpected state):
1. Check for import/module errors first (`python3 -c "import <module>"`)
2. Check for shadowed packages (`pip3 show <dirname>` for each local package dir)
3. Check for missing env vars or wrong config keys in the affected flow

Only after ruling out infrastructure-level bugs, proceed to fix business logic.

## Evidence

cotiza-api-cloud: service restart loop required 3 commits to resolve.
Root cause was `websocket/` shadowing `websocket-client`, causing pyRofex to fail silently.
The two preceding fix commits (cooldown + retry) addressed symptoms, not the cause.
