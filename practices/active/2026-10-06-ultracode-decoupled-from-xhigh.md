---
id: practice-2026-10-06-ultracode-decoupled-from-xhigh
title: Ultracode is its own /effort toggle, no longer forces xhigh (v2.1.284)
source: "/forge watch — Claude Code CHANGELOG v2.1.219–v2.1.291"
source_type: upstream
discovered: 2026-10-06
status: active
tags: [ultracode, workflows, effort, policy, breaking-change]
tested_in: []
incorporated_in: [".claude/rules/domain/workflow-automation.md", ".claude/rules/domain/model-ids.md", ".claude/rules/domain/workflow-and-ultracode-policy.md"]
replaced_by: null
effectiveness: monitoring
error_type: config
---

## Description
v2.1.284: Ultracode became its own toggle in `/effort` (Tab, or `/effort ultracode [on|off]`). It no longer forces `xhigh` effort and stays on at any effort level. `--effort ultracode` CLI flag still "requests xhigh with ultracode on" per cli docs — the in-session toggle is the decoupled path. Related: `workflowSizeGuideline` setting (default "medium", <15 agents, v2.1.219), `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS` (1–256), `CLAUDE_CODE_WORKFLOW_PREFIX_STAGGER_MS`, Workflow tool description cut to ~1K tokens with the script reference moved to the bundled `workflow-authoring` skill (v2.1.248). Workflow `import()` sandbox escape fixed (v2.1.223).

## Evidence
`workflow-automation.md:141` says ultracode "combines `xhigh` reasoning effort with automatic workflow orchestration". `model-ids.md:39` and `workflow-and-ultracode-policy.md` activation table describe the same coupling and recommend `/effort ultracode` as the tier activator.

## Impact on dotforge
- `.claude/rules/domain/workflow-automation.md`: § Runtime activation + settings
- `.claude/rules/domain/model-ids.md`: effort levels paragraph
- `.claude/rules/domain/workflow-and-ultracode-policy.md`: tier → runtime table (production tier may want `/effort xhigh` + `ultracode on` as two explicit steps)
- `.claude/rules/domain/workflow-economics.md`: "~80K tokens per agent overhead" figure predates the 1K-token tool description — re-measure before citing

## Decision
Accepted 2026-10-06 — incorporated in dotforge v4.4.0 (/forge update, breaking batch).
