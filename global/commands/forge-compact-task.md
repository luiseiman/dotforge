---
name: forge-compact-task
description: Compact context with dotforge-standardized hint that preserves decisions, files modified, pending TODOs, behaviors disabled, and last commit. Use at ~80% context window instead of waiting for auto-compact.
---

Run the `/compact` slash command with this exact hint:

```
preserve: active task description, files modified this session, decisions made (architecture, security, naming), pending TODOs, behaviors disabled in this session, last commit hash and message. drop: tool output verbose (find, grep, ls dumps), intermediate searches that didn't lead anywhere, redundant explanations.
```

Why a custom hint matters (per evidence from X practitioners): default auto-compact may drop info you know is critical. Passing explicit preservation instructions improves summary fidelity.

When to use this command:
- ~80% of context window (operational threshold from research, not academic 50% nor default 96.7%)
- Between distinct tasks within the same project
- Before a long break (>4h) so the next session resumes with quality summary
- Before delegating to a subagent so the parent context is light

When NOT to use:
- <70% context: summary would lose recent thread
- New project: use `/clear` instead (full reset)
- Switching between unrelated tasks: subagent or `/clear`
