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

### G1. Parallelism as a first-class pattern
**Tip:** "Run 5 Claudes in parallel", "teleport between local and web sessions",
"cowork dispatch", "fork your session", "git worktrees", "/batch to fan out".
**Gap:** dotforge has no guidance on *when* to run parallel sessions vs. a single
sequential session. Our `agents.md` covers *subagents* but not *parallel top-level
Claude instances*. Could be a workflow rule: "for independent bugs/features →
separate sessions in worktrees".
**How to apply:** add a section to `.claude/rules/domain/agent-orchestration.md`
distinguishing parallel top-level sessions from subagent fan-out.

### G2. `/loop` and `/schedule` as workflow primitives
**Tip:** Boris calls these "two of the most powerful features".
**Gap:** dotforge has the `loop` and `schedule` skills but no guidance on *when*
to reach for them. No pattern like "poll long builds with /loop, don't sleep+poll
manually".
**How to apply:** add examples to `.claude/rules/_common.md` or a new
`workflow-automation.md` domain rule.

### G3. Sandboxing ✅ VERIFIED 2026-04-13
**Tip:** "Enable sandboxing" (2026-03-30).
**Gap:** not mentioned anywhere in dotforge. **Verified against code.claude.com/docs/en/settings**: `sandbox.*` is a full block (`enabled`, `failIfUnavailable`, `autoAllowBashIfSandboxed`, `excludedCommands`, `allowUnsandboxedCommands`, `filesystem.*`, `network.*`, `enableWeakerNestedSandbox`, `enableWeakerNetworkIsolation`). macOS/Linux/WSL2 only.
**Incorporated:** `.claude/rules/domain/sandboxing.md` created 2026-04-13; `audit/checklist.md` item 15 added; cross-ref added in `domain/permission-model.md`.

### G4. `/btw` for side queries
**Tip:** keeps main context clean by routing tangents to a side channel.
**Gap:** we don't teach this pattern. Relevant to our context-window-optimization
concerns — avoiding context pollution is literally one of our governance goals.
**How to apply:** mention in `.claude/rules/domain/context-window-optimization.md`.

### G5. `--bare`, `--add-dir`, `--agent` CLI flags
**Tip:** startup flags for faster SDK cold start, multi-dir access, custom
system prompt.
**Gap:** none of these appear in our template or stacks. Worth verifying they
exist (Boris is authoritative) and documenting in `claude-cli-startup-flags`
domain knowledge if we don't have it.

### G6. Mobile app + session handoff
**Tip:** move sessions between mobile/web/desktop/terminal.
**Gap:** not in scope for dotforge (user-level habit, not project config), but
worth noting in docs as "dotforge configs travel with you across clients".

### G7. Chrome extension for frontend work
**Tip:** use the Chrome extension for live browser inspection.
**Gap:** our `react-vite-ts` and `swift-swiftui` stacks don't reference this.
Could be a stack-level note: "for frontend changes, use the Chrome extension
to verify in-browser".

### G8. `/voice` input
Not actionable for dotforge (input method, not config).

## NOT actionable for dotforge

- Terminal customization, keybindings, statusline, spinner verbs, output styles
  → user-level, already covered in our user CLAUDE.md.
- "Run N Claudes in parallel" as a *marketing* tip → covered by G1 more usefully.
- MCP usage generally → we already have `mcp-add` skill.
- Squash merges + small PRs → git hygiene, project-specific.

## Proposed action

1. **Verify first** (before incorporating):
   - `--bare`, `--add-dir`, `--agent`, `/btw`, `/batch`, `/loop`, `/schedule`,
     `/voice`, sandboxing flag — are these real, current, and stable? Boris is
     authoritative but some tips are months old. Run `/forge watch` against
     docs.anthropic.com or fetch the official CLI reference.
2. **Draft** (after verification passes):
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
