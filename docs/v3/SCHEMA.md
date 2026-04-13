# behavior.yaml Schema v1

YAML schema specification for dotforge v3.0 declarative behavior files.
Enforcement semantics: [SPEC.md](SPEC.md). Design decisions: [DECISIONS.md](DECISIONS.md).

---

## 1. Overview

A behavior file declares an expected agent behavior, its enforcement policy, and its rendering templates. Each behavior lives in its own directory:

```
behaviors/
  <id>/
    behavior.yaml        # this schema
    tests/               # optional: test fixtures for validation
```

This directory-per-behavior structure allows test fixtures to live alongside the behavior without cluttering the root. The `behaviors/index.yaml` file controls which behaviors are active and in what evaluation order.

`schema_version: "1"` is required in every behavior file. It is the compile-time version of this schema, not the behavior's own version.

---

## 2. Complete Field Reference

```yaml
schema_version: "1"          # string, required. Must equal "1".
id: search-first             # string, required. Kebab-case. Unique across all behaviors.
name: Search Before Writing  # string, required. Human-readable display name.
description: >               # string, required. 1-3 sentences stating the purpose.
  Require the agent to search existing code before writing new implementations.
  Prevents duplicate code and enforces codebase familiarity.
category: core               # enum [core, opinionated, experimental], required.
scope: session               # enum [session, task, project], required. Only "session" functional in 3.0.
enabled: true                # boolean, default true. Override per-entry in index.yaml.

policy:
  triggers:                  # array, required. At least one trigger.
    - event: PreToolUse      # enum [PreToolUse, PostToolUse, UserPromptSubmit, Stop], required.
      matcher: "Write|Edit"  # string, tool matcher pattern. Required for PreToolUse and PostToolUse.
                             # Optional for UserPromptSubmit and Stop.
                             # Examples: "Bash", "Grep|Glob", "*".
      conditions:            # array, optional. If empty or absent, any matching event triggers.
        - field: file_path   # string, from closed DSL field set (Section 3).
          operator: regex_match  # enum, from closed DSL operator set (Section 3).
          value: '\.(py|ts|js|swift|go|rs|java|kt)$'
      logic: all             # enum [all, any], default "all". How conditions are combined.

  enforcement:
    default_level: silent    # enum [silent, nudge, warning, soft_block, hard_block], required.
    escalation:              # array, optional. Absent = always default_level.
      - after: 1             # integer >= 1, required. counter >= this value triggers level.
        level: nudge         # enum [silent, nudge, warning, soft_block, hard_block], required.
      - after: 3
        level: warning
      - after: 5
        level: soft_block

  recovery:
    hint: "Use Grep or Glob to search for existing patterns before writing new code."
                             # string, required. Instruction shown to agent on violation.
    suggested_tool: Grep     # string, optional. Tool name to suggest.
    suggested_action: "grep -r '<pattern>' src/"
                             # string, optional. Concrete command or action.

rendering:
  nudge_template: "{behavior_name}: Consider searching first (violation {counter})"
                             # string, max 120 chars. Supports {variables} (Section 4).
  warning_template: |
    **[{behavior_id}]** You have written code {counter} times without searching first.
    Expected: use Grep/Glob to find existing patterns before implementing.
    Action: search for related code, then proceed.
    Next violation triggers a block.
                             # string, max 500 chars. Supports {variables}.
  block_reason: "Must search the codebase before writing new code."
                             # string, max 200 chars.
  override_prompt: "Run Grep or Glob first, then retry the write operation."
                             # string, optional. Shown when soft_block allows override.

applies_to:
  tools: []                  # string array, optional. Tool names. Empty = all tools.
  agents: []                 # string array, optional. Agent names, simple string match. Empty = all.
  profiles: [standard, strict]
                             # string array, optional. Hook profiles [minimal, standard, strict].

metadata:
  author: dotforge           # string, optional.
  version: "1.0.0"           # string, optional. Semver.
  tags: [search, quality]    # string array, optional.
```

### Field constraints summary

