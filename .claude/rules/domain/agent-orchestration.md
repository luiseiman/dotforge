---
globs: "**/agents/*.md,**/rules/agents.md"
description: "Agent delegation patterns and team coordination"
domain: claude-code-engineering
last_verified: 2026-03-25
---

# Agent Orchestration

- Decision tree: 1-file fix → direct. Research-heavy → researcher. Code+tests → implementer
- Multi-component (>3 files, >2 concerns, >15 min estimated) → Agent Team
- Agent Team: Lead (coordinates, does NOT implement) + max 3-4 teammates
- Each teammate MUST use isolation: "worktree" for independent copy of repo
- Sequential chaining: researcher → architect → implementer → test-runner → code-reviewer
- NEVER spawn new agent for follow-ups — use SendMessage({to: agentId}) to continue
- Memory agents: architect, implementer, code-reviewer, security-auditor (accumulate learnings)
- Transactional agents: researcher, test-runner (execute and report, no memory)
- Subagent output must not exceed 30% of main context — always structured summaries
- Always verify subagent output (run tests/lint) before declaring task done
