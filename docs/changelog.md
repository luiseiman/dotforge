# Changelog — dotforge

> Version history. Entries use mixed Spanish/English as the project evolved. Technical terms are universal.
>
> Historial de versiones. Las entradas usan español/inglés mixto según la evolución del proyecto. Los términos técnicos son universales.

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
