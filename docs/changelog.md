# Changelog — dotforge

> Version history. Entries use mixed Spanish/English as the project evolved. Technical terms are universal.
>
> Historial de versiones. Las entradas usan español/inglés mixto según la evolución del proyecto. Los términos técnicos son universales.

## v4.4.0 (2026-10-06)

### Upstream sync — Claude Code v2.1.219 → v2.1.291, breaking batch (7 of 25 practices)

`/forge watch` after a 3-month gap: 73 upstream releases. 25 practices captured; this release incorporates the 7 classified BREAKING (dotforge contradicted or depended on the old behavior). The remaining 18 stay in `practices/evaluating/` for v4.5.0.

#### BREAKING (upstream) — templates and audit engines

- **Auto mode is the session default when `permissions.defaultMode` is unset (v2.1.284)**, and project/local scope can no longer set `auto`/`bypassPermissions` (v2.1.257). `global/settings.json.tmpl` now pins `"defaultMode": "default"` at user scope so synced projects keep prompt-for-unknowns; opt into auto per session with `--permission-mode auto`. Audit item 8 reworked in `audit/checklist.md`, `audit/score.sh`, `scripts/audit_all.py`, `skills/audit-project/SKILL.md`: a missing `defaultMode` is now scored as auto mode active (deny list must cover secrets); missing `settings.json` scores 0. `domain/auto-mode.md` header rewritten (server-side classifier default + `CLAUDE_CODE_AUTO_MODE_SERVER=0`, 10-denial stop, third-party opt-in removed); `domain/permission-model.md` gains the scope-restriction note.
- **Default models: Opus 5.5 `claude-opus-5-5` (v2.1.280), Sonnet 5.5 `claude-sonnet-5-5` (v2.1.284), Fable 5.1 `claude-fable-5-1` (v2.1.257)**, 1M context on every provider. `domain/model-ids.md` table + pricing + fast mode (Opus 4.7 dropped, Opus 5.x $10/$50) + `ANTHROPIC_DEFAULT_MODEL` / `modelPicker` / `CLAUDE_CODE_SUBAGENT_MODEL_FORCE`; `domain/context-window-optimization.md` table (Sonnet 5+ compacts ~967K); `domain/compaction-strategy.md` thresholds.
- **Todo/Task tools removed on Opus 4.8+, Sonnet 5+, Fable (v2.1.233/268)** — `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` restores. `behaviors/index.yaml`: `respect-todo-state` disabled (compiled hooks kept, never fire on current models). Stale "Use TodoWrite VERY frequently" override removed from `domain/rule-effectiveness.md` and `domain/prompting-patterns.md`; `TodoWrite` dropped from the global allow list.
- **Subagent nesting default depth 3, not 5 (v2.1.219)**; 20 concurrent (v2.1.217); 200/session cap removed (v2.1.224). `domain/agent-orchestration.md` corrected (+ `LSP`, `SubagentHandoff` in the background tool set).
- **Ultracode decoupled from `xhigh` (v2.1.284)** — independent `/effort ultracode on|off` toggle. `domain/workflow-automation.md`, `domain/model-ids.md`, `domain/workflow-and-ultracode-policy.md` tier table now prescribe `/effort xhigh` + `/effort ultracode on` as two steps; `maxEffortLevel` (v2.1.267) noted.
- **Unquoted `${CLAUDE_PLUGIN_ROOT}` breaks on paths with spaces (v2.1.281/290)** — `skills/plugin-generator/SKILL.md` now emits exec form (`command` + `args`); `domain/hook-architecture.md` adds the quoting rule plus the v2.1.248/288 fail-closed JSON contract.
- **`allowedMcpServers` governs only user-added servers (v2.1.259)**; managed servers load regardless — use `deniedMcpServers`. `domain/permission-managed-settings.md` rewritten for the MCP block (+ `managedMcpServers`, `alwaysLoad: false`, reserved `widgets`).

#### Process

- New practice: for `/forge watch` deltas >30 releases, curl the raw CHANGELOG and split classification across 2 subagents by version range — `WebFetch` summarization silently dropped 60 versions this run.
- 12 domain rules `last_verified: 2026-10-06`.

## v4.3.0 (2026-08-07)

### Upstream domain sync — 5 practices from /forge watch

Same-day second pass. `/forge watch` surfaced 5 breaking/behavior-changing deltas in Claude Code sub-agents + sandboxing (v2.1.198 → v2.1.222); domain rules updated accordingly.

#### BREAKING (upstream)

- **`domain/model-ids.md`** — Built-in `Explore` subagent inherits main conversation model (capped at Opus on Claude API) since v2.1.198. Previously always Haiku. A session on Opus 4.7/4.8 pays Opus rates for exploration. dotforge's custom `researcher` agent unaffected (pinned to haiku). Override via `~/.claude/agents/Explore.md` or `CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS=1`.
- **`domain/agent-orchestration.md`** — Subagents run in background by default (v2.1.198+) with a restricted built-in tool set (allowlist enumerated). Tools outside the allowlist are SILENTLY removed. Audit `agents/*.md` frontmatter `tools:` lists.
- **`.claude/rules/model-routing.md`** — Cost-caveat note added for built-in Explore path bypass.

#### Security / governance

- **`domain/sandboxing.md`** — `sandbox.credentials` schema no longer boolean. Object form with `files: [{path, mode: "mask|deny", extract}]` and `envVars: [{name, mode}]`. `mask` mode is new (sanitize inline instead of full deny). Managed-settings tolerant stripping degrades invalid config to `deny` mode. Migration required for stacks emitting old boolean form.
- **`domain/agent-orchestration.md`** — Subagent output scanning (v2.1.210+) adds backslash/marker to instruction-shaped patterns in subagent reports (prompt-injection defense). Not a substitute for capability restriction.
- **`domain/agent-orchestration.md` + `domain/permission-model.md`** — Project-level subagent frontmatter `hooks:` now require workspace trust (v2.1.218+). Non-interactive sessions silently skip untrusted hooks. CI implication: migrate to `~/.claude/agents/` or `--agents` inline JSON.

#### Practices pipeline

- Moved: 5 inbox → active (all target `.claude/rules/domain/`)
- `metrics.yml`: 5 new entries (4 monitoring / 1 informational)

---

## v4.2.0 (2026-08-07)

### Inbox drain — 10 practices incorporated, 3 rejected

Long-standing inbox backlog (Jun 4 – Jun 29) processed. Rejected 3 auto-detected session-summary captures (Banca-panel ×2, IntMail — pattern of prior deprecations; not actionable without inspecting origin project). Incorporated 10 practices from TradingBot production experience across 3 stacks.

#### `stacks/trading/rules/trading.md` (+2 sections)

- **Reliability (in-flight operations)** — 5 rules covering cancel/resume symmetry at close/open boundaries, terminal-state persistence, crash-recovery source-of-truth reconstruction, drift verification before deletion. Every deploy is a restart — resume path is hot, not cold.
- **Correctness** — metric semantics before comparing across sources; dedup when two subsystems track same obligation.

#### `stacks/supabase/rules/database.md` (+2 sections)

- **Backend auth** — server-side services MUST use `service_role` key on RLS tables; `anon` symptom is silent read failure + `42501` writes; never grant `anon` policies to "fix" backend failures.
- **Error-code ordering (Postgres)** — CHECK constraints evaluated BEFORE RLS WITH CHECK; `23514` does not imply RLS passed; don't infer permissions from error firing order.

#### `stacks/docker-deploy/rules/infra.md` (+2 sections)

- **Runtime diagnosis** — `docker exec -i <container>` for runtime-faithful repro; reference in-container `os.environ` for secrets, never thread through shell.
- **Config drift detection** — long-lived containers hold their startup env in memory; post-rebuild breaks suspect drift before blaming code diff.

#### Practices pipeline

- Moved: 10 inbox → active, 3 inbox → deprecated
- `metrics.yml`: 10 new entries (7 monitoring / 3 informational)

---

## v4.1.0 (2026-06-29)

### Upstream sync — Claude Code v2.1.162 → v2.1.195 (12 domain rule updates)

Captured + incorporated 4 changelog cycles via `/forge watch` + `/forge update`. Verbatim verification against GitHub `anthropics/claude-code/CHANGELOG.md` before incorporation (caught and rejected 6 hallucinated findings from the watch agent — wrong version attributions, fake CLI subcommands).

#### BREAKING (upstream)

- **`domain/hook-architecture.md`** — Hook matchers with hyphens (e.g. `code-reviewer`, `mcp__brave-search`) now exact-match instead of substring-matching (v2.1.195). dotforge agent matchers (`code-reviewer`, `security-auditor`, `session-reviewer`, `test-runner`) are exact-match candidates — verify intent before propagating template change.

#### Security / governance

- **`domain/sandboxing.md`** — `sandbox.credentials` blocks reads on credential files + secret env vars (v2.1.187); `sandbox.allowAppleEvents` opt-in for macOS (v2.1.181). Strong recommend `credentials` for production-tier projects.
- **`domain/permission-managed-settings.md`** — `requiredMinimumVersion` / `requiredMaximumVersion` managed settings (v2.1.187) for enterprise version gating.
- **`.claude/rules/_common.md`** — `attribution.sessionUrl` (v2.1.187) to omit claude.ai session links from commits/PRs in public repos.

#### Model / agents

- **`domain/model-ids.md`** — Claude Fable 5 (Mythos-class) added as top tier above Opus (v2.1.170). `/effort` persistence confirmation note (v2.1.162).
- **`domain/agent-orchestration.md`** — Sub-agent 5-level nesting (v2.1.172), Agent Teams implicit team (v2.1.178), `claude_code.assistant_response` OTel event (v2.1.193, PII opt-in), `claude agents --json` `waitingFor` field (v2.1.162).

#### Hooks / observability

- **`domain/hook-events.md`** — `post-session` lifecycle hook for self-hosted runners (v2.1.169).
- **`domain/auto-mode.md`** — `autoMode.classifyAllShell` to route every Bash/PowerShell command through the classifier (v2.1.193).

#### CLI / session

- **`domain/cli-flags.md`** — `--safe-mode` / `CLAUDE_CODE_SAFE_MODE` for triage (v2.1.169), `--tools` native-build conditional behavior (v2.1.162), `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` (v2.1.195), `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` (v2.1.169).
- **`domain/context-control-patterns.md`** — `/cd` cache-preserving working-dir change (v2.1.169), `/rewind` after `/clear` (v2.1.191).
- **`domain/auth.md`** — Bedrock now reads AWS region from `~/.aws` config files (v2.1.172).
- **`domain/plugin-distribution.md`** — `/plugin list` command + `disableBundledSkills` setting (v2.1.163, v2.1.169).

#### Practices pipeline

- 4 captures: `inbox/` → `active/` with `incorporated_in: ["v4.1.0"]`
- 4 metrics entries: 3 `not-applicable`, 1 `monitoring` (BREAKING hook matcher — track config-error recurrence)
- Researcher hallucination rate: 6/25 findings invented (24%). Verification step (WebFetch CHANGELOG.md verbatim) caught all. Lesson reinforced: never trust agent-reported version numbers without source quote.

#### Non-breaking for dotforge

All edits are domain-rule content additions — no template, hook, or settings.json changes. Existing projects continue to work; running `/forge sync` propagates the updated domain knowledge into managed projects.

## v4.0.0 (2026-06-03)

### Major release — override capture loop, workflow economics rule, audit items 16-17

dotforge v4 closes the practices↔behaviors loop with an automatic override capture mechanism, ships `workflows/watch.js` as a reference implementation (NOT promoted to default `/forge watch`), and documents the cost-quality tradeoffs that determined v4's narrow scope.

This is a **non-breaking minor migration** in terms of functionality. Existing v3 projects continue to work unchanged. Audit scoring changes — perfect v3 projects score ~9.5/10 v4 until migrated. See [`docs/v4/MIGRATION-V3-TO-V4.md`](v4/MIGRATION-V3-TO-V4.md) for the rollout guide.

#### What's new

##### Override capture loop (Phase 1)

- **`scripts/process-override-log.sh`** (260 lines bash) — processes `.forge/audit/overrides.log`, groups by `(project, behavior_id, tool_name)` in a 30-day window, creates `practices/inbox/auto-override-*.md` for behaviors overridden ≥3 times. Idempotent: same input → same output, no duplicates on re-run.
- **`template/hooks/session-start-process-overrides.sh`** + **`.claude/hooks/session-start-process-overrides.sh`** — SessionStart hook wrappers (timeout 5s, non-blocking).
- **`tests/test-process-override-log.sh`** — 10 test cases covering empty log, missing log, below/at threshold, idempotent re-run, skip if already captured, multiple groups, missing config, out-of-window entries, frontmatter integrity. All green.

##### Workflow economics (the lesson from PoC)

- **`.claude/rules/domain/workflow-economics.md`** (new domain rule, ~110 lines) — documents the cost-quality tradeoffs measured in 4 PoC smoke tests. Decision matrix: when workflow vs skill. Token economy principles. Per-stage model routing (Haiku for mechanical work, Sonnet for judgment).
- **`workflows/watch.js`** stays as REFERENCE implementation. `/forge watch` continues as bash skill (4-25x cheaper than workflow refactor with same or better quality after manual review).
- **`docs/v4/SPEC.md`** preserves the full PoC findings as governance record.

##### Audit checklist items 16-17

- **Item 16: workflow availability (0-1)** — `workflows/` directory exists with at least one `.js` file containing `export const meta`. Score is deliberately low (1 pt) — workflows are governance signal, not quality measure.
- **Item 17: override capture loop active (0-1)** — `.forge/audit/overrides.log` exists AND `session-start-process-overrides.sh` wired in `.claude/settings.json` SessionStart.
- **`skills/audit-project/SKILL.md`** extended to evaluate items 13-17 with v4 transition note (v3.x dotforge auto-passes items 16-17 as informational; v4.0+ scores them normally).

##### Migration tooling (Phase 3)

- **`scripts/migrate-v3-to-v4.sh`** — idempotent migration script with mandatory `--dry-run` mode, atomic `.claude/` backup, `--rollback` support. Four actions evaluated independently: install hook, wire in settings.json, init override log, update manifest. Does NOT touch CLAUDE.md, behaviors, rules, agents, commands, or any project content.
- **`docs/v4/MIGRATION-V3-TO-V4.md`** — full rollout guide with per-project steps, verification commands, suggested wave order for 12 managed projects, rollback instructions.

#### What v4 is NOT (the PoC lesson)

The original v4 thesis was "workflow-native everywhere — convert multi-step skills to workflows for adversarial verify by default". **Phase 0 PoC rejected this** on cost-quality grounds:

- 4 smoke tests measured `workflows/watch.js` at $5-25 per run vs $0.75-1.00 baseline
- Per-agent overhead (~80K tokens) dominates over model-routing savings
- Verify-without-WebSearch (cost optimization) caused quality regression in smoke #4
- Model routing (Haiku parse + Sonnet verify) helps but does not reach cost parity

Workflows remain available as on-demand escalation tool, not as default refactor of mechanical lifecycle work. `/forge sync-all`, `/forge audit`, `/forge update`, `/forge watch` stay as bash skills. `workflows/watch.js` is documented reference, not production tool.

#### Migration

```bash
cd <project>
DOTFORGE_DIR=<path> bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh --dry-run
DOTFORGE_DIR=<path> bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh
```

Full guide: [`docs/v4/MIGRATION-V3-TO-V4.md`](v4/MIGRATION-V3-TO-V4.md).

Suggested rollout: vault-bot (pilot) → InviSight-iOS/TRADINGBOT/cotiza-api-cloud (heavy/production) → rest. SOMA/SOMA2 archived.

#### Internal additions documented for future reference

Files committed in this release:

- `scripts/process-override-log.sh`, `scripts/migrate-v3-to-v4.sh`
- `template/hooks/session-start-process-overrides.sh`, `.claude/hooks/session-start-process-overrides.sh`
- `template/settings.json.tmpl` (wired hook), `.claude/settings.json` (self-hosting wired)
- `tests/test-process-override-log.sh`
- `audit/checklist.md` (items 16-17)
- `skills/audit-project/SKILL.md` (extended for v4 items)
- `.claude/rules/domain/workflow-economics.md`
- `workflows/watch.js` (reference)
- `docs/v4/SPEC.md`, `docs/v4/MIGRATION-V3-TO-V4.md`

VERSION 3.14.0 → 4.0.0.

## v3.14.0 (2026-06-03)

### `/forge update` from v4 PoC smoke captures — 4 high-value upstream findings

