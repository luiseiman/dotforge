---
globs: "**/*"
---

# Model Routing Rules

Use these criteria to select the appropriate Claude model for each task.
Apply to direct work and when instantiating subagents.

## haiku — speed over depth

Use when:
- Searching files, grepping, listing, reading for orientation
- Running commands and reporting results (test runs, lint, build)
- Repetitive transformations: rename, reformat, migrate syntax across files
- Short factual questions with deterministic answers
- Fetching and summarizing external content (docs, URLs)

Default agents: `researcher`, `test-runner`

## sonnet — standard implementation

Use when:
- Implementing a feature with a clear, well-scoped spec
- Fixing a bug where the root cause is already identified
- Code review of focused PRs (< 500 lines, single concern)
- Debugging with sufficient context already available
- Writing or updating documentation
- Routine refactoring within a single module

Default agents: `implementer`, `code-reviewer`, `session-reviewer`

## opus — depth where it matters

Use when:
- Designing architecture across 3+ components with real trade-offs
- Security audits where missing a vulnerability has production consequences
- Tasks where the right approach is genuinely unclear (ambiguous requirements)
- Refactoring that touches core abstractions shared across the codebase
- Reviewing high-risk operations: migrations, auth changes, payment flows
- Any task where a wrong answer causes > 2h of rework

Default agents: `architect`, `security-auditor`

## Escalation rule

Start with sonnet. Escalate to opus if:
- You reach a decision point with 2+ valid approaches and real consequences for choosing wrong
- The task touches security, data integrity, or production systems
- After 2 attempts at sonnet the approach is still unclear

Downgrade to haiku if the task reduces to pure information retrieval with no reasoning required.

## MCP server operations

| Operation type | Model |
|---------------|-------|
| Read (SELECT, list, get) | haiku |
| Write with known intent (INSERT, create issue) | sonnet |
| Migration, schema change, production operation | opus |
| Security review of MCP tool output | opus |