| Field | Type | Required | Default | Constraint |
|-------|------|----------|---------|------------|
| `schema_version` | string | yes | — | Must equal `"1"` |
| `id` | string | yes | — | Kebab-case: `[a-z][a-z0-9-]*[a-z0-9]` |
| `name` | string | yes | — | — |
| `description` | string | yes | — | 1–3 sentences |
| `category` | enum | yes | — | `core`, `opinionated`, `experimental` |
| `scope` | enum | yes | — | `session`, `task`, `project` (only `session` functional) |
| `enabled` | boolean | no | `true` | Overridden by index.yaml |
| `policy.triggers` | array | yes | — | At least 1 item |
| `triggers[].event` | enum | yes | — | `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop` |
| `triggers[].matcher` | string | conditional | — | Required for `PreToolUse`/`PostToolUse` |
| `triggers[].conditions` | array | no | [] | Each item needs `field`, `operator`, `value` |
| `triggers[].logic` | enum | no | `all` | `all`, `any` |
| `enforcement.default_level` | enum | yes | — | One of 5 levels |
| `escalation[].after` | integer | yes | — | >= 1 |
| `recovery.hint` | string | yes | — | Shown to agent on violation |
| `nudge_template` | string | no | — | Max 120 chars |
| `warning_template` | string | no | — | Max 500 chars |
| `block_reason` | string | no | — | Max 200 chars |

---

## 3. Closed DSL Specification

Conditions reference fields from two closed namespaces. No other fields are valid in 3.0.

### tool_input fields

Available when the trigger event provides tool context (PreToolUse, PostToolUse):

| Field | Available for tools | Description |
|-------|--------------------|----|
| `command` | Bash | Full command string |
| `file_path` | Write, Edit, Read | Target file path |
| `content` | Write, Edit | File content or new text |
| `old_string` | Edit | Text being replaced |
| `pattern` | Grep, Glob | Search pattern |
| `query` | WebSearch | Search query |
| `url` | WebFetch | Target URL |
| `prompt` | Agent | Agent prompt text |

### session_state fields

Available in all trigger evaluations:

| Field | Type | Description |
|-------|------|-------------|
| `counter` | integer | Current violation count for this behavior in the current session |
| `flags` | object | Key-value flags set by PostToolUse triggers. Used for temporal behaviors (e.g., "did the agent search before writing?"). See **Session Flags** below. |

### Session Flags

Session flags solve the **temporal behavior problem**: detecting whether the agent did X before doing Y.

**Mechanism:**
- A behavior can define `policy.flag_on_match` (string) in its trigger. When the trigger matches, the flag is SET in `session_state.flags[behavior_id]`.
- A behavior can define `policy.reset_flag_on_match: true`. When the trigger matches AND a flag was set, the flag is CLEARED (violation detected — agent did Y without flag being cleared by Z).
- A behavior can reference `session_state.flags.<behavior_id>` in conditions using the `exists`/`not_exists` operators.

**Example: search-first**

The search-first behavior uses TWO triggers:
1. **PostToolUse on Grep|Glob:** sets flag `"searched"` — the agent searched.
2. **PreToolUse on Write|Edit (code files):** checks if flag `"searched"` exists. If NOT → violation. If yes → clear flag (consumed).

This way, writing after searching is allowed (flag exists → cleared, no violation). Writing without searching triggers the violation (flag absent → counter increment → escalation).

**Lifecycle:**
- Flags are stored in `state.json` under `sessions[sid].behaviors[bid].flags`
- Flags persist within the session (TTL 24h like everything else)
- Flags are per-behavior, per-session
- A flag is a simple string key → boolean value

**Schema additions for triggers:**

```yaml
policy:
  triggers:
    - event: PostToolUse
      matcher: "Grep|Glob"
      flag_on_match: "searched"     # SET flag when this trigger matches
    - event: PreToolUse
      matcher: "Write|Edit"
      conditions:
        - field: file_path
          operator: regex_match
          value: "\\.(py|ts|js|tsx|jsx|swift|go|rs|java|kt)$"
        - field: session_state.flags.search-first
          operator: not_exists
          value: ""                  # flag absent → agent didn't search
      consume_flag: "searched"       # CLEAR flag after evaluation (whether or not triggered)
```

**Fields added to trigger schema:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `flag_on_match` | string | optional | Flag name to SET when this trigger matches. Stored in `session_state.flags[behavior_id]`. |
| `consume_flag` | string | optional | Flag name to CLEAR after this trigger is evaluated (regardless of match). Implements "consume on check" semantics. |

