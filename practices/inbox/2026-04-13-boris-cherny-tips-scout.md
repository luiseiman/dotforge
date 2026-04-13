---
id: boris-cherny-tips-scout
source: scout:shanraisshan/claude-code-best-practice/tips
status: inbox
captured: 2026-04-13
tags: [scout, boris-cherny, workflow, gaps]
tested_in: []
incorporated_in: []
---

# Boris Cherny tips — scout digest

## Source

Six posts from Boris Cherny (creator of Claude Code) scraped from
`shanraisshan/claude-code-best-practice/tips/`, spanning 2026-01-03 → 2026-03-30.
Total: 54 tips across 6 posts.

## Already covered in dotforge (no action needed)

- Plan mode for complex tasks → `.claude/rules/_common.md` planning rule
- CLAUDE.md investment → template + domain-learning rule
- Subagents for common workflows → `agents/` + `agents.md` orchestration
- PostToolUse auto-format hook → `lint-on-save.sh` in template
- Pre-allow permissions (not `--dangerously-skip`) → template `allow:` list
- Custom skills committed to git → `skills/` + global sync
- Hooks for deterministic logic → `hooks/` in template
- Opus with thinking for hard tasks → `model-routing.md`
- Verify work (tests/lint) → `CLAUDE.md` "never report done without tests"

## Gaps revealed — candidates for dotforge

### G1. Parallelism as a first-class pattern ✅ VERIFIED + INCORPORATED 2026-04-13
**Tip:** "Run 5 Claudes in parallel", "teleport between local and web sessions",
"cowork dispatch", "fork your session", "git worktrees", "/batch to fan out".
**Gap:** dotforge has no guidance on *when* to run parallel sessions vs. a single
sequential session. Our `agents.md` covers *subagents* but not *parallel top-level
Claude instances*.
**Incorporated:** new `.claude/rules/domain/parallel-sessions.md` (39 lines) covering worktree isolation, session handoff, fast-start flags. Cross-ref added from `domain/agent-orchestration.md`.

### G2. `/loop` and `/schedule` as workflow primitives ✅ VERIFIED + INCORPORATED 2026-04-13
**Tip:** Boris calls these "two of the most powerful features".
**Verified:** `/loop` and `/batch` confirmed as bundled skills in `code.claude.com/docs/en/skills`. `/schedule` not explicitly in bundled list — may be plugin-only, but our local skill works.
**Incorporated:** new `.claude/rules/domain/workflow-automation.md` (38 lines) with decision patterns for `/loop` / `/schedule` / `/batch`, cache-aware cadence heuristics, and anti-patterns (no hand-rolled `sleep N`, no stop-less loops).

### G3. Sandboxing ✅ VERIFIED 2026-04-13
**Tip:** "Enable sandboxing" (2026-03-30).
**Gap:** not mentioned anywhere in dotforge. **Verified against code.claude.com/docs/en/settings**: `sandbox.*` is a full block (`enabled`, `failIfUnavailable`, `autoAllowBashIfSandboxed`, `excludedCommands`, `allowUnsandboxedCommands`, `filesystem.*`, `network.*`, `enableWeakerNestedSandbox`, `enableWeakerNetworkIsolation`). macOS/Linux/WSL2 only.
**Incorporated:** `.claude/rules/domain/sandboxing.md` created 2026-04-13; `audit/checklist.md` item 15 added; cross-ref added in `domain/permission-model.md`.

### G4. `/btw` for side queries ✅ VERIFIED + INCORPORATED 2026-04-13
**Tip:** keeps main context clean by routing tangents to a side channel.
**Gap:** we don't teach this pattern. Relevant to our context-window-optimization
concerns — avoiding context pollution is literally one of our governance goals.
**Verified details:** ephemeral (no conversation history), no tool access (answers from existing context only), single-turn, reuses parent prompt cache (near-zero cost), available while Claude is working. Dismissible overlay via Space/Enter/Esc. Explicitly "the inverse of a subagent".
**Incorporated:** context-window-optimization.md split into two files. Runtime details stay in `context-window-optimization.md` (44 lines). User-facing patterns moved to new `domain/context-control-patterns.md` (40 lines) with sections on `/btw`, skill budget after compaction, manual pruning (`Esc+Esc`, `/compact`, `Ctrl+X Ctrl+K`), and pollution avoidance.

### G5. `--bare`, `--add-dir`, `--agent` CLI flags ✅ VERIFIED + INCORPORATED 2026-04-13
**Tip:** startup flags for faster SDK cold start, multi-dir access, custom
system prompt.
**Verified:** all three real, plus discovered `--agents` (plural, inline JSON) and `--setting-sources`. Also: `--add-dir` grants file access but NOT `.claude/` discovery — except `.claude/skills/` which IS loaded live. Important gotcha.
**Incorporated:** covered in `domain/parallel-sessions.md` § Fast-start flags.

