---
globs: "**/rules/*.md,**/agents/*.md,**/commands/*.md,**/skills/**/SKILL.md,docs/prompting-patterns.md"
description: "Structural prompt engineering patterns for Claude Code configuration"
domain: claude-code-engineering
last_verified: 2026-10-06
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
- "Use TodoWrite VERY frequently" → only on models that still ship todo tools (≤ Opus 4.7 / Sonnet 4.6 / Haiku 4.5); absent on Opus 4.8+, Sonnet 5+, Fable unless `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`
- "minimize output tokens" → use "thorough analysis required, do not abbreviate"

## Headless invocation cost profile (v2.1.154+)

`claude -p` invocations from scripts/CI carry a hidden baseline cost — auto-discovery loads CLAUDE.md, skills, and MCP servers into the system prompt. Measured baseline pre-optimization: **~117k tokens cache_creation per cold call (~$0.15)** even for a one-line response. v2.1.154 ships a **lean system prompt default** for Opus 4.8 / Sonnet 4.6 / Haiku 4.5 (Opus 4.7 still loads full) which drops the floor materially.

Manual lean-invocation pattern (works across all models, complements the v2.1.154 default):

```bash
cd /tmp && claude -p "$user_prompt" \
  --system-prompt "$your_minimal_sys_prompt" \
  --disable-slash-commands \
  --strict-mcp-config \
  --permission-mode bypassPermissions
```

Measured (vps-control watchdog, 2026-05-31, Opus 4.7 — pre-lean-default era):
- Default: 117k tokens cache_creation, ~$0.15/call, 6s
- With lean params: 31k cache_creation, ~$0.04/call cold, 4s
- Second call inside 5-min cache window: 0 cache_creation, ~$0.004/call
- **12-37x cost reduction on identical workload**

Interaction with prompt cache TTL: identical `--system-prompt` between calls within 5 min (default) or 60 min (`ENABLE_PROMPT_CACHING_1H=1`) → cache hits, near-zero marginal cost. Stable sys prompt + variable stdin is the cache-friendly shape.

## Language rules

- All Claude-consumed content (rules, prompts, skills, agents) MUST be in English
- User-facing content (docs, descriptions, changelog) may be in Spanish