### Operators

**String operators** (for tool_input fields):

| Operator | Semantics |
|----------|-----------|
| `regex_match` | Value is a regex; field must match |
| `contains` | Field contains value as substring |
| `not_contains` | Field does not contain value |
| `equals` | Exact string equality |
| `starts_with` | Field starts with value |
| `ends_with` | Field ends with value |

**Numeric operators** (for `session_state.counter`):

| Operator | Semantics |
|----------|-----------|
| `gt` | Greater than |
| `lt` | Less than |
| `gte` | Greater than or equal |
| `lte` | Less than or equal |
| `equals` | Equal to |

**Existence operators** (for any field):

| Operator | Semantics |
|----------|-----------|
| `exists` | Field is present and non-empty |
| `not_exists` | Field is absent or empty |

---

## 4. Template Variables

Available in `nudge_template`, `warning_template`, `block_reason`, and `override_prompt`:

| Variable | Value |
|----------|-------|
| `{behavior_name}` | Human-readable name (from `name` field) |
| `{behavior_id}` | Kebab-case id |
| `{counter}` | Current violation count for this behavior |
| `{tool_name}` | Tool that triggered the violation |
| `{level}` | Current effective level name (e.g., `warning`) |
| `{threshold}` | Next escalation threshold count, or `"max"` if at highest level |

Example: `"{behavior_name}: violation {counter}/{threshold} — {level} active"`

---

## 5. behaviors/index.yaml Format

Controls which behaviors are active and in what order they are evaluated. Order determines chain evaluation sequence (see SPEC.md Section 4).

```yaml
schema_version: "1"
behaviors:
  - id: search-first
    enabled: true
  - id: verify-before-done
    enabled: true
  - id: no-destructive-git
    enabled: true
  - id: respect-todo-state
    enabled: true
  - id: plan-before-code
    enabled: false  # opinionated, opt-in
  - id: objection-format
    enabled: false  # opinionated, opt-in
```

Rules:
- `enabled` here overrides the behavior file's own `enabled` field.
- Every referenced `id` must have a corresponding `behaviors/<id>/behavior.yaml`.
- Evaluation follows declaration order — put safety-critical behaviors first.

---

## 6. Validation Rules

Compile-time checks that must pass before hook generation:

- `schema_version` must equal `"1"`.
- `id` must be unique across all behaviors in the index.
- `id` must match `[a-z][a-z0-9-]*[a-z0-9]` (no uppercase, no leading/trailing hyphens).
- At least one trigger is required per behavior.
- `matcher` is required when `event` is `PreToolUse` or `PostToolUse`.
- All `field` values in conditions must be from the closed DSL field set (Section 3).
- All `operator` values must be from the closed DSL operator set (Section 3).
- Escalation `after` values must be non-decreasing when sorted: each successive entry must have `after >= previous after`. Levels must be non-decreasing in severity.
- `nudge_template` length must be <= 120 chars.
- `warning_template` length must be <= 500 chars.
- `block_reason` length must be <= 200 chars.
- Every `id` listed in `behaviors/index.yaml` must have a file at `behaviors/<id>/behavior.yaml`.
- Triggers with `event: PostToolUse`, `UserPromptSubmit`, or `Stop` must not have escalation paths reaching `soft_block` or `hard_block`. Blocking levels only apply to `PreToolUse` (see SPEC.md Section 5.7).
- `flag_on_match` is only valid on triggers with `event: PostToolUse`. `consume_flag` is only valid on triggers with `event: PreToolUse`.

---

## 7. Complete Example: search-first

