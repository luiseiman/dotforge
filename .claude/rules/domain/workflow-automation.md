---
globs: "**/CLAUDE.md,**/skills/loop/**,**/skills/schedule/**,**/rules/_common.md"
description: "When to reach for /goal, /loop, /schedule, /batch, /workflows — temporal and orchestration primitives"
domain: claude-code-engineering
last_verified: 2026-10-06
---

# Workflow Automation Primitives

Five primitives cover temporal and multi-agent orchestration: `/goal` (condition-driven persistence), `/loop` (polling), `/schedule` (cron triggers), `/batch` (fan-out over independent files), `/workflows` (dynamic multi-agent orchestration, v2.1.154+). Pick by the problem shape, not by familiarity.

## `/goal` — condition-driven persistence (v2.1.139+)

- `/goal <completion-condition>`: Claude keeps working across turns until the condition is met. Works in interactive, `-p` print mode, and Remote Control. Live overlay shows elapsed/turns/tokens
- Use for: open-ended tasks with a clear "done" signal (`all tests in <file> pass and the change is committed`, `the deploy reports HEALTHY for 60s`, `PR #N is approved and CI green`)
- Stop condition is judged by the model; phrase it concretely so the judgment is reliable
- Alternative to `/loop` when the stop condition is well-defined — `/goal` is condition-driven (semantic), `/loop` is cadence-driven (temporal)
- Fails closed when `disableAllHooks` or `allowManagedHooksOnly` is set (v2.1.140 — shows clear message instead of silent hang)

## `/loop` — time-bounded polling

- Use for: watching a long-running build, waiting for a PR check to finish, polling an external service with a known-short settling time, iterating on a prompt until a condition holds
- Default cadence heuristic: sleep <5min stays in prompt cache; 5–60min pays one cache miss; 20–30min is the sweet spot for idle polls. See `ScheduleWakeup` docs for the full rationale. With `ENABLE_PROMPT_CACHING_1H=1` (v2.1.108+) the 5-min boundary extends to 60min — see `context-window-optimization.md`
- Never use `sleep N` in Bash as a polling mechanism — it burns a tool call, freezes Claude, and wastes context. `/loop` or `ScheduleWakeup` instead
- Stop condition MUST be explicit in the loop prompt — otherwise `/loop` runs forever

## `/schedule` — recurring work