### G6. Mobile app + session handoff
**Tip:** move sessions between mobile/web/desktop/terminal.
**Gap:** not in scope for dotforge (user-level habit, not project config), but
worth noting in docs as "dotforge configs travel with you across clients".

### G7. Chrome extension for frontend work
**Tip:** use the Chrome extension for live browser inspection.
**Gap:** our `react-vite-ts` and `swift-swiftui` stacks don't reference this.
Could be a stack-level note: "for frontend changes, use the Chrome extension
to verify in-browser".

### G8. `/voice` input — ❌ NOT A SLASH COMMAND
**Correction (verified 2026-04-13):** voice input is push-to-talk via `Hold Space`, not a `/voice` command. The digest was wrong. Requires `voice-dictation` enabled. Rebindable. No dotforge action needed — it's a keyboard shortcut, not a config surface.

## NOT actionable for dotforge

- Terminal customization, keybindings, statusline, spinner verbs, output styles
  → user-level, already covered in our user CLAUDE.md.
- "Run N Claudes in parallel" as a *marketing* tip → covered by G1 more usefully.
- MCP usage generally → we already have `mcp-add` skill.
- Squash merges + small PRs → git hygiene, project-specific.

## Verification results (2026-04-13)

Fetched against `code.claude.com/docs/en/cli-reference`, `settings`,
`interactive-mode`, and `skills`:

| Item | Status | Notes |
|---|---|---|
| `--bare` | ✅ real | Skips auto-discovery, sets `CLAUDE_CODE_SIMPLE` |
| `--add-dir` | ✅ real | Grants file access, NOT `.claude/` discovery (except `.claude/skills/`) |
| `--agent` | ✅ real | Overrides `agent` setting |
| `--agents` (plural) | ✅ real | **Bonus finding** — inline JSON subagent definition |
| `--worktree` / `-w` | ✅ real | Creates isolated worktree at `.claude/worktrees/` |
| `--fork-session` | ✅ real | Use with `--resume`/`-c` |
| `--teleport` | ✅ real | Resume web session locally |
| `--remote` | ✅ real | Launch new claude.ai/code session |
| `--chrome` | ✅ real | G7 confirmed |
| `--effort` | ✅ real | `low/medium/high/max` (max Opus 4.6 only) |
| `sandbox.*` | ✅ real | Full settings.json block — handled in a separate capture |
| `/btw` | ✅ real | Side questions — ephemeral, no tool access, reuses parent cache. "Inverse of a subagent" (has conversation context, no tools) |
| `/batch` | ✅ real | Bundled skill alongside `/simplify`, `/debug`, `/loop`, `/claude-api` |
| `/loop` | ✅ real | Bundled skill (we already have locally) |
| `/schedule` | ⚠️ not in bundled skills list | May be plugin-only. Our local `schedule` skill works but isn't a first-party bundled skill |
| `/voice` | ❌ NOT a slash command | Voice input is **push-to-talk via `Hold Space`**, not a command. Digest misattributed. Skip entirely |

**Other findings from the same docs, unrelated to Boris tips but dotforge-relevant:**

- `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` — env var to disable all background bash tasks. Consider in `domain/auto-mode.md` or a new domain rule.
- `CLAUDE_CODE_TASK_LIST_ID` — share task list across sessions via `~/.claude/tasks/<id>/`. Relevant to our session continuity rules.
- `Ctrl+X Ctrl+K` — kill all background agents (double-tap). Not a dotforge config concern but worth knowing.
- `Esc+Esc` — rewind conversation / summarize from a selected message. Relevant to our context optimization rules.
- `SLASH_COMMAND_TOOL_CHAR_BUDGET` — env var to raise skill description char budget (default = 1% of context window, fallback 8K). Important for projects with many skills. Add to `domain/rule-effectiveness.md`.
- Skills re-attached after compaction: most recent invocation keeps first 5K tokens, combined budget 25K across all skills. Add to `domain/context-window-optimization.md`.
- `/btw` cost model: reuses parent conversation's prompt cache → near-zero marginal cost. Pattern to teach explicitly in `domain/context-window-optimization.md`.

## Proposed action

1. **Draft** (verification complete):
   - G1 → extend `domain/agent-orchestration.md` with parallel-session guidance.
   - G2 → new `domain/workflow-automation.md` with `/loop`, `/schedule`, `/batch`
     patterns.
   - G3 → audit sandboxing, add to `domain/permission-model.md` if it exists.
   - G4 → one paragraph in `domain/context-window-optimization.md`.
   - G5 → confirm and expand `domain/` CLI flags coverage if missing.
   - G7 → frontend stack notes.
3. **Skip** G6, G8, and user-level tips.

## Source files

- `tips/claude-boris-13-tips-03-jan-26.md`
- `tips/claude-boris-10-tips-01-feb-26.md`
- `tips/claude-boris-12-tips-12-feb-26.md`
- `tips/claude-boris-2-tips-10-mar-26.md`
- `tips/claude-boris-2-tips-25-mar-26.md`
- `tips/claude-boris-15-tips-30-mar-26.md`