```yaml
schema_version: "1"
id: search-first
name: Search Before Writing
description: >
  Require the agent to search existing code before writing new implementations.
  Prevents duplicate code and enforces codebase familiarity before modification.
  Uses session flags: a PostToolUse trigger on Grep/Glob sets a "searched" flag,
  and the PreToolUse trigger on Write/Edit checks for that flag.
category: core
scope: session
enabled: true

policy:
  triggers:
    # Trigger 1: SET flag when agent searches (PostToolUse on Grep/Glob)
    - event: PostToolUse
      matcher: "Grep|Glob"
      flag_on_match: "searched"

    # Trigger 2: CHECK flag when agent writes code (PreToolUse on Write/Edit)
    # Violation fires only if "searched" flag is absent (agent didn't search first)
    - event: PreToolUse
      matcher: "Write|Edit"
      conditions:
        - field: file_path
          operator: regex_match
          value: '\.(py|ts|js|tsx|jsx|swift|go|rs|java|kt|rb|php|cs)$'
        - field: session_state.flags.search-first
          operator: not_exists
          value: ""
      logic: all
      consume_flag: "searched"

  enforcement:
    default_level: silent
    escalation:
      - after: 1
        level: nudge
      - after: 3
        level: warning
      - after: 5
        level: soft_block

  recovery:
    hint: "Use Grep or Glob to search for existing patterns before writing new code."
    suggested_tool: Grep
    suggested_action: "grep -r '<pattern>' src/"

rendering:
  nudge_template: "{behavior_name}: Consider searching first (violation {counter}/{threshold})"
  warning_template: |
    **[{behavior_id}]** You have written code {counter} times without searching first.
    Expected: use Grep/Glob to find existing patterns before implementing.
    Action: search for related code, then proceed.
    Next violation ({threshold}) triggers a block.
  block_reason: "Must search the codebase before writing new code."
  override_prompt: "Run Grep or Glob first, then retry the write operation."

applies_to:
  tools: []
  agents: []
  profiles: [standard, strict]

metadata:
  author: dotforge
  version: "1.0.0"
  tags: [search, quality, core]
```

> **How it works:** The agent searches (Grep) → PostToolUse fires → flag "searched" is SET. Then the agent writes (Write) → PreToolUse fires → flag exists → condition `not_exists` is false → NO violation → flag is consumed (cleared by `consume_flag`). If the agent writes WITHOUT searching → flag is absent → condition `not_exists` is true → violation → counter increments → escalation applies.

---

## 8. Complete Example: no-destructive-git

```yaml
schema_version: "1"
id: no-destructive-git
name: No Destructive Git Operations
description: >
  Block force pushes, hard resets, and other destructive git operations permanently.
  Safety-critical — no override available.
category: core
scope: session
enabled: true

policy:
  triggers:
    - event: PreToolUse
      matcher: "Bash"
      conditions:
        - field: command
          operator: regex_match
          value: 'git\s+(push\s+.*--force|push\s+.*-f\b|reset\s+--hard|clean\s+-f|branch\s+-[Dd])'
      logic: all

  enforcement:
    default_level: hard_block

  recovery:
    hint: "Destructive git operations are permanently blocked. Use safe alternatives: git revert, git stash, git reset --soft."
    suggested_tool: Bash
    suggested_action: "git revert HEAD  # or git stash"

rendering:
  block_reason: "Force push, hard reset, and destructive git operations are permanently blocked."

applies_to:
  tools: [Bash]
  agents: []
  profiles: [minimal, standard, strict]

metadata:
  author: dotforge
  version: "1.0.0"
  tags: [git, safety, core]
```

Note: no `escalation` defined — `hard_block` is the immediate and permanent level. No `nudge_template` or `warning_template` needed since the behavior never produces those levels. See SPEC.md Section 5.6 for hard_block output protocol.

---

## 9. Anti-patterns

Do NOT include these in a behavior file:

- **Runtime expressions or scripting.** Conditions must use the closed DSL. No embedded bash, jq filters, or eval expressions.
- **File I/O or network calls.** Behaviors are declarative. No reading external files, no HTTP calls, no database queries.
- **Cross-behavior references.** A behavior cannot reference another behavior's counter, state, or output.
- **External state beyond tool_input and session_state.counter.** Environment variables, filesystem state, git state, and time-based conditions are out of scope for 3.0.
- **Rendering templates that exceed length limits.** nudge > 120 chars, warning > 500 chars, block_reason > 200 chars all fail validation.
- **Mixed concerns in one behavior.** A behavior enforcing both search-first and test-before-done is two behaviors. Split them — each behavior must have a single, named concern.
- **Bare `enabled: false` as a permanence signal.** Use `category: experimental` to signal instability; `enabled: false` in index.yaml for user opt-in behaviors.
- **Using `scope: task` or `scope: project`.** Reserved for future versions. Set `scope: session` in 3.0; other values parse but produce no functional behavior.