- Use for: nightly reports, weekly audits, periodic scans, scheduled maintenance, dead-man's-switch monitors
- Cron-based, survives session end. Edit/list/delete via the skill
- NOT for polling-until-done (that's `/loop`) — scheduled triggers fire regardless of state
- Keep the scheduled prompt self-contained — no assumed session context, no references to prior conversation turns

## `/batch` — fan-out across many independent changes

- Use for: renaming a symbol across 50 files, migrating 30 components between frameworks, applying the same refactor to every file matching a pattern
- Each change must be independent (no shared mutable state, no order dependency)
- When blast radius is wide, stage into a branch first — batch failures are harder to unwind than sequential
- If changes are <10, sequential is usually faster than `/batch` setup overhead

## `/workflows` — dynamic multi-agent orchestration (v2.1.154+)

JavaScript script that Claude writes for the task you describe; a runtime executes it in the background while your session stays responsive. Use when one conversation can't coordinate the work, or when you want orchestration codified as a script you can read/rerun.

- Use for: codebase-wide bug sweep, 500-file migration, multi-source research with cross-check, multi-angle plan drafting
- Distinct from Agent Teams (handcrafted ≤4 teammates, declared upfront): `/workflows` is dynamic — shape decided at runtime, scales to tens-to-hundreds of agents
- Availability: v2.1.154+ on all paid plans, Anthropic API, Bedrock, Vertex, Foundry
- Inspect runs: `/workflows`, arrow-keys to select, Enter to open progress view

### Declarative meta block (required prefix)

```javascript
export const meta = {
  name: 'find-flaky-tests',
  description: 'Find flaky tests and propose fixes',  // shown in permission dialog
  phases: [                                            // one entry per phase() call
    { title: 'Scan', detail: 'grep CI logs for retries' },
    { title: 'Fix', detail: 'one agent per flaky test' },
  ],
}
// script body starts here
```

`meta` must be a PURE LITERAL — no variables, function calls, spreads, or template interpolation. Required: `name`, `description`. Optional: `whenToUse`, `phases`, `model`.

### Core primitives

- `agent(prompt, opts?)` — spawn subagent. Returns final text (string) or validated object (when `opts.schema` set). Returns `null` if user skips mid-run → `.filter(Boolean)`. Opts: `label`, `phase`, `schema`, `model`, `isolation: 'worktree'`, `agentType`
- `parallel(thunks)` — barrier: awaits all thunks. Throws/errors resolve to `null` (call never rejects). Use ONLY when stage N genuinely needs cross-item context from all of stage N-1
- `pipeline(items, ...stages)` — DEFAULT for multi-stage. No barrier between stages. Item A can be in stage 3 while item B is still in stage 1. Wall-clock = slowest single-item chain. A throwing stage drops that item to `null`
- `phase(title)` — start progress group; subsequent `agent()` calls land under this title
- `log(message)` — narrator line above progress tree
- `workflow(name|{scriptPath}, args?)` — run another workflow inline (1 level deep)

### Schema validation

`opts.schema` forces a StructuredOutput tool call; validation happens at the tool layer so the model retries on mismatch. Returns the validated object directly — no JSON.parse needed.

### Concurrency + budget

- Per-workflow concurrent cap: `min(16, cpu cores - 2)` — excess `parallel()`/`pipeline()` items queue and run as slots free
- Lifetime cap: 1000 agents per workflow (runaway backstop)
- `budget.total` (null if not set), `budget.spent()`, `budget.remaining()` — pool is shared across main loop + all workflows in the turn. Once `spent() >= total`, `agent()` throws

```javascript
while (budget.total && budget.remaining() > 50_000) {  // guard on .total — else remaining() is Infinity
  const result = await agent("Find more bugs", {schema: BUGS_SCHEMA})
  bugs.push(...result.bugs)
}
```

### Resume

`Workflow({scriptPath, resumeFromRunId})` — cached `(prompt, opts)` agent calls return instantly; first edited/new call runs live. Same script + same args → 100% cache hit. `Date.now()`, `Math.random()`, argless `new Date()` are unavailable in scripts (would break resume) — pass timestamps via `args`, stamp at the end.

### Pipeline vs parallel decision

Default to **pipeline**. Use parallel barrier ONLY when:
- Dedup/merge across full result set before expensive downstream work
- Early-exit if total count is zero
- Stage N prompt references "the other findings" for comparison

NOT a barrier justification: "I need to flatten/filter first" → do it inside a pipeline stage.

### Quality patterns

Compose for thoroughness: adversarial verify (N skeptics try to refute; ≥majority refute → kill), perspective-diverse verify (correctness/security/perf lenses instead of N identical refuters), judge panel (independent attempts scored by parallel judges), loop-until-dry (K consecutive empty rounds = done), multi-modal sweep (each agent searches a different way), completeness critic (final "what's missing?" agent).

### Permission model (security boundary)

Workflow subagents **always run in `acceptEdits` mode regardless of the parent session's permission mode** (including `plan`). File edits are auto-approved. The session's permission mode controls ONLY the per-run launch prompt — once a workflow starts, every subagent it spawns edits files without prompting.

| Session mode | Launch prompt | Subagent edits mid-run |
|--------------|---------------|------------------------|
| `default`, `acceptEdits` | every run (or remembered per-workflow consent) | auto-approved |
| `auto` | first launch only; consent stored. **Skipped entirely when ultracode is on** | auto-approved |
| `bypassPermissions`, `claude -p`, Agent SDK | never | auto-approved |
| `plan` | every run | **auto-approved — plan mode does NOT gate workflow subagents** |

Shell commands, web fetches, and MCP tools that aren't in the allowlist can still prompt mid-run; file edits cannot. `permissions.deny` (kernel-level + permission-cascade) still applies — for production projects, ensure `deny` covers sensitive paths (e.g. `migrations/`, `infrastructure/`, secrets).

### Bundled workflows (v2.1.154+)

Claude Code ships built-in workflows that appear in `/` autocomplete:

| Command | What it does |
|---------|--------------|
| `/deep-research <question>` | Fans out web searches across angles, fetches and cross-checks sources, votes on each claim, returns a cited report with claims that didn't survive cross-checking filtered out. Requires WebSearch tool. |

Workflows saved via `/workflows` → `s` shortcut become commands the same way and appear alongside the bundled ones. Save to `.claude/workflows/` (project, shared) or `~/.claude/workflows/` (personal). Project workflows shadow personal ones at the same name.

### Settings

- `disableWorkflows: true` — kill switch (equivalent to `CLAUDE_CODE_DISABLE_WORKFLOWS=1`)
- `workflowKeywordTriggerEnabled` (v2.1.157, default `true`) — controls whether the literal trigger keyword in prompt triggers expansion. **Keyword renamed v2.1.160**: pre-v2.1.160 = `workflow`, v2.1.160+ = `ultracode`. The setting key is unchanged — only the matched word. Natural-language requests ("use a workflow", "run a workflow") still trigger expansion in both versions. UI label in `/config` changed to "Ultracode keyword trigger".
- Dismiss the highlighted keyword in-prompt: `Option+W` macOS / `Alt+W` Windows-Linux (or backspace while cursor is just after it)
- **Anti-confusion** for dotforge ultracode-as-tier policy: when documenting "this project is ultracode tier", prefer `ultracode-tier`, `ultracode posture`, or `ultracode mode` over the bare word `ultracode` to avoid triggering accidental workflow expansion

### Runtime activation: `/effort ultracode on|off`

Ultracode is an **independent toggle since v2.1.284**: `/effort` → Tab, or `/effort ultracode on|off`. It no longer forces `xhigh` and stays on at any effort level. The CLI flag `--effort ultracode` (v2.1.203+) still requests `xhigh` + ultracode together. Session-only, resets on new session. Pre-v2.1.284 the two were coupled (ultracode = xhigh + orchestration, Opus-only).

With it on, Claude plans a workflow for each substantive request — one user prompt can spawn several workflows in sequence (understand → change → verify). Launch prompts in `auto` mode are also skipped. The 20-concurrent-subagent cap is lifted while ultracode is on.

Pairs with dotforge `workflow-and-ultracode-policy.md` tier mapping: `production` → `/effort xhigh` + `/effort ultracode on` mandatory · `heavy` → ultracode on for architecture/security tasks · `standard` → `/effort high` (default), ultracode off · `light` → `/effort medium|high`, off.

Workflow settings: `workflowSizeGuideline` (default `"medium"`, keeps workflows under ~15 agents; v2.1.219), `CLAUDE_CODE_WORKFLOW_MAX_CONCURRENT_AGENTS` (1–256), `CLAUDE_CODE_WORKFLOW_PREFIX_STAGGER_MS`. The Workflow tool description was cut to ~1K tokens in v2.1.248 — the script reference now lives in the bundled `workflow-authoring` skill. A workflow `import()` sandbox escape was fixed in v2.1.223.

### dotforge integration considerations

- Workflows ARE distributable via plugins (`.claude/skills/<name>/` or marketplace) — but currently dotforge has no `/forge workflow` wrapper. Candidate: register saved workflow scripts under `workflows/<name>.js` in dotforge with a `/forge workflow <name>` dispatcher
- Agent Teams (handcrafted ≤4) remain the right tool for known small fan-out; `/workflows` for unknown-shape or large scale

## Routines vs `/schedule` vs Desktop scheduled tasks

Three distinct cron-like primitives — don't confuse them:

- **Routines** (Anthropic-managed cloud): survives machine off; triggers on cron, API calls, or GitHub events. Use for unattended reports, overnight audits, dead-man switches that must run regardless of local state. Create via web/Desktop app or `/schedule` in the CLI.
- **Desktop scheduled tasks** (local machine): full file/tool access. Use when local state matters (reading local dev files, hitting `localhost`).
- **`/schedule`** (dotforge skill): session-bound local cron. Use for per-project recurring work during active development.

## Anti-patterns

- `sleep 300 && check-again` in Bash → use `/loop` with 270s cadence to stay in cache
- Hand-coded cron in a SessionStart hook → use `/schedule`
- Looping over files with Edit tool calls for a mechanical rename → use `/batch`
- `/loop` without a stop condition → will run until the session dies or the loop burns the context
- `/batch` for fan-out where teammates need to coordinate or share state → use `/workflows`
- Spawning 20+ subagents from a Lead agent — exceeds Agent Teams' "max 3-4 teammates" guidance → use `/workflows`
