---
id: practice-2026-08-07-subagent-frontmatter-hooks-workspace-trust
title: Subagent frontmatter hooks require workspace trust (v2.1.218+)
source: "/forge watch — Claude Code upstream docs"
source_type: upstream-doc
discovered: 2026-08-07
status: active
tags: [subagents, hooks, security, workspace-trust, breaking-change]
tested_in: []
incorporated_in: [".claude/rules/domain/agent-orchestration.md,.claude/rules/domain/permission-model.md"]
replaced_by: null
---

## Description
Since v2.1.218, project-level subagent frontmatter `hooks:` blocks require workspace trust acceptance BEFORE they run. Non-interactive sessions (`-p`, SDK, CI) no longer execute untrusted frontmatter hooks — the subagent still runs, but its hooks are skipped and an error is logged to the debug log.

Trust scope:
- `.claude/agents/*.md` in a project → workspace-trust gate applies
- Directories added via `--add-dir` from outside the trusted workspace → separate trust required (does not inherit workspace's grant)
- User-level agents in `~/.claude/agents/` → no trust required (files you wrote yourself)
- `--agents` CLI JSON → no trust required (explicit caller input)

This is a hardening: pre-v2.1.218 frontmatter hooks could run from folders you hadn't trusted, including in non-interactive sessions. That was the injection surface a hostile PR could exploit — check out a repo with a malicious `agents/reviewer.md` frontmatter hook and have it fire on your next Claude session.

## Evidence
Fetched from https://code.claude.com/docs/en/sub-agents#hooks-in-subagent-frontmatter (2026-08-07):
> "To let a project-level subagent's frontmatter hooks run, accept the workspace trust dialog for the folder that contains the agent file [...] Until you trust the folder, the subagent still runs, but Claude Code skips its frontmatter hooks and logs an error to the debug log [...] Before v2.1.218, frontmatter hooks could run from folders you hadn't trusted, including in non-interactive sessions."

## Impact on dotforge
- Update `agents/*.md` — any agent shipped with frontmatter hooks needs a docstring note that first-run in a fresh checkout requires workspace trust
- Update `domain/agent-orchestration.md` — document the trust gate in the hooks section (currently mentions frontmatter hooks without mentioning trust requirement)
- Update `domain/permission-model.md` — link workspace-trust dialog to subagent hook execution (previously covered only project settings + top-level hooks)
- CI implication: any pipeline using `claude -p` with project-level agent frontmatter hooks will silently skip them. Document `~/.claude/agents/` migration or `--agents` inline JSON as alternatives for CI usage

## Decision
Pending
