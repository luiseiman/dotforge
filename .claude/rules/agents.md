---
globs: "**/*"
description: "Multi-agent orchestration rules — always loaded"
---

# Agent Orchestration Protocol

## Delegation Decision Tree

Before starting any task, evaluate:

1. **Single-file fix / quick question** → handle directly, no subagent
2. **Research-heavy or verbose output** → delegate to `researcher`
3. **Code changes + tests needed** → delegate to `implementer`
4. **Security/vulnerability concern** → delegate to `security-auditor`
5. **Multi-component refactor (>3 files, >2 concerns)** → evaluate Agent Teams
6. **Code review before merge** → delegate to `code-reviewer` subagent (structured chain-of-review during the change) OR invoke the built-in `/code-review` slash command (v2.1.147+ ad-hoc end-of-PR pass, runs as a background subagent since v2.1.214; `/review` is an alias since v2.1.223; `--comment` posts inline comments on GitHub PRs and GitLab MRs, `--fix` applies findings, `--max-findings <n>|all` bounds output, v2.1.274; medium effort also reports cleanup + CLAUDE.md-convention findings, v2.1.290). The two are independent — subagent is for in-flight review with memory, slash command is for one-shot review-and-comment
7. **Architecture decision or tradeoff analysis** → delegate to `architect`
8. **Session analysis / pattern detection / /forge insights** → delegate to `session-reviewer`

## Subagent Invocation Rules

- Use `Agent(subagent_type="<name>", ...)` to spawn new subagents
- To continue a subagent's work, use `SendMessage({to: agentId})` — NEVER spawn a new agent for follow-up. A subagent stopped by `maxTurns` returns partial output with the same hint: resume it
- `SendMessage` also reaches OTHER Claude Code sessions on this machine by name (v2.1.224+, `ListAgents` discovers them). That is cross-session messaging, not subagent continuation — see `domain/parallel-sessions.md` § Cross-session messaging before using it
- Pass minimal, focused context — don't dump the full conversation
- Each subagent must return a structured summary, not raw output
- Chain subagents sequentially: researcher → architect → implementer → test-runner → code-reviewer
- If a subagent result is unclear or incomplete, resume it via SendMessage — don't restart

## Agent Teams Escalation Criteria

Spawn an Agent Team ONLY when ALL of these hold:
- Task touches ≥3 independent components/files
- Components don't share mutable state during the task
- Estimated single-agent time >15 min
- Each teammate can own a distinct file set (no overlap)

Team structure pattern:
- **Lead**: coordinates, synthesizes, DOES NOT implement
- **Teammates**: max 3-4 (diminishing returns beyond that)
- Each teammate MUST use `isolation: "worktree"` to work on an isolated copy of the repo
- Lead agent coordinates merges from worktree branches into the main branch
- Require plan approval before any teammate writes code
- **v2.1.149 scope fix**: pre-v2.1.149 worktree teammates had sandbox-blessed write access to the entire main repo (bug). Post-fix, writes are correctly limited to the worktree itself + shared `.git` subset. Agent Teams patterns that relied on teammates editing main-repo files directly were exploiting the bug — rework so teammates merge upstream via branches, not direct writes. See `domain/sandboxing.md`

## Context & Error Handling

- Subagent raw output must not exceed 30% of main context — always structured summaries
- After compaction, re-summarize active agent results if still relevant
- If a subagent fails → log to `CLAUDE_ERRORS.md`, don't retry blindly
- Always verify subagent output (run tests/lint) before declaring done
