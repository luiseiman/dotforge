---
globs: "**/rules/*.md,**/agents/*.md,**/commands/*.md,**/skills/**/SKILL.md,docs/prompting-patterns.md"
description: "Structural prompt engineering patterns for Claude Code configuration"
domain: claude-code-engineering
last_verified: 2026-10-07
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
- Comments (current, v2.1.316): "Default to writing no comments. Only add one when the WHY is non-obvious…" — the old "DO NOT ADD ANY COMMENTS" absolute is gone, so a blanket "ALWAYS add docstrings" now fights a nuanced directive; override narrowly ("public API functions get a one-line docstring")
- The "fewer than 4 lines" response cap no longer exists (removed before v2.1.316) — drop overrides written against it
- Source of truth for the live text: Piebald-AI/claude-code-system-prompts (`system-prompts/*.md`, per-version CHANGELOG with token deltas) — re-check before writing any counter-rule
- "Use TodoWrite VERY frequently" and "minimize output tokens" — gone from the v2.1.318 extraction (0 matches); the live style block is "Lead with the outcome" + "complete sentences… not arrow chains". Overrides written against the old strings are dead weight; override the live wording narrowly if at all
- Todo tools themselves remain absent on Opus 4.8+, Sonnet 5+, Fable unless `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`

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

Interaction with prompt cache TTL: identical `--system-prompt` between calls within 5 min (default) or 60 min (`ENABLE_PROMPT_CACHING_1H=1`) → cache hits, near-zero marginal cost. Stable sys prompt + variable stdin is the cache-friendly shape. Since v2.1.275 a line containing only `__SYSTEM_PROMPT_DYNAMIC_BOUNDARY__` inside the custom prompt marks the cached/dynamic split explicitly — put the stable instructions above it and per-run context below.

**Snapshot caveat (v2.1.257+)**: the system prompt is recorded on a conversation's first request and reused until compaction, including across `--continue`/`--resume`. Iterating on `--append-system-prompt` text against the same conversation silently keeps the first version — pass `--system-prompt-snapshot off` while tuning, or start a fresh conversation per variant. Bare mode (`--bare` / `CLAUDE_CODE_SIMPLE=1`) records only with `--system-prompt-snapshot on`.

Exit-code contract (v2.1.314–v2.1.318): `claude -p` exits 1 on startup failure and when a full disk or quota loses transcript or `~/.claude.json` writes (previously 0, silently); a non-interactive launch no longer overwrites an invalid `~/.claude.json` — it fails to start. CI wrappers must check the exit code. `-p` JSON results carry `credential_expires_at` (v2.1.318). Unattended retry knobs: `CLAUDE_CODE_RETRY_WATCHDOG` (+ `_MAX_WAIT_MS`, `_MAX_USAGE_LIMIT_WAIT_MS`, `_USAGE_LIMIT_RECHECK_MS`), `CLAUDE_CODE_OVERLOADED_RETRY_BASE_DELAY_MS` / `_MAX_DELAY_MS` (v2.1.295–v2.1.305). Local transcripts record each request's system prompt, tools and parameters since v2.1.300 — CLAUDE.md-derived content lands in any transcript you share.


## Language rules

- All Claude-consumed content (rules, prompts, skills, agents) MUST be in English
- User-facing content (docs, descriptions, changelog) may be in Spanish