Processes 4 inbox practices captured by the v4 workflow PoC adversarial verify (smoke #3, 2026-06-03). All 4 accepted, all incorporated. These were findings the v3.13 bash `/forge watch` missed — validates that workflows DO catch real gaps even though the cost-quality tradeoff rejects them as default tool (see `docs/v4/SPEC.md`).

#### Domain rules

- **`domain/hook-events.md`** — three new sections:
  - **Channel-specific 10K char cap (BREAKING, 2026)** — `additionalContext`, `systemMessage`, and plain stdout now capped at 10K chars (separate from older v2.1.89 generic 50K rule). Excess saves to file with pointer-preview reference. dotforge implication: `post-compact.sh` + `compact-filter.py` need retuning to ≤10K target.
  - **CLAUDE_ENV_FILE preamble execution (4-hook scope)** — expanded from 1-line CwdChanged mention to full coverage. `SessionStart` / `Setup` / `CwdChanged` / `FileChanged` can write `export` statements to `$CLAUDE_ENV_FILE`. Claude Code executes the file as preamble before each Bash subprocess. APPEND-mode warning. SessionStart+CwdChanged pattern for direnv-equivalent.
  - **SessionStart watchPaths registers persistent FileChanged matchers** — `hookSpecificOutput.watchPaths` registers paths with FSEvents/inotify. Modifications fire `FileChanged` events for the rest of the session with ms latency, no polling. dotforge governance use case: mid-session drift detection on `settings.json`, `behaviors/index.yaml`, `.claude/rules/*`.
- **`domain/compaction-strategy.md`** — new "Hook output context cap impact" section: 10K cap on `additionalContext` impacts compact-filter design (was targeting 50K). Re-tune required. `session-restore.sh` and `session-startup.sh` audit needed for drift section growth.
- **`domain/plugin-distribution.md`** — new "Dormant by default — `defaultEnabled: false` (v2.1.154+)" section: plugins can install dormant, require explicit enable. Use cases (ambient cost, external services, opinionated behaviors). Default recommendations for `plugin-generator` skill.

#### Source

All 4 findings detected by `workflows/watch.js` smoke #3 (2026-06-03). The PoC verified each via adversarial cross-check against authoritative sources before reporting. This validates workflow value (quality is real) while confirming cost (~$5-25 per run) keeps them as on-demand escalation rather than default tool. See `docs/v4/SPEC.md` for full PoC findings and v4 scope decision.

#### Practices lifecycle

- 4 inbox → active (hook-output-10k-cap, claude-env-file-preamble, sessionstart-watchpaths, plugin-defaultenabled-dormant)
- `metrics.yml`: 4 entries added (1 monitoring — hook-output-10k-cap targets compact context loss; 3 informational)

## v3.13.0 (2026-06-03)

### `/forge update` from 2026-06-03 watch — v2.1.158 → v2.1.161 coverage + ultracode policy refinements

Processes 6 inbox practices from `/forge watch` 2026-06-03. 1 breaking-ish (workflow subagents bypass session permission mode), 4 medium, 1 low-priority bundle. All accepted, all incorporated.

#### Security boundary clarification

- **`domain/workflow-automation.md`** — new "Permission model" subsection: workflow subagents ALWAYS run in `acceptEdits` mode regardless of session permission mode (including `plan`). File edits auto-approved. Table mapping session mode → launch prompt → subagent edit behavior. Reinforces that `permissions.deny` is the only kernel-level backstop for production.
- **`domain/workflow-and-ultracode-policy.md`** — new "Security boundary" section: production-tier policy assumption (plan-mode gates edits) holds for direct main-thread actions but NOT for workflow-spawned subagents. Audit checklist for `permissions.deny` paths.
- **`domain/permission-model.md`** — `acceptEdits` row in 6-modes table now flagged with v2.1.160 exceptions. New "Paths that always prompt regardless of mode" section: shell rc files (`.zshenv`/`.zlogin`/`.bash_login`/`~/.config/git/`) always prompt; build-tool config (`.npmrc`/`.yarnrc*`/`bunfig.toml`/`.bazelrc`/`.pre-commit-config.yaml`/`.devcontainer/`) prompts in `acceptEdits` mode.
- **`domain/sandboxing.md`** — new "Built-in safety prompts (Claude-Code-level, v2.1.160+)" section with concrete `denyWrite` example for defense-in-depth. Also documents the v2.1.149 → v2.1.161 workflow worktree isolation regression+fix.

#### Workflow + ultracode refinements

- **`domain/workflow-automation.md`** — three new subsections:
  - "Bundled workflows" — `/deep-research <question>` ships built-in (v2.1.154+)
  - Keyword trigger rename: `workflow` → `ultracode` (v2.1.160). Setting key `workflowKeywordTriggerEnabled` unchanged. Anti-confusion guidance.
  - "Runtime activation: `/effort ultracode`" — session activator that combines xhigh + auto-workflow planning. Tier mapping table.
- **`domain/workflow-and-ultracode-policy.md`** — new "Activation: tier (policy) → runtime" section. Production tier → `/effort ultracode` mandatory. Heavy tier → conditional. Closes the loop between dotforge tier system and upstream runtime activator.
- **`domain/model-ids.md`** — Effort levels section: `ultracode` documented as 6th tier (Opus-only, runtime-activator that combines xhigh + auto-workflow orchestration).
- **`template/hooks/session-startup.sh`** + **`.claude/hooks/session-startup.sh`** — tier brief made actionable: `production` recommends "Activate now: `/effort ultracode`"; `heavy` recommends activation for architecture/security tasks.

#### Behavior changes documented

- **`domain/hook-events.md`** — PostToolBatch: v2.1.161 batch-failure isolation. Failed Bash no longer cancels other parallel calls; hook must inspect per-tool success.
- **`domain/auto-mode.md`** — Tool concurrency table addendum: batch-level vs kernel-level concurrency semantics (v2.1.161 changes batch-level).

#### Small additions bundle (low priority, consolidated)

- **`domain/auto-mode.md`** — `CLAUDE_CODE_ENABLE_AUTO_MODE=1` opt-in for Bedrock/Vertex/Foundry. Mantle added to enterprise platforms list (v2.1.161 changelog mention).
- **`domain/auth.md`** + **`domain/permission-managed-settings.md`** — Mantle added to third-party providers in `forceLoginOrgUUID`/`forceLoginMethod` enforcement scope.
- **`domain/permission-managed-settings.md`** — new bullet under MCP server config: `claude mcp list/get/add` no longer expands `${VAR}` in CLI output (v2.1.161 security fix).
- **`domain/agent-orchestration.md`** — OpenTelemetry section extended: `OTEL_RESOURCE_ATTRIBUTES` as metric labels, `tool_decision` includes `tool_parameters` with `OTEL_LOG_TOOL_DETAILS=1`. New section: "Single-file grep satisfies read-before-edit (v2.1.160+)".
- **`domain/parallel-sessions.md`** — `claude agents` rows show `done/total` (v2.1.161+).

#### Practices lifecycle

- 6 inbox → active (workflow-subagents-bypass-permission-mode, v2160-security-prompts-shell-rc, deep-research-bundled-workflow-and-effort-ultracode, v2160-keyword-rename-workflow-to-ultracode, v2161-posttoolbatch-failed-bash-no-cancel, v2158-v2161-small-additions-bundle)
- `metrics.yml`: 6 entries added (4 monitoring — 2 security + 1 logic + 1 config; 2 informational)

## v3.12.1 (2026-06-02)

### Housekeeping — completar `/forge update` 2026-06-01 sin commitear

El `/forge update` del 1/6 había procesado 6 prácticas y editado 7 domain rules + metrics + skill + template hook, pero quedó sin commitear. Esta versión los baja a `main` sin nuevos cambios. Esto es housekeeping puro — no agrega features.

#### Prácticas movidas a estado terminal

| Práctica | Estado |
|---|---|
| `2026-06-01-workflows-v2154-full-coverage` | active — completa cobertura de `/workflows` v2.1.154 en `domain/workflow-automation.md` (+75 líneas) |
| `2026-06-01-agent-frontmatter-hooks` | active — documenta hooks scoped por subagent en `domain/agent-orchestration.md` (+20 líneas) |
| `2026-06-01-stopfailure-matchers` | active — matchers de `StopFailure` event para production routing en `domain/hook-events.md` (+25 líneas, parte) |
| `2026-06-01-settings-hardening-v2140-bundle` | active — bundle de hardenings v2.1.140 (auto-mode, hooks, managed-settings, permission-managed) |
| `2026-06-01-worktree-lifecycle-improvements` | active — auto-unlock + `EnterWorktree` mid-session en `domain/parallel-sessions.md` (+8 líneas) |
| `2026-06-01-init-interactive-flow` | evaluating — propuesta de flujo init interactivo |

#### Domain rules actualizados

- `domain/workflow-automation.md` (+75) — coverage completa de `/workflows` v2.1.154
- `domain/hook-events.md` (+25) — StopFailure matchers + Stop/SubagentStop additional fields v2.1.145+
- `domain/hook-architecture.md` (+24) — agent-scoped hooks frontmatter + OpenTelemetry agent attribution
- `domain/agent-orchestration.md` (+20) — agent-scoped hooks pattern + OTEL spans
- `domain/parallel-sessions.md` (+8) — worktree lifecycle improvements
- `domain/auto-mode.md` (+1) — hardening note
- `domain/permission-managed-settings.md` (+1) — hardening note

#### Otros

- `template/hooks/session-report.sh` (+13) — métrica adicional (probable: pending_bg_tasks + active_crons)
- `skills/sync-all-repos/SKILL.md` (+1) — minor edit
- `practices/metrics.yml` (+50) — 6 entradas nuevas correspondientes a las prácticas movidas

## v3.12.0 (2026-06-02)

### Workflow + Ultracode policy — tier-driven defaults per project

Diseñado con el Workflow tool (4 fases, 9 agentes, adversarial verify) tras consultar criterios de uso. El verify atrapó 4 issues críticos + 2 mejoras de clasificación antes de aplicar — los arreglos están reflejados en lo que se commitea.

#### Conceptos canónicos (no conflagran)

- **Workflow = TOOL** (orquestación multi-agente, v2.1.154+). Por tarea.
- **Ultracode = MODE** (adversarial verify + workflow-first + plan-mode + structured output). Por proyecto, vía tier en registry.

#### Nuevas piezas

- **`domain/workflow-and-ultracode-policy.md`** (nueva, 65 líneas) — política canónica con 5 criterios (C1 Blast radius, C2 Domain risk, C3 Ambiguity, C4 Reversibility, C5 Prior failure), score mapping, 4 tiers (`light`/`standard`/`heavy`/`production`), portfolio table para 12 proyectos, anti-patterns. Globs: CLAUDE.md + registry.
- **`/forge ultracode-check`** (slash command) — lee tier del registry + git state + last-startup, aplica los 5 criterios, output: "ON | CONSIDER | OFF" con score N/5 y reasoning. Override a ON si C2+C4 (irreversible touch on risk surface).
- **`.claude/hooks/session-startup.sh`** + `template/hooks/session-startup.sh` — nuevo bloque que lee `ultracode_tier` del registry para el proyecto actual y agrega `**Ultracode tier:** <tier> — <hint>` al startup brief. Hint diferenciado por tier (production = "hard-gate, blocks merge on High"; heavy = "soft-gate"; standard = "advisory, /forge ultracode-check for verdict"; light = "workflow only for batch ops").
- **`registry/projects.yml`** header documenta el nuevo campo `ultracode_tier` con allowed values y semantics. Promotion upward-only (no auto-demote).

#### Adversarial verify findings (resueltos en este commit)

| # | Finding | Resolución |
|---|---|---|
| 1 | Vocabulario inconsistente (command usaba `critical/standard/experimental` vs `light/standard/heavy/production` en otros) | Unificado a `{light, standard, heavy, production}` en los 4 artifacts |
| 2 | 5 criterios distintos entre rule y command | Adoptado el set del command (más operacional): C1-C5 con nombres y umbrales explícitos |
| 3 | Registry omitía `light` de allowed values | Documentado en header |
| 4 | Hint del hook para `production` más débil que contrato del registry | Reforzado: "Multi-pass adversarial verify. Hard-gate: blocks merge on High findings." |
| 5 | **dotforge clasificado `standard`** — pero propaga a 12 proyectos via `/forge sync` | Promovido a **`heavy`** (tratable como `production` para cambios en `template/hooks/`, `stacks/*/settings.json.partial`, `global/`) |
| 6 | **SOMA2 clasificado `heavy`** — pero es dev branch sin traffic | Bajado a **`standard`** |

#### Asignación de tier (12 proyectos)

```
production (3): TRADINGBOT, cotiza-api-cloud, SOMA
heavy     (5): InviSight-iOS, jira-nbch, cds-dashboard, openclaw, dotforge
standard  (4): SOMA2, vault-bot, derup, crm
light     (0): —
```

#### Bug fix incidental

`registry/projects.local.yml` tenía `path: '.'` para dotforge y `path: /Users/luiseiman/Documents/crm` para crm (path malo). Hook compara con cwd absoluto → no matcheaba. Fix: paths absolutos canónicos para los 12.

## v3.11.0 (2026-06-01)

### `/forge update` from watch-upstream — resolves /workflows TODO + 4 more

Processes 5 inbox practices captured from the 2026-06-01 `/forge watch` run: 1 high-priority (resolves explicit TODO), 3 medium, 1 low-priority bundle. 1 practice deferred pending empirical testing (`init-interactive-flow`).

#### Domain rules

- **`domain/workflow-automation.md`** — `/workflows` section **TODO resolved**. Full v2.1.154+ coverage added: declarative `export const meta` block (pure literal constraint), 5 core primitives (`agent`/`parallel`/`pipeline`/`phase`/`log`/`workflow`), schema validation via `opts.schema`, concurrency cap (`min(16, cpu cores - 2)` per workflow, 1000 agents lifetime backstop), budget integration (`budget.total`/`spent()`/`remaining()`), resume semantics (`resumeFromRunId` + cached `(prompt, opts)` re-execution), pipeline vs parallel decision criteria, quality patterns (adversarial verify, perspective-diverse, judge panel, loop-until-dry, multi-modal sweep, completeness critic), settings (`disableWorkflows`, `workflowKeywordTriggerEnabled` v2.1.157), dotforge integration considerations.
- **`domain/parallel-sessions.md`** — new "Lifecycle improvements (2026 changelog)" subsection: Claude-managed worktrees auto-unlock on agent finish (no more stuck worktrees blocking `git checkout main`), `EnterWorktree` mid-session switching, cleanup hygiene pattern. Lived during sync-all 2026-06-01 (TRADINGBOT `festive-maxwell-a70698`/`heuristic-swartz-65163d`). Plus `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` opt-in for loading CLAUDE.md from `--add-dir` paths.
- **`domain/hook-events.md`** — new "StopFailure matchers" section: documented `error_type` matcher values (`rate_limit`, `authentication_failed`, `billing_error`, `server_error`) with production-grade routing recommendations (page on billing_error, rotate token on authentication_failed, log on rate_limit, alert if server_error persistent). Concrete hook config example.
- **`domain/hook-architecture.md`** — three additions: (1) PowerShell `if:` pattern matching fix (e.g. `PowerShell(git push*)` now actually matches), (2) new "ConfigChange matcher values" subsection (`user_settings`/`project_settings`/`policy_settings`/`skills`), (3) new "Settings.json hook parsing resilience" subsection — unrecognized event names no longer invalidate the entire `hooks` section (explains historical "why aren't my hooks running" mysteries).
- **`domain/agent-orchestration.md`** — new "Agent-scoped hooks" section: agents can declare `PreToolUse`/`PostToolUse`/`Stop` hooks in frontmatter, scoped to that subagent's lifecycle. Use-case table per dotforge agent role (code-reviewer / security-auditor / test-runner / implementer / researcher / architect / session-reviewer). Status: documented architecturally; not yet wired into `agents/*.md` pending empirical schema verification (lowest blast radius: test-runner).
- **`domain/permission-managed-settings.md`** — added `claudeMd` managed key (inline CLAUDE.md content in `managed-settings.json` instead of separate file deploy).
- **`domain/auto-mode.md`** — Bedrock/Vertex/Foundry auto mode availability for Opus 4.7+4.8 (was claude.ai/Console-only).

#### Templates + skills

- **`template/hooks/session-report.sh`** — extended Stop hook stdin parsing to also read `error_type` from StopFailure payload (when hook is wired to both events). New `stopfailure_error_type` field in JSON metrics. Whitelist validation (`rate_limit`/`authentication_failed`/`billing_error`/`server_error`/`none`/`unknown`).
- **`skills/sync-all-repos/SKILL.md`** — new edge case: "Stuck Claude-managed worktrees block branch checkout". Detection command + cleanup pattern. Encodes the festive-maxwell/heuristic-swartz lesson from real run today.

#### Deferred

- **`init-interactive-flow`** practice (`CLAUDE_CODE_NEW_INIT=1` multi-phase `/init`) marked `needs-more-info`. Requires empirical test run on a fresh project to compare against `/forge init` before deciding adoption path (deprecate / hybrid / differentiate).

#### Practices lifecycle

- 5 inbox → active (workflows-v2154-full-coverage, worktree-lifecycle-improvements, stopfailure-matchers, agent-frontmatter-hooks, settings-hardening-v2140-bundle)
- 1 inbox → inbox tagged `needs-more-info` (init-interactive-flow)
- `metrics.yml`: 5 entries added (2 monitoring, 3 informational)

## v3.10.1 (2026-06-01)

### `/forge update` partial sync from Claude Code v2.1.153 → v2.1.158 + watchdog field practice

Processes 6 inbox practices: 5 upstream from the v2.1.153–v2.1.158 release window past v3.10.0's sync cutoff, plus 1 field practice from `vps-control`. 4 incorporated to domain rules, 1 to a new cross-cutting doc, 1 stubbed pending official docs.

#### Domain rules

- **`domain/model-ids.md`** — Opus 4.8 GA (v2.1.154): table top row now `claude-opus-4-8`, Opus 4.7 demoted to legacy-pin note for benchmark reproducibility. `xhigh` effort tier annotated as Opus-4.7-and-4.8-exclusive. Fast mode advisory updated: Opus 4.8 fast = 2x cost / 2.5x speed (more aggressive than 4.7). **`CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` documented as removed 2026-06-01** (was deprecated in v2.1.154); the pin-to-4.6 escape hatch no longer exists.
- **`domain/prompting-patterns.md`** — new "Headless invocation cost profile (v2.1.154+)" section documenting the v2.1.154 lean-system-prompt default (Opus 4.8 / Sonnet 4.6 / Haiku 4.5; Opus 4.7 still full) and the manual lean-invocation pattern (`--system-prompt + --disable-slash-commands + --strict-mcp-config + cd /tmp`). Carries `vps-control` field measurement as evidence: 117k → 31k cache_creation → 0 on cache hit, 12-37x cost reduction.
- **`domain/plugin-distribution.md`** — new "Plugin from `.claude/skills/` (v2.1.157+)" section: plugins in that path auto-load without marketplace, `claude plugin init <name>` scaffolds the minimal `plugin.json` + `SKILL.md`. "When to plugin vs `.claude/`" table updated — first row now recommends the scaffolded plugin shape over standalone `.claude/skills` for one-project experiments. Threshold to plugin lowered.
- **`domain/workflow-automation.md`** — **/workflows added as the 5th primitive (v2.1.154+)**, alongside /goal /loop /schedule /batch. Stub coverage: positioning (orchestrates tens-to-hundreds of agents, dynamic shape vs Agent Teams' handcrafted ≤4), v2.1.158 keyword-trigger setting note, and explicit **TODO** flag for official docs. Anti-patterns extended.

#### New cross-cutting doc

- **`docs/monitoring-patterns.md`** (new) — Five field-tested patterns for any rules-based monitoring system: (1) suppression symmetry across all checks of a scheduled service, (2) stuck-detection requires backlog evidence (lag + pending > 0), (3) throttle by sub-issue not aggregate hash, (4) on-demand services need a distinct schedule class, (5) don't auto-restart what requires human interaction. Originating practice: `vps-control` watchdog incident series May 2026.

#### Deferred

- **`/workflows`** practice (#workflows-fifth-primitive) marked `status: evaluating`, not `active`. Stub merged but full coverage pending an official docs fetch for the declarative/dynamic API surface and `settings.json` schema. Re-process in next `/forge update` when docs are read.

#### Practices lifecycle

- 4 inbox → active (opus-4-6-fast-mode-override-removed, opus-4-8-ga, lean-system-prompt-default, plugins-skills-auto-load)
- 1 inbox → active (watchdog-triage-symmetry, own-experience)
- 1 inbox → evaluating (workflows-fifth-primitive)
- `practices/metrics.yml`: 6 new entries (98 practices tracked total). 3 with `status: monitoring` (target concrete errors), 2 `informational`, 1 `evaluating`.
- Inbox empty.

#### Propagation

- Domain rules and `docs/` are picked up by `/forge sync` on managed projects. The Opus-4.6-fast-mode-override removal note is urgent for any project pinning the env var in CI — sync now.
- No `template/` or `stacks/*/` changes in this release — pure rules + docs delta. Managed projects only need a docs/rules refresh.

## v3.10.0 (2026-05-27)

### `/forge watch` sync from Claude Code v2.1.144 → v2.1.152 (features)

Builds on the v3.9.1 security patch with 14 upstream feature/UX practices from the same release window. Adds a new hook event (the first display-time event), a new frontmatter field, two new managed settings, one new slash command, plus several rename / UX semantic shifts that need documentation.

#### New hook event

- **MessageDisplay** (v2.1.152+) — first display-time hook event, lifecycle cadence #4 in the catalogue (was 3). Hook can transform or hide assistant message text as it is rendered. Use cases: PII/secret redaction, post-processing markdown, compliance overlays. Catalogue bumped 32+ → **34+**.

#### Hook payload / output expansions

- **SessionStart** (`hookSpecificOutput.reloadSkills: true` + `sessionTitle`, v2.1.152) — a hook that installs skills can request a same-session re-scan via `reloadSkills`; a SessionStart hook can set the session title (was UserPromptSubmit-only since v2.1.94).
- **Stop / SubagentStop** (`background_tasks` + `session_crons` fields, v2.1.145) — exit-time visibility into `claude --bg` sessions still running and `/schedule` crons active in the session.
- **`domain/hook-events.md`** + **`hook-architecture.md`** updated accordingly.
- **`template/hooks/session-report.sh`** now reads stdin payload and emits `pending_bg_tasks` + `active_crons` in the JSON metrics file (defaults to 0 on older Claude Code without the fields).

#### New frontmatter field

- **`disallowed-tools`** (v2.1.152) for skills and slash commands. Companion to `allowed-tools`; removes tools from the model while the skill is active. Pattern for read-only analytical skills (audit, rule-check, diff): `disallowed-tools: [Bash, Write, Edit]`. Documented in `domain/rule-effectiveness.md` frontmatter table.

#### Settings

- **`autoMode` first-use opt-in consent removed** (v2.1.152) — auto mode now activates directly. `domain/auto-mode.md` updated.
- **`allowAllClaudeAiMcps`** managed setting (v2.1.149) — load claude.ai cloud MCP connectors alongside `managed-mcp.json`. `domain/permission-managed-settings.md` row added.
- **`pluginSuggestionMarketplaces`** managed setting (v2.1.152) — admins allowlist marketplaces for context-aware tip suggestions. `domain/plugin-distribution.md` row added.

#### Slash commands

- **`/code-review`** (v2.1.147 rename from `/simplify`; v2.1.152 added `--fix`) — `--comment` posts inline GitHub PR comments, `--fix` applies findings to working tree. `/simplify` now invokes `--fix`. Independent from dotforge's `code-reviewer` subagent — `.claude/rules/agents.md` clarifies when to use each.
- **`/reload-skills`** (v2.1.152) — re-scan skill directories without restart. Pairs with the SessionStart `reloadSkills` hook field.
- **`/extra-usage` → `/usage-credits`** (v2.1.144 rename; old name still works).
- **`/model`** is per-session by default (v2.1.144) — was settings-mutating before. Press `d` in the picker to set persistent default. `domain/model-ids.md` UX section added.

#### CLI

- **`claude agents --json`** (v2.1.145) — live sessions as JSON for tmux-resurrect / status bars / pickers. `domain/parallel-sessions.md` + `cli-flags.md` updated.
- **`/resume` supports background sessions** (v2.1.144) — `claude --bg`-started sessions appear in picker marked `bg`.

#### Auth

- **`ANTHROPIC_WORKSPACE_ID`** env var (v2.1.141, captured 2026-05-18) — scopes a token when the user's federation rule covers more than one workspace. Required for multi-workspace SAML/OIDC. `domain/auth.md` federation section added.

#### Observability

- **OTEL `claude_code.tool` spans** now carry `agent_id` / `parent_agent_id` (v2.1.145) — previously only on `llm_request` spans. Trace parenting fixed: background subagent spans nest under dispatching Agent tool span. `domain/agent-orchestration.md` OTEL section added.

#### Practices lifecycle

- 14 practices migrated inbox → active. Status: 4 `monitoring` (target concrete errors), 10 `informational` (general knowledge).
- `practices/metrics.yml`: 14 new entries (92 practices tracked total).
- Inbox now empty.

## v3.9.1 (2026-05-27)

### Upstream security fixes propagated (v2.1.145 → v2.1.149)

Patch release dedicated to five upstream security/permission fixes from the v2.1.145–v2.1.149 hardening pass. No feature additions — see v3.10.0 for those. Projects auditing against pre-v2.1.149 Claude Code builds should re-verify; the fixed bugs could cause silent permission/sandbox bypasses.

#### Domain rules

- **`domain/permission-model.md`** — new "Permission-detection bypasses fixed in v2.1.145-149" section documenting three classes:
  - **Bare env var assignments** (v2.1.145 fix): `FOO=bar cmd` with non-allowlisted vars was auto-approved
  - **PowerShell built-in `cd` functions** (v2.1.149 fix): `cd..`, `cd\`, `cd~`, `X:` changed working dir undetected, letting a later command escape the workspace
  - **Stale `PWD`/`OLDPWD`/`DIRSTACK` tracking** (v2.1.149 fix): same escape class via stale variable values across `cd`/`pushd`/`popd`
- **`domain/sandboxing.md`** — new "Worktree allowlist scope fix" section: pre-v2.1.149 the sandbox write allowlist covered the entire main repo root instead of just the shared `.git` subset. Agent Teams patterns that relied on worktree teammates writing to main-repo files were exploiting the bug. Also new "PowerShell execution policy bypass" section documenting `-ExecutionPolicy Bypass` default + opt-out via `CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY=1`.
- **`domain/auth.md`** — new "Enterprise enforcement fix (v2.1.147)" section: managed-settings `forceLoginOrgUUID` / `forceLoginMethod` were enforced only against Claude.ai sessions; third-party-provider (Bedrock/Vertex/Foundry) and API-key sessions silently bypassed. Now fixed — re-verify enterprise audits.
- **`domain/permission-managed-settings.md`** — `forceLoginOrgUUID` / `forceLoginMethod` row added with v2.1.147 fix note.
- **`.claude/rules/agents.md`** — Agent Teams worktree note: pre-v2.1.149 teammates had sandbox-blessed write access to entire main repo; post-fix limited to worktree + shared `.git` subset.

#### Security checklist

- **`docs/security-checklist.md`** — new "Windows PowerShell execution policy" entry under Claude Code permissions: opt-out env vars, plus warning to audit any Windows project on pre-v2.1.149 builds.

#### Practices

- 5 practices migrated inbox → active (`status: monitoring`, all `error_type: security`)
- `metrics.yml`: 5 new entries

#### Recommended action for managed projects

Re-audit any project with `claude --worktree` patterns, Windows + PowerShell tool, or enterprise `forceLogin*` managed settings. The v3.9.1 sync is the marker for "I've reviewed against the v2.1.149 hardening pass". `/forge audit` to refresh the score.

## v3.9.0 — 2026-05-22

### Sync from Claude Code v2.1.141-143

Procesados 13 items del inbox (acumulado 2026-05-18 a 2026-05-19). 8 incorporados a domain rules + skill + best-practices. 3 rechazados (1 informational sin acción, 2 auto-stubs de session-changes sin proyecto identificable). 2 diferidos (`powershell-execution-policy` con tag `needs-windows-user`; `workspace-id-federation` con tag `needs-enterprise-federation`).

#### Domain rules

- **`domain/hook-events.md`** — nueva sección "Hook JSON output fields (universal)" con `continue`, `stopReason`, `suppressOutput`, `systemMessage`, y el nuevo `terminalSequence` (v2.1.141+) para desktop notifications / window titles / terminal bell desde hooks sin TTY. Nueva sección "Stop hook contract (v2.1.143+)" con el cap de 8 bloqueos consecutivos y `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`.
- **`domain/hook-architecture.md`** — sección "Stop hook convergence contract (v2.1.143+)": cap de 8 blocks, patrones de convergencia (contadores en `.claude/session/`, `systemMessage` en vez de `block`).
- **`domain/model-ids.md`** — nueva sección "Fast mode (Opus toggle)" con default flippeado a Opus 4.7 (v2.1.142) y `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1` para pin a 4.6.
- **`domain/cli-flags.md`** — `claude agents` ahora documentado como launcher con los 9 flags (`--cwd`, `--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir`, `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions`). Nuevas env vars: `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE`, `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`.
- **`domain/parallel-sessions.md`** — nueva sección "Disabling bg session worktree isolation" con `worktree.bgIsolation: "auto"|"none"` y los trade-offs (Bazel/codegen vs concurrent-clobber risk). Nueva sección "Configuring sessions dispatched from claude agents" documenta los flags-as-launcher y la persistencia en detach a `/bg` (v2.1.143).
- **`domain/compaction-strategy.md`** — tabla extendida con cuarta modalidad: **rewind + "Summarize up to here"** (v2.1.141), sexta opción del rewind menu. Comprime desde session start hasta un checkpoint elegido, deja turnos posteriores intactos.

#### Skills

- **`skills/plugin-generator/SKILL.md`** — documenta dos shapes:
  - **Flat** (single-skill, v2.1.142+): `SKILL.md` en root sin `skills/` directory
  - **Structured** (default): cuando hay ≥2 skills u otros componentes
  - Plus: `plugin.json` ahora incluye `dependencies: []` con guía sobre el enforcement de v2.1.143 (`claude plugin disable` rechaza si otros plugins dependen; `enable` force-enables transitive deps).

#### Docs

- **`docs/best-practices.md`** — nueva subsección "Recent additions (v2.1.141-143)" con 6 entries: Stop hook anti-pattern, plugin disable-chain, hook terminalSequence, worktree.bgIsolation, claude agents launcher, rewind+summarize partial.

#### Inbox lifecycle

| Item | Decisión |
|---|---|
| `claude-agents-cli-flags` | accept → `incorporated_in: ['3.9.0']` |
| `fast-mode-opus-4-7-default` | accept (informational) |
| `hook-terminal-sequence` | accept (informational) |
| `plugin-dependency-enforcement` | accept (monitoring: integration) |
| `plugin-root-skill-md` | accept (informational) |
| `rewind-summarize-partial` | accept (informational) |
| `stop-hook-block-cap` | accept (monitoring: logic) |
| `worktree-bgisolation-none` | accept (monitoring: config) |
| `plugin-lsp-visibility` | reject — informational, no requiere cambio (self-deferred) |
| `stoic-babbage-session-changes` | reject — auto-stub sin proyecto identificable |
| `festive-maxwell-session-changes` | reject — idem |
| `powershell-execution-policy` | defer — tag `needs-windows-user` |
| `workspace-id-federation` | defer — tag `needs-enterprise-federation` |

#### Metrics

8 entradas nuevas en `practices/metrics.yml`: 3 monitoring (logic/config/integration con error_targeted), 5 informational.

## v3.8.1 — 2026-05-18

Maintenance: docs domain migration.

- `skills/watch-upstream/SKILL.md`: 6 fetch URLs migrated from
  `docs.anthropic.com/en/docs/claude-code/*` to `code.claude.com/docs/en/*`
  (Anthropic flipped the canonical host between v3.7.x and v3.8.0).
  `agent-tool` slug also moved → `sub-agents`. Added llms.txt fallback
  note for future migrations.
- `docs/internal/improvement-plan-internals.md`: WebFetch reference
  updated to point at the new canonical host.

Practice: `2026-05-18-docs-domain-migration-claude-code` (active,
informational).

## v3.8.0 (2026-05-13)

### `/forge watch` sync from Claude Code v2.1.129 → v2.1.140

Diez prácticas upstream incorporadas. Cinco de prioridad alta cubren primitives nuevos (hook `continueOnBlock`, exec form, `autoMode.hard_deny`, effort visibility en hooks, API key precedence). Cinco de prioridad media cubren breaking sutiles (worktree.baseRef flip, gateway model discovery opt-in, plan mode fix) y features nuevos (`/goal`, `claude --bg`).

#### Domain rules actualizadas

- **`domain/hook-architecture.md`** — `continueOnBlock: true` para PostToolUse (v2.1.139+) cambia el contrato de fatal stop a feedback loop. Forma exec (`args: string[]`, v2.1.139+) — spawn directo sin shell, sin quoting para path placeholders. Nueva sección sobre `effort.level` / `$CLAUDE_EFFORT` visibility en hooks (v2.1.133+).
- **`domain/hook-events.md`** — `continueOnBlock` documentado bajo PostToolUse. Sección nueva "Shared payload fields" cubriendo `session_id` / `$CLAUDE_CODE_SESSION_ID` (v2.1.132+), `effort.level` / `$CLAUDE_EFFORT` (v2.1.133+), `cwd`, `transcript_path`. Subagent agent_id headers + OTEL attrs (v2.1.139+).
- **`domain/auto-mode.md`** — tercer tier `autoMode.hard_deny` (v2.1.136+) con tabla allow/soft_deny/hard_deny. Bloquea sin override possible — recomendado para `Bash(curl *|sh)`, eval pipes, base64-decode pipes en proyectos con cloud creds.
- **`domain/permission-model.md`** — cascade order corregida: plan mode ahora precede allow rules (v2.1.136 fix). Antes `Edit(*)` permitía escribir bajo plan mode — era bug. Anotada también el hard_deny short-circuit antes del classifier.
- **`domain/parallel-sessions.md`** — `worktree.baseRef` setting (v2.1.133+) con nota sobre default flip `head → fresh` entre v2.1.128 y v2.1.133. Sección nueva "Background sessions" cubriendo `--bg` + 5 subcomandos (`attach`/`logs`/`respawn`/`rm`/`stop`) + `claude agents` agent-view (v2.1.139+). Tabla comparativa worktree / fork / background.
- **`domain/cli-flags.md`** — nueva sección "Background sessions" + 5 subcomandos. Nueva sección "Env vars worth knowing" con `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY` (breaking v2.1.129 — opt-in para gateway model discovery), `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN`, `CLAUDE_CODE_FORCE_SYNC_OUTPUT`, `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE`, `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL`, `CLAUDE_CODE_SESSION_ID`, `$CLAUDE_EFFORT`.
- **`domain/workflow-automation.md`** — agregada sección `/goal` (v2.1.139+) al principio como cuarto primitive: condition-driven vs `/loop` cadence-driven. Notas sobre Stop condition phrasing y fail-closed bajo `disableAllHooks`/`allowManagedHooksOnly` (v2.1.140 fix).

#### Domain rules nuevas

- **`domain/auth.md`** (nueva, ~45 líneas) — modelo de auth completo: 4 sources con precedencia (API key > setup-token OAuth > Claude.ai > Console), feature gating por API key presence (v2.1.139+ disables Remote Control / `/schedule` / claude.ai MCP / notifications cuando API key está set), canonical CI path con `claude setup-token`, anti-patterns (API key in `.bashrc`, shared OAuth tokens, etc.).

#### Otros

- **`docs/claude-vs-forge.md`** — `/goal` agregado a tablas de automation (EN + ES) junto a `/schedule`, `/loop`, `/autofix-pr`.

#### Inbox lifecycle

- 10 watch captures (2026-05-13) → `active/`
- 7 auto-generated `*-session-changes` rejected (incluye 1 duplicado macOS Finder)
- 0 deferred esta vuelta
- `metrics.yml`: 10 entradas nuevas (5 con `status: monitoring` por targetear errores concretos, 5 con `status: informational` por ser conocimiento general)

## v3.7.1 (2026-05-05)

### Política de compactación basada en evidencia

Investigación combinando academia (Liu et al. Stanford 2023, Chroma Research, Greg Kamradt) y práctica de campo en X (Boris Cherny y Cat Wu de Anthropic, Daniel San, Avthar, Paweł Huryn) consolidada en política operacional dotforge. Threshold canónico: **80%** del context window (no 50%, no 96.7% default).

#### Nuevas piezas

- **`domain/compaction-strategy.md`** (nueva domain rule, 70 líneas) — política basada en evidencia: threshold 80%, distinción `/compact` vs `/clear` vs subagent, anti-patterns confirmados, cache economy (Paweł Huryn — invalidación de prefix cache), re-anchoring para mitigar "lost in the middle" (Liu et al.). Citas con URLs.
- **`/forge compact-task`** (nuevo slash command) — wrapper de `/compact` con hint estandarizado dotforge: preserve decisions, files modified, pending TODOs, behaviors disabled, last commit; drop tool output verbose. Resuelve el anti-pattern de `/compact` sin instructions custom.
- **`/forge context-status`** (nuevo slash command) — reporte read-only sobre uso estimado del context window, cache health proxy (basado en `tool-latency.sh` p50), edits recientes, recomendación de acción. No compacta.
- **`pre-compact-warning.sh`** (nuevo hook, wired en `UserPromptSubmit`) — alerta proactiva al 80% (warning) y 90% (urgent). Estimación: bytes del transcript / 5. Configurable via env vars: `CLAUDE_CONTEXT_LIMIT`, `CLAUDE_COMPACT_WARN_PCT`, `CLAUDE_COMPACT_URGENT_PCT`. Smoke-tested en 3 escenarios (debajo del threshold, warning, urgent).
- **`docs/internal/compaction-strategy.md`** (~200 líneas) — guía operacional canónica con flow chart ASCII, tabla de decisión `/compact` vs `/clear` vs subagent, configuración por tipo de proyecto (light/standard/heavy), bibliografía completa (académica + X).

#### Wiring

- `.claude/settings.json`: nuevo bloque `UserPromptSubmit` con `pre-compact-warning.sh` (timeout 3s)
- `template/settings.json.tmpl`: idem para propagación a 12 proyectos
- `template/hooks/pre-compact-warning.sh`: copia propagable

#### Hallazgos clave de la investigación

- **Liu et al. (Stanford 2023)**: 30%+ accuracy loss para info en el medio del contexto (7-50% depth)
- **Chroma Research (2024)**: 18 modelos frontier degradan dentro de su ventana declarada — Sonnet 200K muestra caídas desde 50K tokens
- **Greg Kamradt**: GPT-4 recall degrada >73K tokens
- **Boris Cherny (Anthropic)**: auto-compact dispara ~155K tokens; plan acceptance auto-clears context
- **Cat Wu (Anthropic)**: defiende auto-compact como preservador de info crítica
- **Daniel San (X)**: mantiene auto-compact OFF, hook al 80% en producción ("every time it triggered for me, I lost important context")
- **Avthar (X)**: "actively clear context yourself using /clear or /compact rather than waiting for auto-compact to happen mid-task, which can hurt performance"
- **Paweł Huryn (X)**: cache economics dominan la decisión — bug de marzo 2026 causó 20× cost inflation por cache roto

#### Convergencia de la evidencia

| Threshold | Veredicto |
|---|---|
| 50% | Demasiado agresivo. Pérdida de thread reciente, summary acumula degradación |
| **80%** | **Sweet spot**. Coinciden Daniel San, Avthar, evidencia académica con safety margin |
| 96.7% (default) | Demasiado tarde. Calidad ya degradada al disparar auto-compact |

## v3.7.0 (2026-05-05)

### Init inteligente — startup snapshot + drift detection + Setup validation

Cuatro piezas nuevas que cierran la simetría con auto-compact (v3.6.3): el SessionStart ahora captura, compara y persiste el estado inicial; el Setup hook valida invariantes antes de cualquier tool call.

#### Nuevos hooks

- **`.claude/hooks/session-startup.sh`** (wired en `SessionStart`, todos los `source ≠ compact`):
  - Captura branch, HEAD short, working tree count, archivos `.claude/` editados en últimas 24h, TODOs/FIXMEs pendientes, behaviors deshabilitados
  - Compara HEAD actual con el HEAD del último snapshot en `startup-history/` → emite "drift" line con commits-ahead
  - Escribe `.claude/session/last-startup.md` (snapshot completo) + `startup-history/<ISO>.md` (rotating, últimos 5)
  - Inyecta brief al stdout (Claude lo recibe como contexto inicial) SOLO si hay algo notable: tree dirty, recent edits, drift, behaviors off, TODOs pending. Silencioso si todo limpio
  - Silencioso en `source=compact` (delegado a `session-restore.sh`)

- **`.claude/hooks/pre-session-check.sh`** (wired en `Setup`, matchers `init` y `maintenance`):
  - Valida invariantes en `claude --init-only` / `claude --maintenance`:
    1. `settings.json` es JSON válido
    2. `block-destructive.sh` presente + ejecutable (security baseline)
    3. `behaviors/index.yaml` es YAML válido (si existe)
    4. Todos los hooks wireados existen y son ejecutables
    5. `DOTFORGE_DIR` resuelve (warn only)
  - Exit 2 bloquea session start si hay errores críticos
  - Output: silencioso en éxito, checklist completo en fallo

#### Cambios

- **`template/settings.json.tmpl`** — nuevos hooks wireados:
  - `SessionStart` agrega tercer entry: `session-startup.sh` (timeout 10s)
  - `Setup` con matchers `init` y `maintenance` apunta a `pre-session-check.sh`
- **`template/hooks/session-startup.sh`** y **`template/hooks/pre-session-check.sh`** — copias propagables a los 12 proyectos en próximo `/forge sync`
- **`domain/hook-events.md`** — documenta el wiring de dotforge en `SessionStart` (3 hooks) y `Setup` (pre-session-check). Refleja `enabled` en `index.yaml` para los 3 hooks y los matchers para Setup.

#### Verificación

Smoke tests sobre el proyecto dotforge mismo:
```
$ printf '{"source":"startup"}' | bash .claude/hooks/session-startup.sh
## Session Startup Brief
**Branch:** main @ fffc0b6
**Working tree:** 6 changed files
**Recent .claude/ edits (24h):** 14
**Behaviors disabled:** search-first,plan-before-code,objection-format

$ bash .claude/hooks/pre-session-check.sh
✓ dotforge pre-session check: all invariants pass

$ printf '{"source":"compact"}' | bash .claude/hooks/session-startup.sh
(silent — delegated to session-restore.sh)

$ # Inject broken hook reference, run check
$ bash .claude/hooks/pre-session-check.sh
── dotforge pre-session check ──
Errors (1):
  ✗ Wired hook missing: .claude/hooks/nonexistent.sh
─────────────────────────────────
exit=2
```

#### Lo que cierra de la auditoría inicial

| Pre-v3.7.0 | Post-v3.7.0 |
|---|---|
| SessionStart sólo en `compact` re-inyecta contexto | Cubre los 4 sources (startup, resume, compact, clear) |
| No detección de drift entre sesiones | `session-startup.sh` compara HEAD vs último snapshot |
| Setup hook nunca wireado pese a estar documentado | `pre-session-check.sh` valida invariantes en `--init-only` |
| No histórico de session starts | `startup-history/` rotating, último 5 |
| Sin visibilidad de behaviors disabled al arrancar | Brief incluye lista explícita |

## v3.6.3 (2026-05-05)

### Auto-compact inteligente — filtrado y histórico

Capa de filtrado encima del compact_summary que genera Claude Code. Dos mejoras concretas al pipeline existente (`PostCompact → last-compact.md → SessionStart restore`):

- **`scripts/compact-filter.py`** (nuevo) — pipe filter conservador que reduce el summary antes de persistirlo. Heurísticas seguras:
  - Bloques fenced (` ``` `) >40 líneas → primer 5 + último 5 + nota de elisión
  - Runs de ≥30 líneas no-protegidas (sin markdown structure, sin paths, sin keywords decisión/error/fix/pending) → primer 3 + último 3 + nota
  - Paragraphs duplicados ≥3 veces → 1 sola copia
  - Runs de >2 newlines consecutivos → colapso a 2
  - **Nunca filtra**: lineas con `#`/`-`/`|`/`>`/`=`, paths (`.md`/`.sh`/`.py`/etc.), tokens críticos (`decision`, `error`, `fix`, `pending`, `next step`, `commit`, `todo`, `blocker`, `warning`, `fail`), primeras 10 líneas
  - Output a stdout, métricas (in/out bytes, ratio) a stderr
  - Tests: 2253B → 730B = **68% reducción** sobre summary verbose; 22453B → 22447B = ~0% sobre summary ya denso (no daña).
- **`.claude/hooks/post-compact.sh`** + **`template/hooks/post-compact.sh`** — pipe summary por compact-filter, con fallback al raw si el filter falla. Métrica `[compact-filter]` queda en el frontmatter del checkpoint.
- **Histórico rotatorio** — últimas 5 compactaciones bajo `.claude/session/compact-history/<ISO>.md`. Permite diff entre compactaciones consecutivas o recovery si `last-compact.md` quedó stale.
- **`domain/context-window-optimization.md`** — actualizado con la nota del nuevo comportamiento del hook.

#### Verificación

Smoke test end-to-end con JSON sintético (40 líneas filler + decision + next steps):
```
[compact-filter] in=2253B  out=730B  saved=1523B  ratio=0.32
```
Sobre `last-compact.md` real de la sesión actual (22 KB de summary denso):
```
[compact-filter] in=22453B  out=22447B  saved=6B  ratio=1.00
```
Comportamiento esperado: summaries densos pasan casi sin tocar, summaries con tool dumps verbose se reducen 30-70%. **Worst case el archivo queda igual** — el filter es seguridad, no compresión agresiva.

## v3.6.2 (2026-05-05)

### Cierre de pendientes de auditoría

Aplicados los 4 pendientes registrados en v3.6.1.

- **`hooks/detect-claude-changes.sh`** — gate de señal: skip auto-stub si TOTAL < 15 archivos AND no hay cambios estructurales (agents/commands/skills = 0). Elimina ruido de inbox que el usuario no podía evaluar.
- **Métrica honesta — `not-applicable` → `informational`** en `practices/metrics.yml` (35 entradas), `skills/update-practices/SKILL.md`, `practices/active/*.md` (11 frontmatters), `practices/README.md`, `docs/config-validation.md`, `docs/internal/config-validation-flow.md`. Validation rate ahora calcula sobre 19 prácticas trackable (no sobre 54), produciendo 0/19 = 0% — métrica realista, no inflada por información general.
- **`registry/projects.yml`** — header reescrito como "EXAMPLE / REFERENCE FILE" explícito. Aclara que la fuente de verdad es `projects.local.yml` (gitignored) y por qué hay dos archivos.
- **`domain/parallel-sessions.md`** — 81 → 38 líneas. Las secciones de CLI flags no relacionadas con paralelismo migraron al nuevo **`domain/cli-flags.md`** (53 líneas), con globs distintos (`CLAUDE.md`, `agents/*`, `skills/**/SKILL.md`, `scripts/**/*.sh`, `.github/workflows/*.yml`) — cargan según contexto distinto.

#### Domain rules > 50 líneas tras este pase (8 restantes, no críticas)

| Archivo | Líneas | Sobre |
|---|---:|---:|
| rule-effectiveness.md | 68 | +18 |
| hook-architecture.md | 63 | +13 |
| auto-mode.md | 62 | +12 |
| permission-managed-settings.md | 60 | +10 |
| permission-model.md | 59 | +9 |
| agent-orchestration.md | 59 | +9 |
| context-control-patterns.md | 54 | +4 |
| cli-flags.md | 53 | +3 |
| plugin-distribution.md | 52 | +2 |
| context-window-optimization.md | 52 | +2 |

Diminishing returns: trim de wording en próxima iteración sin fragmentación adicional.

## v3.6.1 (2026-05-05)

### Auditoría crítica + pulidos de calidad

Sesión de auditoría a conciencia detectó tres degradaciones reales y se aplicaron las correcciones baratas + alto retorno.

#### Cambios

- **`behaviors/index.yaml`** — `search-first.enabled: false`. Evidencia: counter=7, escaló a `soft_block` y el usuario lo desactivó manualmente en sesión. Diseño actual (flag se consume tras cada Write/Edit) genera falsos positivos en sesiones tras compactación o con contexto ya cargado vía Read inicial. Revisitar cuando exista modo "sticky-flag".
- **Hooks generados de `search-first` removidos** — eliminados de `.claude/hooks/generated/` y de `settings.json`. PreToolUse: 8 → 6 hooks. Latencia neta menor; los hooks restantes (`block-destructive`, `no-destructive-git`, `respect-todo-state×2`, `verify-before-done×2`) siguen activos.
- **`domain/permission-model.md` dividido** — 112 líneas → 59 (core: modes, cascade, prefix detection, core rules, auto-approvals tightening, glob/grep platform note). El nuevo **`domain/permission-managed-settings.md`** (60 líneas) absorbe enterprise managed settings, MCP server config y dynamic permissions from hooks. Globs distintos (managed-settings.json, .mcp.json) → cargan sólo cuando aplican.
- **Limpieza de filesystem** — borrados 9 backups huérfanos `settings.json.bak.20260428-*` (dotforge + 8 proyectos), worktree zombi `reverent-banzai` ya no aparecía.

#### Auditoría — qué SÍ aporta valor (con evidencia)

- `block-destructive.sh`: activo en 12 proyectos, nunca desactivado, intercepta patrones nuevos (`find -delete`, `xargs rm`)
- Fix `session-report.sh` (v3.3.1): corrigió bug silencioso de 5 meses en métricas
- `tool-latency.sh`: datos llegando — Bash p50=53ms, Edit p50=11ms (hooks no son cuello de botella)
- Domain rules con globs específicos: cargan sólo cuando aplican
- `scripts/audit_all.py` + `sync_all.py` + `wire_hooks_all.py`: real automatización 12× → 1×

#### Auditoría — pendientes (no críticos)

- 8 domain rules siguen >50 líneas (propio límite). Acumular en próximo refactor sin urgencia.
- `practices/metrics.yml`: 35/54 = `not-applicable`. Métrica engañosa — "validated" debería significar "previno error", no "5 ciclos sin pasar nada". Renombrar campo a `informational` y excluir de validation rate.
- Registry shadow: `projects.yml` (committed, ejemplo) vs `projects.local.yml` (gitignored, real) — aclarar en docs.
- `inbox/*-session-changes.md` automáticos sin detalle son ruido. Filtrar en post-session hook si sólo son conteos.

## v3.6.0 (2026-05-05)

### Sync from Claude Code v2.1.120-128 — round 2 (deeper coverage)

Seven practices captured this morning from a fresh `/forge watch` pass — all incorporated. One auto-stub rejected. Inbox: 0.

#### Domain rule updates

- **`domain/hook-architecture.md`** — added `Setup` event to Session-level cadence (32 events total now). Documents `Setup` lifecycle: fires for `--init-only` / `--maintenance` runs with matchers `init` and `maintenance`, distinct from `SessionStart` (every session) — Setup only fires on explicit request. Also added design tradeoff note for `PostToolUse.updatedToolOutput`: now works for ALL tools (v2.1.121+), not just MCP — but rewriting can hide errors and breaks audit trail. Prefer `additionalContext` for augmentation; reserve `updatedToolOutput` for redaction or compression.

- **`domain/hook-events.md`** — generalized `updatedToolOutput` from MCP-only to all tools (v2.1.121+). New `Setup` event payload: matchers `init` | `maintenance`, non-blockable, used for credential rotation / env-var provisioning / prerequisite checks BEFORE session starts.

- **`domain/permission-model.md`** — added 5 managed-only enterprise fields (`allowManagedPermissionRulesOnly`, `network.allowManagedDomainsOnly`, `filesystem.allowManagedReadPathsOnly`, `strictKnownMarketplaces`, `blockedMarketplaces`) plus `pluginTrustMessage` for org-specific guidance. New **MCP server config** section consolidating `enableAllProjectMcpServers`, `enabledMcpjsonServers`, etc., with new `alwaysLoad: true` option (v2.1.121+) that bypasses tool-search deferral per server, and `workspace` reserved name (v2.1.128+).

- **`domain/rule-effectiveness.md`** — new **Runtime placeholders in skill content (v2.1.120+)** section: `${CLAUDE_EFFORT}` resolves to active effort tier in skill markdown body (not just frontmatter). New **Settings fields worth knowing (beyond permissions)** section: `availableModels`, `effortLevel`, `defaultShell`, `viewMode`, `enableWeakerNestedSandbox`, `pluginTrustMessage`.

- **`domain/parallel-sessions.md`** — `--init-only` / `--maintenance` flag now cross-references `Setup` hook (matchers `init` / `maintenance`) and points to `hook-events.md`.

#### Docs

- **`docs/usage-guide.md`** — new section **5b. CI / automation** covering `claude ultrareview [target]` non-interactive code review (v2.1.120+, exit 0/1 contract, `--json`/`--timeout` flags, GitHub Actions sketch with `claude setup-token`). Subprocess attribution note: `AI_AGENT=claude-code` auto-set in subprocesses for platforms that surface it.

- **`docs/best-practices.md`** — new **Minor tooling tips (v2.1.120-128)** subsection batching: `--plugin-dir .zip`, `claude plugin prune` / `--prune` cascade, `AI_AGENT` subprocess env, `ANTHROPIC_BEDROCK_SERVICE_TIER`, `--channels` API-key auth (`channelsEnabled: true` requirement), `workspace` reserved MCP name, `claude install [version|stable|latest]` for CI pinning.

- **`integrations/channels/README.md`** — added API-key auth note (v2.1.128+): console / API-key users must set `channelsEnabled: true`; Claude.ai sessions don't need this flag.

#### Practices

- 7 practices moved `inbox/ → active/`, frontmatter `incorporated_in: ['3.6.0']`.
- 1 rejected (`invisigtht-session-changes` — auto-stub, summary-only).
- Inbox: 0 pending.
- `metrics.yml`: 1 new `monitoring` (posttooluse-updated-output-all-tools — error_type=logic), 6 `not-applicable`.

## v3.5.0 (2026-05-05)

### Sync from Claude Code v2.1.120 → v2.1.128 + agent memory checklist

Six practices incorporated. Three security-relevant (`monitoring`), one auto-stub rejected.

#### New domain rule

- **`.claude/rules/domain/plugin-distribution.md`** — covers `${CLAUDE_PLUGIN_DATA}` (v2.1.126+ persistent state for plugins surviving updates), `CLAUDE_CODE_PLUGIN_SEED_DIR` multi-dir layered overlays (base + corporate + personal), managed marketplace governance (`strictKnownMarketplaces`, `blockedMarketplaces`, `allowManagedPermissionRulesOnly`, `pluginTrustMessage`), reserved server names (`workspace` since v2.1.128), and lifecycle hygiene (`claude plugin prune`, `--plugin-dir .zip`).
- Migration of dotforge's `practices/metrics.yml` and `inbox/` to `${CLAUDE_PLUGIN_DATA}` is documented as a candidate but explicitly out of scope this release (multi-commit work).

#### Skill / docs / agent updates

- `skills/reset-project/SKILL.md` — new Step 5b suggesting `claude project purge $PWD` post-reset (v2.1.126+) to drop orphaned transcripts, task lists, and `~/.claude.json` entry. Verifies CLI availability before suggesting; never runs automatically.
- `docs/usage-guide.md` — new "Layered distribution (multi-seed)" subsection covering `CLAUDE_CODE_PLUGIN_SEED_DIR` overlay pattern; new "PR review flow tip" noting `/resume` accepts pasted PR URLs (v2.1.122+, GitHub/Enterprise/GitLab/Bitbucket).
- `docs/security-checklist.md` — new "`--dangerously-skip-permissions` tradeoffs (v2.1.121+)" subsection documenting that the flag now bypasses prompts for `.claude/skills,agents,commands` writes, with explicit warning against pairing with prompts that include unverified content (injection vector that can now write to template files unprompted).
- `agents/{architect,code-reviewer,implementer,security-auditor}.md` — appended a "Memory persistence" section to each agent prompt with concrete checklist on when (and when not) to write to `.claude/agent-memory/<agent>.md`. Targets the `agent-memory-underused` finding from `/forge insights` 2026-04-21 (≤2 entries per agent across 5 months).

#### Practices

- 6 practices moved `inbox/ → active/`, frontmatter `incorporated_in: ['3.5.0']`.
- 1 rejected (`tradingbot-session-changes` — auto-stub, summary-only).
- Inbox: 0 pending.
- `metrics.yml`: 4 new `monitoring` entries (plugin-data-variable, claude-project-purge, skip-permissions-claude-paths, agent-memory-underused), 2 `not-applicable`.

#### Verified against

- Claude Code v2.1.128 (latest as of 2026-05-04). Watch-upstream pass surfaced additional v2.1.120-128 deltas captured for next cycle (PostToolUse.updatedToolOutput for all tools, Setup hook event, alwaysLoad MCP option, claude ultrareview, ${CLAUDE_EFFORT} placeholder, missing settings fields).

## v3.4.1 (2026-04-27)

### New rule — `stacks/trading/rules/backtesting-adr-gate.md`

Captured from a real ADR retrospective in the `tradingview` repo: a "Dual Momentum SPY/QQQ/BIL 12m" strategy was declared the official baseline of the passive-US sleeve based on walk-forward OOS Sharpe 1.08 vs QQQ B&H 1.04 (delta = +0.04) and Calmar 2.78 vs 1.66. After fixing a look-ahead bug in the rebalancer, the OOS metrics deflated to 1.06 vs 1.04. Computing **PSR(QQQ B&H)** per Bailey & López de Prado (2012) for all 9 strategies tested in the repo showed **none passed the 0.95 threshold** — the "best" strategy gave 70% probability of beating B&H, i.e. 30% probability of being worse.

The new rule encodes:

- **PSR(benchmark) > 0.95** required to claim "baseline", "winner", or "supersedes" in any ADR
- **DSR (Deflated Sharpe Ratio)** required when testing > 5 strategies in the same project (multiple-testing correction)
- Below threshold: ADR may document the strategy as alternative, but must not use the strong words
- Implementation: ~50 lines stdlib-only via `statistics.NormalDist`; no scipy needed

Generalization beyond trading: when ranking N options by a noisy metric, compute Pr(top option genuinely better than alternatives). Below threshold, the ranking is decoration — don't anchor decisions on it.

#### Changed

- `stacks/trading/plugin.json`: bumped to v2.1.0, components.rules now lists both rules.
- `practices/active/2026-04-27-psr-gate-baseline-adrs.md`: incorporated_in `['3.4.1']`.
- `metrics.yml`: monitoring entry, error_type=logic.

#### Inbox processing

- 1 accepted (psr-gate-baseline-adrs → above)
- 1 rejected (tradingview-session-changes — auto-stub, summary-only)
- 1 deferred (agent-memory-underused — low-priority, needs more usage data to evaluate)

## v3.4.0 (2026-04-26)

### `/forge watch` sync from CHANGELOG v2.1.92 → v2.1.119

Twelve upstream practices incorporated from the 2026-04-26 watch pass plus two older inbox items. Domain rules refreshed against the live docs at code.claude.com.

#### Domain rule updates

- `domain/hook-architecture.md` — bumped event count to 33+; added `UserPromptExpansion` (blockable, slash command expansion) and `PostToolBatch` (blockable, end-of-batch validation). Added `mcp_tool` as a fifth hook type with `${tool_input.*}` substitution (v2.1.118+).
- `domain/hook-events.md` — `PostToolUse`/`PostToolUseFailure` now carry `duration_ms` (v2.1.119+). `UserPromptSubmit` can return `hookSpecificOutput.sessionTitle` to set the session title (v2.1.94+).
- `domain/auto-mode.md` — added the `"$defaults"` placeholder pattern for `autoMode.allow|soft_deny|environment` (v2.1.118+); flagged that native macOS/Linux builds fold `Glob`/`Grep` into `Bash` (v2.1.117+).
- `domain/permission-model.md` — documented the v2.1.113 tightening of `Bash(find:*)` (no longer auto-approves `-exec`/`-delete`), exec-wrapper deny matching (`env`, `sudo`, `watch`, `ionice`, `setsid`), and `/private/{etc,var,tmp,home}` as dangerous removal targets on macOS. Added v2.1.119 PowerShell auto-approval and `cd <project-dir> && ...` no-prompt rule. Noted that `Glob(...)`/`Grep(...)` permission specifiers are platform-dependent.
- `domain/context-control-patterns.md` — added TUI rendering modes (`tui` setting, `/tui`, `autoScrollEnabled`) and idle-return recap (`/recap`, `awaySummaryEnabled`, `CLAUDE_CODE_ENABLE_AWAY_SUMMARY`). Documented coexistence with `last-compact.md` (different problems: idle-return vs compaction-survival).
- `domain/parallel-sessions.md` — extended the headless flags table with `--input-format`, `--include-partial-messages`, `--strict-mcp-config`, `--system-prompt[-file]`, `--append-system-prompt[-file]`, `--tools`/`--allowedTools`/`--disallowedTools`, `--debug-file`. New "Other CLI flags (interactive)" subsection and a "CLI subcommands" section covering `claude install`, `auth`, `agents`, `auto-mode`, `remote-control`, `setup-token`.

#### Other updates

- `_common.md` — Git section now mentions `attribution.commit`/`attribution.pr` (deprecates `includeCoAuthoredBy`) and `prUrlTemplate` for self-hosted Git hosts.
- `docs/claude-vs-forge.md` — `/cost` and `/stats` are typing shortcuts since v2.1.118; `/usage` is the canonical command.
- `behaviors/verify-before-done/behavior.yaml` — extended the test-runner regex to recognize `bash tests/*.sh`, `bash <path>/test-*.sh`, and `./tests/*.sh` patterns. Fixes `git push` from dotforge being soft-blocked despite legitimate `bash tests/test-*.sh` runs.
- `audit/checklist.md` item 14 — scoring now requires ENFORCEMENT (compiled hooks under `.claude/hooks/generated/` AND a `settings.json` reference), not just `behaviors/index.yaml` declaration. Closes the false-positive that scored projects 1/1 with no runtime effect.

#### Notes

- `template/hooks/session-report.sh` was NOT edited despite the `duration_ms` practice listing it: that's a Stop-event hook with no tool payload. The right home is a future PostToolUse `tool-latency.sh` that buffers per-tool durations to a file. Documentation update in `domain/hook-events.md` covers the field for now.
- The built-in `/less-permission-prompts` skill (Claude Code v2.1.111+) overlaps with `skills/fewer-permission-prompts/` if installed at user scope. dotforge does not ship that skill — flagged here for users who do.

#### Inbox lifecycle

- 12 new upstream-watch practices (2026-04-26) → `active/`
- 2 older inbox items → `active/`: `audit-item-14-false-positive-behavior-not-compiled`, `verify-before-done-regex-missing-bash-tests`
- 6 auto-generated `*-session-changes` captures rejected (no actionable content)
- 1 deferred: `agent-memory-underused` tagged `needs-more-info` for cross-project investigation

## v3.3.1 (2026-04-21)

### Fix — `session-report.sh` writes malformed JSON (5-month silent bug)

Discovered via `/forge insights`: every JSON file under `~/.claude/metrics/<slug>/*.json` across all 12 registered projects was malformed. 54 corrupt files total, dating back to 2026-03-22 — the Stop-event session-report hook had been silently corrupting metrics for ~5 months. `/forge insights` silently degraded to retroactive git-log analysis.

**Root cause (two compounding bugs)**:

1. **`grep -c ... || echo "0"` idiom** (3 occurrences in the hook): GNU `grep -c` returns count `"0"` with exit code `1` when no match. `||` then fires and echoes `"0"` again — stdout becomes `"0\n0"`, producing multi-line JSON values like `"errors_added": 0\n0,`.

2. **Cascade via malformed previous file**: once today's metrics file is malformed, `PREV_SESSIONS=$(jq -r '.sessions // 0' "$METRICS_FILE")` returns empty string on the corrupt file. `SESSIONS=$((PREV_SESSIONS + 1))` throws arithmetic error, `SESSIONS` stays empty → next write emits `"sessions": ,`. Corruption compounds on every new session.

**Fix**:

- `template/hooks/session-report.sh` and `.claude/hooks/session-report.sh` — replace `grep -c ... || echo "0"` with separated capture + `${var//[!0-9]/}` sanitization + `${var:-0}` default. Added `_jq_num()` helper that validates numeric output before arithmetic. Pre-validate the previous file with `jq -e .` before attempting the merge — if malformed, restart cleanly from `SESSIONS=1`.
- New `scripts/fix-session-metrics.sh` — propagator that detects the old idiom in each project's hook and replaces it, preserves the project's original shebang, and deletes existing malformed JSON files. Idempotent, safe to re-run.

**Applied this release**:

- 9 projects patched: InviSight-iOS, TRADINGBOT, cotiza-api-cloud, openclaw, vault-bot, SOMA2, cds-dashboard, jira-nbch, crm.
- 1 project already clean: dotforge (fixed in-repo before release).
- 2 projects skipped: derup, SOMA (no `session-report.sh` — predate the template).
- 54 malformed JSON files deleted. Next session in each project writes valid metrics from a clean slate.

Practice: `session-report-malformed-json` → `active/`, `metrics.yml` marked `monitoring`.

## v3.3.0 (2026-04-21)

### MEDIUM-priority sync from 2026-04-21 `/forge watch` pass

Six practices incorporated from the inbox. Two are security-relevant (`status: monitoring`), four are documentation drift.

#### Domain rule updates

- `domain/hook-architecture.md` — clarified: `if` field is evaluated **only** on tool events (PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest). Silently ignored elsewhere — writing `if: "Bash(git *)"` on `Stop` or `SessionStart` hooks is a no-op filter. Verified tag bumped v2.1.108 → v2.1.114.
- `domain/sandboxing.md` — added `network.deniedDomains` (v2.1.113+, overrides `allowedDomains` wildcards for specific hosts) and new **Subprocess env-scrub and PID isolation** section covering `CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` (v2.1.83+) and Linux PID-namespace subprocess sandboxing (v2.1.98+).
- `domain/context-control-patterns.md` — `Ctrl+O` no longer toggles focus view; it's verbose transcript only. Added `/focus` as the v2.1.110+ focus-view command.
- `domain/workflow-automation.md` — new **Routines vs /schedule vs Desktop scheduled tasks** section disambiguating the three cron-like primitives.
- `domain/parallel-sessions.md` — new **Automation / headless flags** section: `--effort`, `--max-budget-usd`, `--max-turns`, `--json-schema`, `--fallback-model`, `--no-session-persistence`, `--include-hook-events`, `--replay-user-messages`, `--exclude-dynamic-system-prompt-sections`, `--init-only`, `--maintenance`.

#### Integrations

- New `integrations/channels/README.md` documenting first-party **Channels** (v2.1.83+) as the native push-integration route, with a decision matrix comparing against OpenClaw. Clarifies when to use each.

#### Practices

- 6 practices moved `inbox/ → active/`, frontmatter `incorporated_in: ['3.3.0']`.
- `metrics.yml`: 2 new `monitoring` entries (`hook-if-field-tool-events-only`, `sandbox-denieddomains-and-env-scrub`), 4 `not-applicable`.

## v3.2.0 (2026-04-21)

### Security hardening — `block-destructive.sh`

Added `find`/`xargs` destruction patterns to the `standard` profile. Pre-v2.1.113, Claude Code core auto-approved `Bash(find:*)` allow rules for `find -exec`/`-delete`; v2.1.113 fixed that gap in core. This commit closes the same gap in the hook layer so `auto` and `bypassPermissions` modes (where core permission checks are relaxed) still block destructive find/xargs invocations:

- `find .* -delete`
- `find .* -exec rm`
- `find .* -exec unlink`
- `xargs[^|]*rm -rf`
- `xargs[^|]*rm -f`

Smoke-tested against 6 variants including `find / -delete`, `find /tmp -exec rm -rf {} \;`, `find . | xargs rm -rf`, and `find / | xargs -I{} rm -rf {}` — all now blocked. Pre-existing `rm -rf /` pattern already catches `sudo rm -rf /`, `env rm -rf /`, `watch rm -rf /` via full-string grep, so wrapper-bypass (v2.1.113 core fix) does not require hook changes.

### Domain knowledge sync — Claude Code v2.1.108 → v2.1.114

Watch-upstream pass against `code.claude.com/docs`. Six practices accepted from the inbox, seven auto-stub session-changes captures rejected.

#### Domain rule updates

- `domain/model-ids.md` — opus tier model ID **`claude-opus-4-6` → `claude-opus-4-7`** (v2.1.111). New `xhigh` effort level documented between `high` and `max` (Opus 4.7-exclusive; other tiers fall back to `high`). Recommends `xhigh` for `security-auditor`/`architect` on complex tasks before escalating to `max`.
- `domain/auto-mode.md` — research-preview hedging removed; auto mode is GA. `--enable-auto-mode` flag removed in v2.1.111 (use `permissions.defaultMode: "auto"` or `--permission-mode auto`). Max-subscriber + Opus 4.7 tier gate noted.
- `domain/rule-effectiveness.md` — added `xhigh` to effort values. New frontmatter field `disable-model-invocation: boolean` documented (v2.1.111+) for gating commands after v2.1.108 made slash commands model-invocable. Skill description cap updated 250 → **1,536 chars** (v2.1.105).
- `domain/permission-model.md` — security note on `updatedInput` recheck (v2.1.110+): mutated tool input is re-validated against `permissions.deny` before execution. Pre-v2.1.110 a hook could bypass denies via mutation.
- `domain/context-window-optimization.md` — new **Prompt cache TTL** section: `ENABLE_PROMPT_CACHING_1H=1` opt-in for 1h TTL (v2.1.108+), `FORCE_PROMPT_CACHING_5M` counterpart, cost tradeoff notes.
- `domain/workflow-automation.md` — cadence heuristic annotated with 1h-TTL extension from `ENABLE_PROMPT_CACHING_1H`.
- `domain/agent-orchestration.md` — new **Model self-invocation of slash commands** section (v2.1.108+). Recommends `disable-model-invocation: true` on destructive commands (`reset`, `unregister`, `capture`) to stay user-gated.

#### Practices

- 6 practices moved `inbox/ → active/`, frontmatter `incorporated_in: ['3.2.0']`.
- 7 auto-stub session-changes captures rejected (machine-generated, summary-only, no actionable content).
- `metrics.yml` tracks two as `status: monitoring` (security-relevant): `model-invokes-slash-commands`, `permission-request-updatedinput-deny-recheck`. Rest are `not-applicable`.

## v3.1.2 (2026-04-20)

### Close the SSH/VPS persistence loop

Problem: Claude forgot SSH connection info (Host/User/Key/AppDir/DeployCmd) across sessions in projects that deploy to VPS (TRADINGBOT → Oracle Free Tier, jira-nbch → internal host). `hooks/post-compact.sh` captured hosts into `session/last-compact.md`, but that file is ephemeral — it only re-injects after compaction, not after `/clear` or a fresh session. Users had to re-teach the same connection details every session.

Root cause: `domain-learning.md` had triggers for business rules and external APIs but nothing for remote-host usage. `learn-project` scanned imports, not shell scripts or `~/.ssh/config`. No stack existed between `docker-deploy` (Compose-only) and the bare-metal VPS reality.

#### Changes

- New stack **`vps-ssh`** — `rules/infra.md` conventions, `ssh`/`scp`/`rsync` permissions, deny rules for `id_*`/`key`/`ed25519`/`rsa` private keys
- `stacks/detect.md` — detects shell scripts containing ssh/scp/rsync or `~/.ssh/config` hosts matching project name
- `domain-learning.md` (template + dotforge's own) — explicit SSH trigger: first ssh/scp/rsync call persists Host/User/Key/AppDir/DeployCmd into `domain/infra.md`, with explicit warning that `last-compact.md` is not a substitute
- `learn-project` Step 4b — scans `*.sh`/Makefile/CI for ssh/scp/rsync and reads `~/.ssh/config` aliases to propose `domain/infra.md`
- `init-project` — optional Step 3.5 "SSH/VPS connection?" installs `vps-ssh` stack and scaffolds `domain/infra.md`

Security: `infra.md` stores `IdentityFile` paths only, never key content. `~/.ssh/config` is never modified without explicit user confirmation.

Propagation: existing projects recover via `/forge learn`. New projects get the prompt via `/forge init`.

## v3.1.1 (2026-04-15)

### Fix — `showThinkingSummaries` was misdocumented

`domain/auto-mode.md` described `showThinkingSummaries` as if toggling it had operational meaning. Per `code.claude.com/docs/en/settings`, the flag is **purely cosmetic** — it controls visibility of thinking blocks (collapsed stub vs full summary) but does NOT change what the model generates or what gets billed. Headless mode (`-p`) and SDK callers always receive summaries regardless.

Also added missing entry for `alwaysThinkingEnabled` — the actual cost knob for extended thinking. Cross-referenced effort levels and `thinking_budget` as alternatives for trimming spend without fully disabling.

No runtime impact. Domain rule clarification only.

## v3.1.0 (2026-04-15)

### Domain knowledge sync — Claude Code v2.1.108

Watch-upstream pass against `code.claude.com/docs` (covers v2.1.70 → v2.1.109). Eight practices accepted, three rejected (auto-stubs).

#### Domain rule updates

- `domain/hook-architecture.md` — events count corrected 27 → **31**, restructured around three lifecycle cadences (session-level, turn-level, tool-loop, async/side). Added `InstructionsLoaded` (with `load_reason` field), `Elicitation`/`ElicitationResult`, and `PreCompact` blockability since v2.1.105.
- `domain/hook-events.md` — `PreCompact` flagged as blockable, `InstructionsLoaded` payload documented, new MCP elicitation events section.
- `domain/permission-model.md` — new sections: **Enterprise managed settings** (`managed-settings.d/`, `allowManagedHooksOnly`, `allowedChannelPlugins`, `forceRemoteSettingsRefresh`) and **Dynamic permissions from hooks** (`addRules`/`replaceRules`/`removeRules`/`setMode`/`addDirectories`/`removeDirectories` via `hookSpecificOutput.decision.updatedPermissions`).
- `domain/model-ids.md` — documented v2.1.94 default effort change `medium → high`. Recommends pinning `effort: low` on `researcher`/`test-runner` agents.

#### Template

- `template/settings.json.tmpl` — added `ask:` permission list (18 entries) covering risky-but-legitimate commands: `rm *`, `chmod *`, `npm/pip install/uninstall`, `docker run`, `kubectl apply/delete`, `gcloud`/`aws`/`terraform apply/destroy`, `git push/rebase/cherry-pick`. Bridges the gap between unrestricted `allow:` and total `deny:`.
- `template/hooks/block-destructive.sh` — added compound-bash safety verification block. Hook is **not vulnerable** to the v2.1.98 bypass class (the Claude Code core fix was about its own permission rule prefix matching; this hook uses `grep -qiE` over the full command string and catches `ls && rm -rf /`-style compound forms by design). Documented known limitations: indirect execution (`eval $(curl)`, `bash <(curl)`), encoded payloads, hostile env vars — defense-in-depth via `sandbox.enabled`.

#### Practices

- 8 practices moved `inbox/ → active/`, frontmatter `incorporated_in: [v3.1.0]`.
- 3 auto-stub session-changes practices rejected (no actionable content).

## v3.0.4 (2026-04-14)

### Skills catalog — `skills/index.yaml` + CI validation

First concrete step toward the unified catalog proposal. SKILL.md frontmatter remains the source of truth for name/description/invocation; this index adds machine-readable enumeration, functional categorization, and target scope metadata to support discoverability and automation tooling.

#### New files

- `skills/index.yaml` — schema v1. Catalogs all 19 dotforge skills with `id`, `category` (lifecycle/analysis/practices/domain/export/integrations/scouting/governance), and `target` (project/global/both/external).
- `tests/test-skills-index.sh` — validator. Enforces schema_version, required fields, closed category/target sets, no duplicate ids, and the consistency invariant: every `skills/<id>/` dir must appear in the index, and every index entry must have a matching `SKILL.md`. Uses python3+yaml. Local run: `PASS: 19 skills validated`.
- CI: new `Validate skills/index.yaml consistency` step in `.github/workflows/ci.yml`, runs alongside the existing skill completeness check.

#### Why this first

Catalogs for behaviors (`behaviors/index.yaml`), practices (`practices/metrics.yml`), and registry (`registry/projects.yml`) already exist. Skills were the largest uncatalogued surface — 19 entries with no machine-readable index and no validation beyond "SKILL.md exists". This release closes that gap. Plugins (installed via `claude plugin`) remain out of scope for now — they are managed by Claude Code's own plugin system, not dotforge.

### Cleanup — pre-existing leaked session captures

Deleted 8 untracked `practices/inbox/*-session-changes.md` files from the working tree that were generated by the pre-hardening `detect-claude-changes.sh` and contained raw filenames, session UUIDs, and path-encoded usernames. The 3 tracked ones from 2026-04-08 are lower-severity (no username leaks, just `.claude/` relative paths) and are left for normal `/forge update` processing.

---

## v3.0.3 (2026-04-14)

### Security hardening — post-session capture sanitization

Complements v3.0.2 release-hygiene work. Driven by a Codex adversarial review of the v3.0.1 working tree; v3.0.2 addressed 7 release-hygiene findings including `block-destructive.sh` fail-closed behavior, and explicitly left `.vscode/` and `practices/inbox/*` out of scope. This release closes those two remaining gaps.

#### `.vscode/` added to `.gitignore`

`.vscode/settings.json` with `claudeCode.initialPermissionMode: "bypassPermissions"` was sitting untracked in the repo. One accidental `git add .` away from shipping a no-prompt execution mode to everyone who clones dotforge. Now explicitly ignored alongside `.idea/`. Also added to `.gitignore`: `.claude/sessions/`, `.claude/session-env/`, `.claude/projects/`, `.claude/metrics/`, `.claude/plugins/`, `.claude/mcp-*cache*.json` — all machine-local runtime state that was previously only partially covered.

#### `hooks/detect-claude-changes.sh` hardened

The post-session Stop hook that auto-generates `practices/inbox/<project>-session-changes.md` was emitting raw filenames of the originating project. Pre-existing inbox entries demonstrated the leak: session UUIDs, path-encoded usernames (Claude Code's `.claude/projects/-Users-<name>-Documents-GitHub-<project>/` convention), foreign project domain-rule names, and auth cache filenames all made it into markdown files destined for git.

Three layers of defense, all fail-closed:

1. **Path exclusion** before counting: drops `.claude/sessions/`, `session-env/`, `projects/`, `metrics/`, `plugins/`, `worktrees/`, `*cache*.json`, `settings.local.json`, `.forge-manifest.json`.
2. **Category summary instead of filenames**: the inbox entry now reports counts per top-level category (`agents: N`, `rules: N`, etc.) and nothing else. Rule names, hook names, and skill names no longer leak.
3. **Secret-prefix scan** on sanitized filenames, regex list adapted from `NousResearch/hermes-agent/agent/redact.py`: `sk-`, `ghp_`, `github_pat_`, `gh[ours]_`, `xox[baprs]-`, `AIza`, `AKIA`, `sk_live_`, `sk_test_`, `SG.`, `hf_`, `r8_`, `npm_`, `pypi-`, `dop_v1_`, `tvly-`, `exa_`, `gsk_`, `pplx-`, `fal_`, `fc-`, `bb_live_`. Any match → no inbox entry is written at all.

Validated end-to-end against a synthetic project tree reproducing the Codex findings: 6 sensitive files excluded, 6 normal files counted by category, zero filenames in output. Fail-closed verified with a secret-looking filename (`sk-abc123def456.md`) — hook exited 0 without writing.

#### Not addressed in this release

- The 11 pre-existing untracked `*-session-changes.md` files in `practices/inbox/` still contain the leaked filenames. Deleting or redacting them is a pipeline decision, not a hook fix — they can be processed by the next `/forge update` and discarded.
- Full structured storage for practices/session captures (SQLite/JSONL) remains a medium-priority future item, not blocked by this fix.

---

## v3.0.1 (2026-04-13)

### Domain knowledge expansion — scout against official docs

Non-breaking, docs + audit + domain-rules only. No runtime behavior changes, no template changes to existing projects. Driven by `/forge watch` against `code.claude.com/docs/en` on 2026-04-13, seeded by a scout of `shanraisshan/claude-code-best-practice`.

#### New domain rules

- `.claude/rules/domain/sandboxing.md` — OS-level bash sandbox (`sandbox.*` in settings.json). Filesystem/network kernel-enforced isolation on macOS/Linux/WSL2. Complementary to `allow`/`deny`/`ask` and `block-destructive.sh`. Interaction with `autoAllowBashIfSandboxed` documented.
- `.claude/rules/domain/parallel-sessions.md` — top-level session parallelism, distinct from subagent delegation. Worktrees (`-w`, `--tmux`), session handoff (`--fork-session`, `--teleport`, `--remote`, `--from-pr`), fast-start flags (`--bare`, `--add-dir` with the `.claude/skills/` exception, `--agent`, `--agents` inline JSON, `--setting-sources`, `--teammate-mode`).
- `.claude/rules/domain/workflow-automation.md` — decision patterns for `/loop`, `/schedule`, `/batch`. Cache-aware cadence heuristics (<5min stays cached, 20–30min sweet spot idle). Anti-patterns: no `sleep N` polling, no stop-less loops.
- `.claude/rules/domain/context-control-patterns.md` — user-facing context hygiene: `/btw` ephemeral side queries, skill re-attachment budget (25K combined, 5K per skill post-compaction), `SLASH_COMMAND_TOOL_CHAR_BUDGET`, manual pruning (`Esc+Esc`, `Ctrl+X Ctrl+K`, `Ctrl+O`).

#### Domain rule refactors

- `context-window-optimization.md` — split to stay under the 40-line soft budget. Runtime details (compaction tiers, window sizes, tool result limits) stay here; user patterns moved to `context-control-patterns.md`. Cross-ref added.
- `agent-orchestration.md` — new "Related: top-level parallelism" section pointing to `parallel-sessions.md`.
- `permission-model.md` — cross-ref to `sandboxing.md` for OS-level defense-in-depth.

#### Audit

- New item **15. OS-level sandboxing** (recommended, 0-1): detects `sandbox.enabled` with `filesystem.*` or `network.allowedDomains` restrictions. Auto-passes projects with no secret indicators (`.env*`, `*.key`, `*.pem`, `credentials*`, cloud CLI refs). Not applicable on Windows native.
- `audit/checklist.md` recomendado total: 9 → 10 items.
- `audit/scoring.md` formula updated: `score_recomendado = sum(items 6-15)`, divisor `3.0 / 10`. Each recommended item contributes 0.3 — 7+ needed to reach score 9.
- `audit/score.sh`: adds `s15` computation via python3 JSON parse + secret-indicator scan. Validated end-to-end against dotforge itself (scores 9.00 — item 15 correctly flags the repo as handling secrets without sandbox enabled).
- `CLAUDE.md`: audit description updated — 12 → 15 items.

#### Verified against official docs (2026-04-13)

CLI flags and settings confirmed in `code.claude.com/docs/en/cli-reference`, `/settings`, `/interactive-mode`, `/skills`:

- **CLI flags:** `--bare`, `--add-dir`, `--agent`, `--agents`, `--worktree`/`-w`, `--fork-session`, `--teleport`, `--remote`, `--chrome`, `--effort`, `--tmux`, `--teammate-mode`, `--setting-sources`, `--from-pr`
- **Slash commands:** `/btw` (side queries, ephemeral, no tools, reuses parent cache), `/batch` and `/loop` (bundled skills alongside `/simplify`, `/debug`, `/claude-api`)
- **Settings:** full `sandbox.*` block with filesystem/network subkeys, `enableWeakerNetworkIsolation`, `enableWeakerNestedSandbox`
- **Env vars:** `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS`, `CLAUDE_CODE_TASK_LIST_ID`, `SLASH_COMMAND_TOOL_CHAR_BUDGET`, `CLAUDE_CODE_SIMPLE` (set by `--bare`)
- **Corrected misattribution:** `/voice` is NOT a slash command — voice input is push-to-talk via `Hold Space`. The scout digest had this wrong; captured in the inbox.

#### Practices inbox

- Added `2026-04-13-granular-ask-permissions.md` — captures the granular `ask:` permission pattern from shanraisshan's settings.json for future evaluation as a `strict` profile option.
- Added `2026-04-13-boris-cherny-tips-scout.md` — digest of 54 Boris Cherny tips across 6 posts, with verification trail. 5 gaps (G1, G2, G3, G4, G5) incorporated into domain rules; G7 (Chrome extension stack notes) remains for future sessions.

---

## v3.0.0 (2026-04-13) — RELEASE

### Behavior Governance (v3 new layer)

dotforge v3 ships a runtime behavior governance layer on top of the existing v2.9 configuration layer. Behaviors are declarative policies on tool calls, compiled to `PreToolUse` hooks that share a session-scoped state file. Opt-in and non-breaking: existing v2.9 projects are untouched unless they create `behaviors/` and wire the generated hooks into `settings.json`. See [`docs/v3/MIGRATION.md`](v3/MIGRATION.md).

#### Spec of record

- `docs/v3/SPEC.md` — evaluation algorithm, 5-level enforcement table (silent, nudge, warning, soft_block, hard_block)
- `docs/v3/SCHEMA.md` — `behavior.yaml v1` shape, closed DSL, validation rules
- `docs/v3/RUNTIME.md` — `state.json` format, mkdir-based locking, TTL, flag semantics, reinvocation override detection
- `docs/v3/AUDIT.md` — `overrides.log` format and exposed metrics
- `docs/v3/COMPILER.md` — behavior → hook generation rules
- `docs/v3/SCOPE.md` — Phase 0–3 milestones
- `docs/v3/DECISIONS.md`, `docs/v3/COMPETITIVE.md` — design rationale
- `docs/v3/MIGRATION.md` — v2.9 → v3 upgrade path (new in 3.0.0)

#### Runtime (Phase 1)

- `scripts/runtime/lib.sh`: session counter, flags (set/consume/keep), level resolution, mkdir-based lock, TTL 24h, pending_block reinvocation detection, per-session behavior override, audit log append
- `.forge/runtime/state.json`: per-session counters, flags, effective_level, behavior_overrides, pending_block. Gitignored, machine-local
- `.forge/audit/overrides.log`: permanent JSONL audit trail of soft_block overrides. Committed to git
- 8 runtime unit tests green (locking, TTL, counter, flags, corruption recovery, stale lock, pending_block)

#### Compiler (Phase 1 + 2)

- `scripts/compiler/compile.sh`: reads `behavior.yaml`, emits one bash hook per trigger into an output dir, plus a `settings.json` snippet for registration
- Supported actions: `evaluate`, `set_flag`, `check_flag` with `on_present: consume|keep` and `on_absent: skip|violate`
- **Phase 2**: conditions enforced at runtime via embedded python regex. Supported operators: `regex_match`, `contains`, `not_contains`, `equals`, `starts_with`, `ends_with`, `exists`, `not_exists`, numeric `gt/lt/gte/lte/equals`
- **Phase 2**: UserPromptSubmit and Stop triggers can read top-level payload fields (e.g., `.prompt`) in conditions — compiler merges them into the condition context
- **Phase 2**: `_bash_sq_escape` reimplemented via `python3` — previous bash parameter-expansion version produced 7 chars per apostrophe instead of 4

#### Behavior catalogue (Phase 2)

**Core** (enabled by default in `behaviors/index.yaml`):

- `no-destructive-git` — hard_block on `git push --force`, `git reset --hard`, `git clean -f`, `git branch -D`. No override.
- `search-first` — flag-based: `Grep|Glob|Read` sets the flag, `Write|Edit` consumes it. Absence escalates silent → nudge → warning → soft_block.
- `verify-before-done` — flag-based: test/build commands (pytest, npm test, go test, cargo test, vitest, jest, ruff, mypy, tsc, eslint, …) set verification credit; `git push` consumes it. Unverified pushes escalate.
- `respect-todo-state` — flag-based: `TaskUpdate` grants credit, `TaskCreate` consumes it. Each create without prior update escalates.

**Opinionated** (opt-in via `enabled: false`):

- `plan-before-code` — requires an `ExitPlanMode` call before writing source files (regex on `file_path`). Non-source files exempt.
- `objection-format` — detects friction markers in user prompts ("no", "stop", "don't", "revert", "wait", …) and nudges the agent to reflect before continuing.

Each behavior directory contains `behavior.yaml` + `tests/` with per-scenario integration tests.

#### CLI (Phase 1 + 2)

- `/forge behavior status [--session SID]` — show project index + per-session counters, effective levels, overrides
- `/forge behavior on|off <id> [--project | --session SID]` — toggle in index.yaml (persistent) or state.json (ephemeral, per-session, survives `/clear` via `scope: session`)
- `/forge behavior strict|relaxed <id>` — halve or double escalation thresholds in `behavior.yaml`
- **Phase 2**: `/forge behavior list [--category core|opinionated|experimental]` — tabular catalogue with on/off state, category, name
- **Phase 2**: `/forge behavior describe <id>` — full policy dump: triggers, enforcement, escalation, recovery hint, runtime status

#### Audit integration (Phase 2)

- `audit/score.sh` item 14 "Behaviors coverage" (0-1): scores 1 when `behaviors/index.yaml` has ≥1 enabled behavior, OR compiled hooks exist under `.claude/hooks/generated/`, OR `settings.json` references behavior hooks
- `audit/checklist.md` updated: recomendado section now sums to 9 (was 7); weight rebalanced in the normalization step to `REC * (3 / 9)`
- Dimension does NOT apply the security cap — absence is neutral, not penalized

#### Testing

Phase 2 suite: **33 tests green** (up from 18 in Phase 1 alpha).

- runtime: 8
- compiler: 1
- CLI: 5 (adds `test_list_describe.sh`)
- search-first: 5
- no-destructive-git: 2
- verify-before-done: 3
- respect-todo-state: 2
- plan-before-code: 3
- objection-format: 2

#### Breaking changes

**None.** v3 is purely additive. A v2.9.1 project upgraded to v3.0.0 continues to work with zero changes until the user explicitly creates `behaviors/` and wires the compiled hooks into `settings.json`.

---

## v2.9.1 (2026-04-08)

### Practices Pipeline Update

- Evaluated 17 inbox practices: 5 accepted, 12 rejected (session-changes not generalizable)
- Incorporated: `defer` permission hook detail → hook-events.md
- Incorporated: plugin `bin/` executable convention → hook-architecture.md
- Confirmed already-incorporated: `disableSkillShellExecution`, `forceRemoteSettingsRefresh`, MCP 500K override
- Inbox cleared: 0 pending (was 17)
- Active practices: 13 (was 8)
- Metrics: 13 tracked practices in metrics.yml (was 8)

---

## v2.9.0 (2026-04-05) — RELEASED

### Hardening + Portability + Upstream Alignment + E2E Validated

#### Reliability Fixes (Codex Review)
- Fix: `audit/score.sh --json` — triple-quote Python heredoc + true/false → sanitized strings + True/False; lint-*.sh detection fixed; agent-memory .gitkeep accepted as valid presence check; JSON output sanitized
- Fix: `check-updates.sh` — manifest path `.forge-manifest.json` → `.claude/.forge-manifest.json`
- Fix: `detect-stack-drift.sh` — reads stacks from manifest file sources (was reading nonexistent `stacks` field)
- Fix: `detect-stack-drift.sh` — react/vite message `/forge mcp add` → `/forge sync`
- Fix: `test-config.sh` — injection scan false positive on `<instructions>` (now requires closing tag)
- Fix: `hookify` — settings.json.partial paths from `$DOTFORGE_DIR/stacks/hookify/` → `.claude/hooks/hookify/`
- Schema: manifest now includes `stacks` array (bootstrap + sync skills updated)

#### Portability
- Fix: `check-updates.sh` — portable timeout: `timeout` → `gtimeout` → skip (macOS + Git Bash)
- Fix: 3 hooks — `_hash()` POSIX function: `md5sum` → `md5` → `cksum` (Git Bash compatible)
- Fix: 11 scripts — shebangs normalized `#!/bin/bash` → `#!/usr/bin/env bash`
- New: `install.sh` — one-liner installer with platform detection (macOS/Linux/WSL/Git Bash)

#### Upstream Alignment (Claude Code v2.1.84–v2.1.92)
- Update: 27 hook events (PermissionDenied correctly counted), `if` conditional field, `defer` decision documented
- Update: 6 permission modes (added auto, dontAsk) with classifier details
- Update: 1M context window GA for Opus 4.6 / Sonnet 4.6, auto-compact buffers recalculated
- Update: MCP tools can override result cap to 500K via `_meta` annotation
- Update: `paths:` frontmatter now accepts YAML list syntax
- Update: Claude 3 Haiku deprecated (retiring April 19, 2026)
- Update: Removed built-in commands `/tag` and `/vim` from Claude Code (upstream removal)
- New settings: `showThinkingSummaries` (false default), `disableSkillShellExecution`, `forceRemoteSettingsRefresh`
- New: plugin bin/ executable support (v2.1.91)
- New domain rules: `auto-mode.md`, `hook-events.md`
- Split: `hook-architecture.md` → `hook-architecture.md` + `hook-events.md` (50-line constraint)
- Split: `permission-model.md` → `permission-model.md` + `auto-mode.md`

#### Project Health
- Audit: all 12 projects scored (8 perfect 10.0, avg 9.8/10)
- Migration: claude-kit → dotforge completed across all 12 projects (symlinks, hooks, settings, commands)
- Global sync: deny list aligned (global template +5 entries, `**/` recursive globs)
- Security: Jira PAT removed from global settings.json, stale entries cleaned
- Hygiene: `__pycache__/`, `*.pyc` added to .gitignore

#### README
- Tagline: "Configuration factory" → "Configuration governance"
- New: lifecycle hero diagram, "Works with" table, multi-platform export section
- New: Requirements with WSL/Windows guidance
- Updated: Spanish section aligned

#### Documentation
- New: `docs/plan-v2.9.md` — execution plan with competitive analysis
- Updated: `docs/best-practices.md` — 26 hook events
- Updated: `docs/security-checklist.md` — auto mode safety section
- Updated: `docs/creating-stacks.md` — paths YAML format + stack hook copying

#### E2E Validation (2026-04-05)
- Bootstrap on clean project: 20 files created, react-vite-ts detected, manifest with stacks
- Audit: 8.87/10 (text + JSON valid)
- Status: 12 projects, avg 9.8/10
- Sync: all in sync, no destruction
- Checklist: 28/28 passed. Verdict: SHIP

---

## v2.8.1 (2026-04-05)

### Source-Verified Corrections + Cleanup

- Fix: compaction threshold corrected from "~90%" to "effectiveContextWindow - 13K tokens (≈93.5% for 200K)"
- Fix: MEMORY.md index has dual cap: 200 lines AND 25KB — whichever triggers first
- Fix: auto-mode permission stripping is reversible (restored on exit)
- Fix: complete dangerous patterns list: +tsx, +env, +xargs, +ssh, matching rules documented
- Fix: hook events count 25 → 27 (+PermissionDenied, +Setup, +WorktreeCreate, +WorktreeRemove)
- Fix: PostCompact dual interface documented (command hook vs SDK schema field names)
- Nuevo: tool result size limits documented (50K/tool, 200K/turn, 30K bash)
- Nuevo: tool concurrency & safety classification table
- Nuevo: `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80` in template settings
- Cleanup: go-api redundant permissions removed (go test/build/run/vet → go *)
- Cleanup: python-fastapi Redis section removed (use redis stack)
- Cleanup: _common.md split to ≤50 lines → practice-capture.md + context-continuity.md
- Fix: forge.md init description ("zero questions" → "4 quick questions")
- Ref: hardcoded system prompt rules documented in internals (reference only)
- Ref: 6 additional settings.json keys documented, constants table expanded

---

## v2.8.0 (2026-04-05)

### Internals Analysis + P0 Fixes + P1 Alignment

Deep reverse engineering of Claude Code internals from 5 repositories, verified against source code. All P0 bugs fixed, P1 alignment completed.

#### P0 Bug Fixes
- Fix: `session-report.sh` — `$DOMAIN_CHANGES` used before defined → invalid JSON output
- Fix: `block-destructive.sh` — regex `\*` in ERE mode didn't match literal `*` → switched to `grep -qiF`
- Fix: missing deny patterns — `DROP TABLE`, `DROP DATABASE`, `git checkout --`, `git checkout .` added
- Fix: agent frontmatter — `tools:` → `allowed-tools:` in 7 agents (was silently ignored)
- Fix: agent frontmatter — removed invalid `memory: project` field from 5 agents
- Fix: redis glob — `**/*stream*` matched unrelated files → narrowed to `**/*redis*`
- Fix: `_common.md` exceeded 50-line limit (67 lines) → split into separate files
- Fix: removed `Bash(cat *)` from allow list (conflicts with Read tool)
- Fix: added `Bash(make *)` to base template allow list

#### P1 Internals Alignment
- Fix: node-express glob narrowed to backend paths — avoids overlap with react-vite-ts
- Fix: data-analysis glob removed `.py` — avoids overlap with python-fastapi
- Fix: auto-mode safe permissions — replaced python3/node/npm/aws/gcloud with specific tool commands in 6 stacks
- Nuevo: ToolSearch Step 0 in watch-upstream + scout-repos skills (deferred tools discovery)
- Nuevo: `CLAUDE_CODE_SESSIONEND_HOOKS_TIMEOUT_MS=5000` env var in template settings
- Nuevo: async hooks documentation in hookify (async flag, asyncRewake, streaming)
- Mejora: detect.md — added hookify + trading stacks, pyproject.toml refined, priority rules
- Cambio: test-runner model haiku → sonnet (writes tests, needs reasoning quality)
- Nuevo: 5K token output budget in 6 agents + SendMessage continuation in all agents
- Nuevo: system prompt override patterns in python-fastapi, java-spring, go-api
- Nuevo: `context: fork` on 5 heavy skills for post-compaction safety

#### Domain Rules — Source-Verified Updates
- `hook-architecture.md`: 25 events (was 13), async hooks, timeouts, plugin env vars, event details
- `permission-model.md`: 5-step evaluation cascade, bash prefix detection, auto-mode stripping
- `context-window-optimization.md`: 5-tier compaction hierarchy, token budgets, env vars for control
- `rule-effectiveness.md`: complete frontmatter fields (model, effort, context, agent, allowed-tools)
- `agent-orchestration.md`: task types, slash command priority, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- `prompting-patterns.md`: system prompt conflicts, override patterns, language rules

#### New Documentation
- `docs/internal/claude-code-internals-analysis.md` — comprehensive cross-repo analysis (system prompt, context window, 41 tools, permissions, hooks, agents, sessions, undocumented features)
- `docs/internal/improvement-plan-internals.md` — 36 prioritized items (P0-P3) with execution plan
- `docs/internal/feature-flags-reference.md` — complete feature flags: 9 env vars, 4 settings keys, 7 internal flags (KAIROS, Coordinator, ULTRAPLAN, Voice, Vim, Undercover, Anti-Distillation), 25+ GrowthBook gates, 10 gated slash commands

#### Python Reimplementation Insights
- Analysis of nanocode (250 lines, minimal viable loop) and nano-claude-code (6.2K lines, full reimplementation)
- 5 insights: pre-compaction tool-result snipping, read_only/concurrent_safe annotations, skill context:fork, minimal system prompt sufficiency, self-documenting tool descriptions

---

## v2.7.1 (2026-03-30)

### Hook Architecture — Correcciones y expansión

- Corrección: `PreCompact` es **non-blocking** — el exit code se ignora (documentación anterior era incorrecta)
- Verificado: `PostCompact` recibe `compact_summary` y `trigger` — los docs oficiales dicen "common fields only" pero estos campos SÍ llegan
- Nuevo: hook types `http`, `prompt`, `agent` documentados en `stacks/hookify/rules/hookify.md`
- Nuevo: 4 eventos de alto valor añadidos a `hook-architecture.md`: PermissionRequest, SubagentStart, CwdChanged, StopFailure
- Corrección: `rule-effectiveness.md` — documentación de eager loading (`globs:`) vs lazy loading (`paths:` CSV + `alwaysApply: false`). Ref: [anthropics/claude-code#17204](https://github.com/anthropics/claude-code/issues/17204)
- 5 prácticas de investigación incorporadas al pipeline activo

---

## v2.7.0 (2026-03-30)

### Domain Knowledge Layer + Context Continuity

#### Domain Knowledge Layer

- Nuevo: `template/rules/domain-learning.md` — regla `globs:**/*` que instruye a Claude a persistir descubrimientos de dominio en `.claude/rules/domain/`
- Nuevo: `skills/domain-extract/SKILL.md` — skill `/forge domain extract|sync-vault|list` para extraer y gestionar conocimiento de dominio del proyecto
- Nuevo: frontmatter extendido para domain rules: campos `domain:`, `last_verified:`, `domain_source:`
- Mejora: `template/CLAUDE.md.tmpl` — secciones `## Role` y `## Domain` añadidas al template base
- Mejora: `/forge init` — pregunta 4 sobre dominio/rol del proyecto
- Mejora: `/forge bootstrap` — crea archivos seed en `domain/` durante el bootstrap
- Mejora: `/forge audit` — muestra sección de domain knowledge (informacional, sin impacto en score)
- Mejora: `/forge sync` — skippea explícitamente `.claude/rules/domain/` (nunca sobrescribe conocimiento de dominio acumulado)

#### Context Continuity

- Nuevo: `template/hooks/post-compact.sh` — hook PostCompact que escribe `compact_summary` + estado git en `.claude/session/last-compact.md`
- Nuevo: `template/hooks/session-restore.sh` — hook SessionStart con `source="compact"` que re-inyecta last-compact.md como contexto al iniciar sesión después de compactación
- Mejora: `template/settings.json.tmpl` — registra ambos hooks (PostCompact + SessionStart)
- Mejora: `template/rules/_common.md` — sección Context Continuity: Claude actualiza last-compact.md después de tareas significativas

---

## v2.6.1 (2026-03-24)

### Practices pipeline — Python debugging rules

- Incorporado: `stacks/python-fastapi/rules/backend.md` — regla "root cause first": antes de hacer un fix, verificar import errors, shadowed packages y env vars
- Incorporado: `stacks/python-fastapi/rules/backend.md` — regla "package naming": verificar con `pip3 show <dirname>` antes de nombrar un directorio local para evitar shadowing de PyPI packages
- Fuente: 2 prácticas promovidas a active/ desde cotiza-api-cloud (fix-loop-root-cause, websocket-shadow-import)
- Deprecadas: 7 prácticas de inbox (session logs sin contenido generalizable, cotiza security action item project-specific)

---

## v2.6.0 (2026-03-21)

### Audit CI + Stack Drift + MCP Versioning + Orchestration

- Nuevo: `audit/score.sh` — script bash standalone (3.2+ compatible) que evalúa 12 items mecánicos sin Claude. Flags: `--json`, `--threshold N`. Score 0-10, security cap 6.0 si faltan settings.json o block-destructive
- Nuevo: `.github/workflows/audit.yml` — CI que ejecuta score.sh en PRs y comenta el score. Bloquea si score < `AUDIT_SCORE_THRESHOLD` (default 7.0)
- Nuevo: `template/hooks/detect-stack-drift.sh` — PostToolUse hook que detecta nuevas dependencias y avisa sobre stacks no instalados. Monitorea package.json, pyproject.toml, go.mod, pom.xml, Gemfile. Nunca bloquea (exit 0 siempre)
- Nuevo: `skills/mcp-add/SKILL.md` — skill `/forge mcp add <server>` que instala templates MCP en proyectos (merge config, permisos aditivos, copia rules.md)
- Mejora: MCP version pinning — todos los config.json con versiones exactas: github@2025.4.8, postgres@0.6.2, redis@2025.4.25, slack@2025.4.25, supabase@0.7.0
- Nuevo: `mcp/update-versions.sh` — script que consulta npm y actualiza pines de versión en todos los config.json
- Mejora: `template/rules/agents.md` — sección TodoWrite con guía de cuándo/cómo usarlo (session-scoped, mark immediately, ≥3 acciones)
- Mejora: `template/rules/model-routing.md` — tabla de Model IDs explícitos (opus/sonnet/haiku con IDs de API exactos para agosto 2025)
- Mejora: `template/settings.json.tmpl` — añadido Stop hook para session-report.sh y detect-stack-drift.sh en PostToolUse

---

## v2.5.0 (2026-03-21)

### Learning Loop + MCP Templates + Model Routing

- Nuevo: `/forge capture` modo auto-detección — sin args, analiza contexto de sesión, propone insight pre-formateado, pide confirmación Y/n/edit antes de guardar
- Nuevo: `/cap` — alias shorthand para `/forge capture` (4 chars vs 14)
- Nuevo: Regla proactiva en `template/rules/_common.md` — Claude sugiere `/cap` al detectar workaround, bug multi-intento, decisión con trade-offs, o comportamiento de API no-obvio
- Nuevo: `mcp/` — templates de servidores MCP para github, postgres, supabase, redis, slack. Cada uno con config.json (mcpServers entry), permissions.json (allow/deny/prompt por tool), rules.md (reglas Claude-consumed). Auto-detectados por `/forge bootstrap`
- Nuevo: `template/rules/model-routing.md` — criterios explícitos haiku/sonnet/opus por tipo de tarea, con tabla de escalation y MCP operations
- Cambio: 7 agents con modelo explícito — researcher/test-runner=haiku, implementer/code-reviewer/session-reviewer=sonnet, architect/security-auditor=opus. Anterior: todos en `model: inherit`
- ROADMAP reescrito: documenta v2.4.0 completado, v2.5.0 completado, v2.6.0 próximo, descartados

---

## v2.4.0 (2026-03-21)

### Init, Unregister, Auto-update, Privacy
- Nuevo: `/forge init` — setup rápido con detección de stack + 3 preguntas (qué hace/no hace, con qué, cómo trabajo). Detecta idioma del usuario. Genera CLAUDE.md personalizado
- Nuevo: `/forge unregister <project>` — elimina proyecto del registry sin borrar config
- Cambio: `/forge global sync` ahora hace `git pull --ff-only` automático de dotforge antes de sincronizar
- Fix: registry ships vacío (`projects: []`). Datos locales en `projects.local.yml` (gitignored). No más paths privados en el repo público
- Fix: limpieza de datos personales en practices y evaluating
- Nuevo: `demo/README.md` con instrucciones para grabar demo GIF manualmente (vhs no funciona con CLIs interactivos)
- Nuevo: GitHub Releases para v2.1.0, v2.2.0, v2.3.0

---

## v2.3.0 (2026-03-21)

### Plugin Generator + OpenClaw Integration
- Nuevo: `/forge plugin` — genera un paquete de plugin de Claude Code desde la config del proyecto actual, listo para `claude --plugin-dir` o submission al marketplace oficial
- Nuevo: skill `plugin-generator` — convierte rules a skills, hooks a hooks.json, extrae deny list, genera README
- Nuevo: `integrations/openclaw/` — bridge skill para operar /forge desde WhatsApp, Telegram, Slack via OpenClaw
- Nuevo: `/forge export openclaw` — genera workspace skill de OpenClaw por proyecto
- Fix: OpenClaw install.sh usa `skills.load.extraDirs` en vez de symlinks (evita "Skipping skill outside root")
- Fix: Variables de entorno van en `~/.openclaw/.env`, no en `.bashrc`

---

## v2.2.0 (2026-03-20)

### CI/CD + Quality + OpenClaw Integration
- Nuevo: GitHub Actions CI workflow — validates hooks (bash -n + permissions), YAML files, rules frontmatter, stack completeness, skill completeness, benchmark tasks, version consistency
- Nuevo: `tests/lint-rules.sh` — validates all rule .md files have `globs:` frontmatter
- Nuevo: `integrations/openclaw/` — bridge skill que permite operar `/forge` desde WhatsApp, Telegram, Slack, Discord via OpenClaw
- Nuevo: `/forge export openclaw` — genera un workspace skill de OpenClaw por proyecto con contexto, reglas, deny list, y bridge CLI
- Cambio: `forge-export.md` y export-config skill actualizados con OpenClaw como cuarto target
- Fix: plugin.json version synced to VERSION file (CI catches mismatches)

---

## v2.1.0 (2026-03-20)

### Making it real
- Fix: `/forge benchmark` y `/forge rule-check` agregados al dispatch de forge.md (skills existían pero /forge no ruteaba a ellos)
- Cambio: `/forge watch` reescrito — ahora usa WebFetch en docs oficiales + WebSearch como fallback, con comparación estructurada contra template
- Cambio: `/forge scout` reescrito — usa `gh api` para fetch read-only de configs `.claude/` de repos en sources.yml, clasificación novel/variant/superior/covered
- Cambio: usage guide + guía de uso actualizados con sección Config Validation (session metrics, rule-check, benchmark, test-config.sh)
- Fix: skill counts 11 → 13 en ambas guías
- Registrados 10 proyectos reales en registry (3 auditados, 4 bootstrap standard, 3 bootstrap minimal)

---

## v2.0.0 (2026-03-20)

### Stabilization
- Nuevo: `docs/internal/architecture-components.md` — component map completo (template, stacks, skills, agents, practices, audit, global, registry)
- Nuevo: `docs/internal/scoring-algorithm.md` — fórmula, security cap, ejemplos por tier
- Nuevo: `docs/internal/config-validation-flow.md` — diagramas de data flow para las 4 fases
- Git tags retroactivos v0.1.0 → v1.6.0 (13 tags anotados)
- Practices inbox limpio (plugin-system → deprecated, duplicate removed)
- Registry re-auditado en v1.6.0, changelog completo v0.1.0 → v2.0.0

---

## v1.6.0 (2026-03-20)

### Config Validation System
- Nuevo: `tests/test-config.sh` — 30 checks de coherencia interna (hooks existen, globs válidos, deny list completa, no contradicciones)
- Nuevo: coherence check integrado en `/forge audit` (paso 1c)
- Nuevo: skill `/forge rule-check` (`rule-effectiveness`) — clasifica reglas en activas/ocasionales/inertes cruzando globs contra git log
- Cambio: `session-report.sh` reescrito — genera JSON metrics en `~/.claude/metrics/{slug}/{date}.json` (siempre activo, SESSION_REPORT.md sigue opt-in)
- Nuevo: hook counters en `block-destructive.sh` y `lint-on-save.sh` — escriben a `/tmp/` para que session-report los agregue
- Nuevo: rule coverage calculation — cruza archivos tocados contra globs de rules por sesión
- Cambio: `session-insights` skill — retroactive analysis desde git log + CLAUDE_ERRORS.md cuando no hay métricas de sesión
- Nuevo: `practices/metrics.yml` — tracking binario de efectividad (monitoring → validated/failed tras N checks sin recurrencia)
- Cambio: `update-practices` skill — nueva Fase 4 recurrence check contra CLAUDE_ERRORS.md de proyectos del registry
- Nuevo: campos `effectiveness` y `error_type` en frontmatter de prácticas
- Nuevo: skill `/forge benchmark` — compara full config vs minimal en worktrees aislados con tareas estándar por stack
- Nuevo: 6 benchmark tasks (python-fastapi, react-vite-ts, swift-swiftui, node-express, go-api, generic)
- Nuevo: `metrics_summary` schema en registry para métricas agregadas por proyecto
- Nuevo: tabla de precondiciones en `forge.md` — valida estado antes de despachar acciones
- Nuevo: `docs/config-validation.md` — documentación completa del sistema de 4 fases

---

## v1.5.0 (2026-03-20)

### Intelligence & Analytics
- Nuevo: skill `/forge insights` (`session-insights`) — analiza sesiones pasadas: error patterns, file activity, agent usage, score trends. Genera recomendaciones y alimenta practices pipeline
- Nuevo: hook `session-report.sh` (Stop) — genera `SESSION_REPORT.md` al finalizar sesión (opt-in via `FORGE_SESSION_REPORT=true`)
- Nuevo: scoring trends en `/forge status` — sparkline ASCII, flechas de tendencia, alertas cuando score baja >1.5 puntos
- Nuevo: recomendación automática de `/forge sync` cuando score < 7.0 y hay nueva versión disponible

---

## v1.4.0 (2026-03-20)

### Distribution & Plugin
- Nuevo: `.claude-plugin/plugin.json` — metadata formal para el sistema de plugins de Claude Code
- Nuevo: `.claude-plugin/INSTALL.md` — documentación de modos de instalación (plugin vs full)
- Nuevo: `plugin.json` en cada uno de los 13 stacks para distribución independiente
- Los stack plugins son composables: múltiples se pueden instalar, permisos se mergean por unión
- Plugin mode = subconjunto curado (hooks + rules + commands)
- Full mode = git clone + sync.sh (skills, agents, practices pipeline)

---

## v1.3.0 (2026-03-20)

### Stack Expansion & Cross-Tool
- Nuevo stack: **node-express** — Node.js + Express/Fastify (rules + permissions)
- Nuevo stack: **java-spring** — Java + Spring Boot + Maven/Gradle (rules + permissions)
- Nuevo stack: **aws-deploy** — AWS CDK/SAM/CloudFormation (rules + deny list para ops destructivos)
- Nuevo stack: **go-api** — Go modules + standard library HTTP (rules + permissions)
- Nuevo stack: **devcontainer** — configuración de devcontainers para Claude Code
- Nuevo: skill `/forge export` (`export-config`) — exporta config a Cursor (`.cursorrules`), Codex (`AGENTS.md`), Windsurf (`.windsurfrules`)
- Nuevo: bootstrap profiles — `--profile minimal|standard|full` controla qué se instala
- Nuevo: project tier detection en audit — `simple|standard|complex` ajusta expectations de scoring
- 13 stacks totales (era 8)
- 11 skills totales (era 9)

---

## v1.2.3 (2026-03-20)

### Hardening & Quick Wins
- Nuevo: audit item 12 — prompt injection scan (escanea rules y CLAUDE.md por patrones sospechosos)
- Nuevo: hook profiles (`FORGE_HOOK_PROFILE`: `minimal|standard|strict`) en block-destructive.sh
- Nuevo: columna Type en CLAUDE_ERRORS.md (`syntax|logic|integration|config|security`)
- Nuevo: instrucción de git worktree `isolation: "worktree"` para Agent Teams en agents.md e implementer.md
- Nuevo: hook `warn-missing-test.sh` (PostToolUse, Write) — warning educativo cuando se crea archivo sin test (solo profile strict)
- Cambio: scoring actualizado para 12 items recomendados (preserva split 70/30)

---

## v1.2.2 (2026-03-19)

### Correcciones del análisis v1.2.1
- Fix: fórmula de scoring — recomendados ahora pesan 50% real (obligatorios perfectos sin recomendados = 7.0, no 10.0)
- Fix: template lint-on-save.sh usa swiftlint (consistente con stack swift-swiftui), eliminado swiftformat
- Fix: implementer.md ya no referencia `.claude/specs/in-progress/` inexistente
- Fix: README.md corregido "51 items" → "31 items" en security checklist
- Fix: fórmula duplicada en audit-project skill actualizada a nueva fórmula
- Nuevo: `stacks/detect.md` — lógica de detección de stacks centralizada (antes duplicada en 4 skills)
- Nuevo: bootstrap crea `.claude/agent-memory/` para agentes con `memory: project`
- Nuevo: git tags v0.1.0 a v1.2.1 (habilita `/forge diff` con comparación por tags)
- Cambio: `/forge watch` y `/forge scout` marcados como stubs en forge.md
- Cambio: registry scores recalculados con nueva fórmula
- Nuevo: audit cross-project error promotion — errores recurrentes (3+) en CLAUDE_ERRORS.md se promueven a practices/inbox
- Nuevo: audit gap capture — gaps de auditoría (obligatorios 0-1, recomendados 0) se capturan como prácticas
- Nuevo: update-practices genera rules automáticamente cuando la práctica lo amerita
- Nuevo: `/forge watch` skill formal (`watch-upstream`) — busca cambios en docs Anthropic
- Nuevo: `/forge scout` skill formal (`scout-repos`) — revisa repos curados
- Nuevo: `practices/sources.yml` — repos curados para scout
- Nuevo: agent memory operativo — 4 agentes (implementer, architect, code-reviewer, security-auditor) leen/escriben `.claude/agent-memory/`
- Nuevo: score trending — audit appends `history` entries al registry (nunca sobreescribe)
- Fix: `{{DOTFORGE_PATH}}` placeholder resuelto en instrucciones de global sync

---

## v1.2.0 (2026-03-19)

### Tooling defensivo
- Nuevo: `/forge diff` — muestra qué cambió en dotforge desde el último sync del proyecto
- Nuevo: `/forge reset` — restaura `.claude/` a la plantilla con backup y rollback
- Nuevo: Validación JSON obligatoria en bootstrap y sync antes de escribir settings.json
- Nuevo: Hook testing framework (`tests/test-hooks.sh`) — 10 tests para block-destructive y lint-on-save
- Nuevo: Manifest de archivos deployados (`.claude/.forge-manifest.json`) con hashes SHA256
- Bootstrap genera manifest automáticamente al finalizar
- Sync actualiza manifest después de aplicar cambios
- Diff usa manifest para comparación rápida si existe

---

## v1.1.0 (2026-03-19)

### Gestión global (~/.claude/)
- Nuevo: `global/CLAUDE.md.tmpl` — plantilla del CLAUDE.md global con marker `<!-- forge:custom -->`
- Nuevo: `global/settings.json.tmpl` — deny list base para settings.json global
- Nuevo: `global/sync.sh` — script que instala/actualiza symlinks de skills, agents y commands
- Nuevo: `global/commands/forge.md` — forge.md versionado (reemplaza archivo suelto por symlink)
- Nuevo: `/forge global sync` y `/forge global status` en el comando forge
- Nuevo: `/forge watch` y `/forge scout` (stubs para intake de prácticas externas)
- Fix: deny list global poblada (estaba vacía, contradiciendo la filosofía de seguridad)
- Fix: marker `<!-- forge:custom -->` agregado a ~/.claude/CLAUDE.md
- Cambio: `_common.md` simplificada — elimina duplicación con global CLAUDE.md (reglas de comportamiento van en global, reglas de código van en _common.md)
- Cambio: sync-template ahora verifica global antes de sincronizar (no duplica reglas)

---

## v1.0.1 (2026-03-19)

### Higiene interna
- Fix: frontmatter `globs:` agregado a `template/rules/_common.md` (inconsistencia con versión deployada)
- Fix: command `audit.md` actualizado a 8 stacks (faltaban gcp-cloud-run y redis)
- Fix: inflated scores corrected in registry (recalculated with v1.0 formula)
- Fix: bootstrap siempre copia `lint-on-save.sh` genérico (resuelve ambigüedad hooks de stack vs genérico)
- Fix: researcher constraint relajada de 5 a 15 file reads
- Eliminado: `docs/x-references.md` (contenido efímero)
- Nuevo: `docs/roadmap.md` con plan v1.0→v2.0

---

## v1.0.0 (2026-03-19)

### Estable y completo
- 8 stacks con rules + settings.json.partial: python-fastapi, react-vite-ts, swift-swiftui, supabase, docker-deploy, data-analysis, gcp-cloud-run, redis
- 6 hooks ejecutables verificados (template + stacks + global)
- Auditoría con verificación de contenido, chmod, y cap de seguridad
- Sync inteligente con merge de arrays y protección de customizaciones
- Pipeline de prácticas funcional e2e (capture → update → incorporate)
- Documentación completa: README, troubleshooting, creating-stacks, best-practices, security-checklist, prompting-patterns
- Registry con version tracking y last_sync
- practices/inbox vacío (todo procesado)

---

## v0.9.0 (2026-03-19)

### Pipeline de prácticas funcional
- update-practices simplificado: 3 fases (evaluar → incorporar → propagar), eliminada web search automática y deprecación automática
- capture-practice: validación de duplicados contra active/ e inbox/ antes de crear
- detect-claude-changes.sh: instrucciones de instalación completas como comentario
- Flujo e2e: /forge capture → /forge update funciona en una sesión

---

## v0.8.0 (2026-03-19)

### Documentación y onboarding
- README.md con quick start (3 pasos), estructura, tabla de stacks y skills
- docs/troubleshooting.md — 4 problemas comunes con checklist de diagnóstico
- docs/creating-stacks.md — guía completa para crear stacks nuevos

---

## v0.7.0 (2026-03-19)

### Sync inteligente
- Sync reescrito con merge inteligente: unión de sets para allow/deny, preserva hooks y permisos custom
- Dry-run obligatorio antes de aplicar (muestra diff exacto)
- Nunca toca settings.local.json ni secciones `<!-- forge:custom -->`
- Actualiza registry con last_sync y dotforge_version post-sync
- Score antes/después para verificar mejora
- Template CLAUDE.md.tmpl: nuevo marker `<!-- forge:custom -->` para secciones protegidas

---

## v0.6.0 (2026-03-19)

### Stacks faltantes
- Nuevo stack: **gcp-cloud-run** — rules (Cloud Run, Secret Manager, scaling, logging) + settings.partial
- Nuevo stack: **redis** — rules (Streams, consumer groups, keys, connection pool) + settings.partial
- Bootstrap y audit detectan los 8 stacks (python-fastapi, react-vite-ts, swift-swiftui, supabase, data-analysis, docker-deploy, gcp-cloud-run, redis)
- 8/8 stacks con rules + settings.json.partial completos

---

## v0.5.0 (2026-03-19)

### Auditoría que audite de verdad
- Checklist: CLAUDE.md ahora verifica secciones clave (stack, build, arquitectura), no solo líneas
- Checklist: hooks verifican chmod +x y wiring en settings.json
- Scoring: cap de 6.0 si falta settings.json o block-destructive (seguridad crítica)
- Skill audit-project: verifica ejecutabilidad de hooks, reporta dotforge_version
- Registry: nuevos campos `dotforge_version` y `last_sync` por proyecto
- Detección de stacks nuevos: gcp-cloud-run y redis

---

## v0.4.0 (2026-03-19)

### Completar lo roto
- settings.json.partial para docker-deploy (docker, docker-compose)
- settings.json.partial para supabase (supabase CLI)
- Hook lint-swift.sh para swift-swiftui (swiftlint + swift build fallback)
- Pipeline de prácticas: directorios evaluating/, active/, deprecated/ creados
- Example practice moved to active/ with incorporated_in complete
- Domain-specific practice discarded (local config only)
- Bootstrap skill: soporte multi-stack explícito + sugerencia de hook global
- 6/6 stacks ahora tienen settings.json.partial

---

## v0.3.0 (2026-03-19)

### Multi-Agent Orchestration
- 6 agentes especializados: researcher, architect, implementer, code-reviewer, security-auditor, test-runner
- Regla de orquestación global (agents.md) con decision tree de delegación
- Agentes instalados globalmente via symlink (~/.claude/agents/)
- Cadenas de agentes: feature, bug fix, security audit, refactor
- Soporte para Agent Teams (experimental, requiere Opus)
- Template y bootstrap actualizados para incluir agentes
- Checklist de auditoría incluye verificación de agentes

---

## v0.2.0 (2026-03-19)

### Pipeline de prácticas
- practices/ con ciclo de vida: inbox → evaluating → active → deprecated
- Skill capture-practice para registrar insights manuales
- Skill update-practices reescrito con pipeline de 5 fases
- Comando /forge capture, /forge inbox, /forge pipeline
- Hook Stop global: detecta cambios en .claude/ y los registra en inbox
- Scheduled task forge-weekly-update (lunes 9:15 AM)

---

## v0.1.0 (2026-03-19)

### Inicial
- Template base: CLAUDE.md.tmpl, settings.json.tmpl, rules/_common.md
- Hooks: block-destructive.sh, lint-on-save.sh
- Stacks: python-fastapi, react-vite-ts, swift-swiftui, supabase, data-analysis, docker-deploy
- Skills: audit-project, bootstrap-project, sync-template, update-practices
- Comando global: /forge (audit, sync, bootstrap, status, update)
- Auditor: checklist.md, scoring.md
- Registry: 7 proyectos registrados
- Docs: best-practices, prompting-patterns, security-checklist, x-references, anatomy-claude-md
- Comandos template: review, debug, audit, health
