---
globs: "**/*"
---

# GitHub MCP Rules

## Scope
Use GitHub MCP for: reading issues/PRs/code, creating issues, adding review comments.
Do not use as a substitute for local git operations when working in this repo.

## Read operations
Read freely without confirmation: get_file_contents, list_issues, get_issue,
list_pull_requests, get_pull_request, search_code, list_commits, list_branches.

## Write operations — state intent before calling
Before any write operation, show what you are about to do and why:
- `create_issue`: state the title and key content
- `add_issue_comment`: quote the comment before posting
- `create_pull_request`: state target branch, summary of changes, and linked issue
- `update_issue`: show current state and proposed change
- `push_files`: list every file and the nature of the change

## Hard stops (enforced by deny list)
- `merge_pull_request` — use the GitHub UI or `gh pr merge`. Never merge programmatically.
- `delete_branch` — only after confirming the PR is merged AND user explicitly requests it.
- `delete_file` — treat as destructive. Requires explicit user instruction.

## Branching pattern
When implementing a GitHub issue:
1. Read the full issue first
2. Work locally on a feature branch
3. Create PR only when implementation is complete and tests pass
4. Never auto-merge — leave that decision to the user

## Repo targeting
Always confirm which repo you are operating on before write operations.
When context is ambiguous, ask: "Which repo: <current-repo> or another?"
