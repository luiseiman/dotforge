---
globs: "**/rules/*.md,**/agents/*.md,**/commands/*.md,**/skills/**/SKILL.md,docs/prompting-patterns.md"
description: "Structural prompt engineering patterns for Claude Code configuration"
domain: claude-code-engineering
last_verified: 2026-04-02
---

# Prompting Patterns

## Structure

- Base formula: ROLE → CONTEXT → TASK → CONSTRAINTS → OUTPUT FORMAT → EXAMPLE
- Ultrathink for complex decisions: ANALYZE → EXPLORE 3+ approaches → EVALUATE tradeoffs → DECIDE with why → IMPLEMENT
- Negative constraints ("NEVER do X") more effective than positive suggestions ("consider doing Y")
- Few-shot: provide 1-2 examples of expected output before requesting results
- One instruction per line, imperative mood, no "please", no "you should consider"
- High information density — rewrite shorter if meaning preserved
- Critical self-review: ask Claude to find errors/edge cases before finalizing
- Forced chain-of-thought: require explicit step completion before answering

## System prompt internals to account for

- System prompt has cacheable (static) and dynamic (per-turn) regions split by SYSTEM_PROMPT_DYNAMIC_BOUNDARY
- Rules and CLAUDE.md land in dynamic region (NOT cached by Anthropic prompt caching)
- File security warning injected after EVERY Read tool call — adds token cost per read
- `isMeta: true` messages (system-reminders) get special treatment during compression — may be stripped

## Overriding hardcoded defaults

These system prompt instructions require STRONG override language in rules:
- "DO NOT ADD ANY COMMENTS" → use "ALWAYS add docstrings to public functions"
- "fewer than 4 lines" → use "provide detailed explanations with examples"
- "Use TodoWrite VERY frequently" → difficult to suppress
- "minimize output tokens" → use "thorough analysis required, do not abbreviate"

## Language rules

- All Claude-consumed content (rules, prompts, skills, agents) MUST be in English
- User-facing content (docs, descriptions, changelog) may be in Spanish
