---
globs: "**/rules/*.md,**/agents/*.md,**/commands/*.md,**/skills/**/SKILL.md,docs/prompting-patterns.md"
description: "Structural prompt engineering patterns for Claude Code configuration"
domain: claude-code-engineering
last_verified: 2026-03-25
---

# Prompting Patterns

- Base formula: ROLE → CONTEXT → TASK → CONSTRAINTS → OUTPUT FORMAT → EXAMPLE
- Ultrathink for complex decisions: ANALYZE → EXPLORE 3+ approaches → EVALUATE tradeoffs → DECIDE with why → IMPLEMENT
- Negative constraints ("NEVER do X") are more effective than positive suggestions ("consider doing Y")
- Few-shot: provide 1-2 examples of expected output before requesting results
- One instruction per line, imperative mood, no "please", no "you should consider"
- High information density — if it can be said in fewer words without losing meaning, rewrite shorter
- Critical self-review: ask Claude to find errors/edge cases in its own response before finalizing
- All Claude-consumed content (rules, prompts, skills, agents) MUST be in English
- User-facing content (docs, descriptions, changelog) may be in Spanish
- Forced chain-of-thought: require explicit step completion before answering
