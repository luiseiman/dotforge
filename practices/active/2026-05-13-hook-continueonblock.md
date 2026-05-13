---
id: practice-2026-05-13-hook-continueonblock
title: PostToolUse hooks support continueOnBlock for non-fatal feedback (v2.1.139)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [hooks, upstream, behavior-design]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
PostToolUse hook config now accepts `continueOnBlock: true`. When set, a `decision: "block"` does NOT stop the turn — instead the hook's `reason` is fed back to Claude as feedback and the turn continues. Changes the contract of PostToolUse from "fatal stop on block" to "feedback loop on block".

```json
{
  "type": "command",
  "command": ".claude/hooks/lint-on-save.sh",
  "continueOnBlock": true
}
```

## Evidence
CHANGELOG v2.1.139: "Added hook `continueOnBlock` config option for `PostToolUse` — set to `true` to feed the hook's rejection reason back to Claude and continue the turn".

Game-changer for validation hooks: a lint failure no longer kills the agent's flow; the model sees the error and retries with the fix in the same turn.

## Impact on dotforge
- `.claude/rules/domain/hook-architecture.md` — document the new field under PostToolUse decision control
- `.claude/rules/domain/hook-events.md` — note the dual semantics (with/without `continueOnBlock`)
- `template/hooks/lint-on-save.sh` + `template/hooks/detect-stack-drift.sh` — candidates for opt-in to `continueOnBlock: true` so lint failures self-heal instead of halting

## Decision
Pending
