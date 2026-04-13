# v2.9 → v3.0 Migration Guide

dotforge v3.0 adds a **behavior governance** layer on top of v2.9. It is opt-in, additive, and non-breaking: a v2.9 project upgraded to v3 continues to run unchanged until you explicitly adopt behaviors.

This guide walks through the upgrade in five steps.

---

## 1. What changes on disk

Nothing, until you opt in. v3.0.0 adds the following paths to the dotforge repo:

```
behaviors/                       # catalogue + index.yaml (new)
scripts/runtime/lib.sh           # shared runtime (new)
scripts/compiler/compile.sh      # behavior.yaml → hook compiler (new)
scripts/forge-behavior/cli.sh    # /forge behavior CLI (new)
docs/v3/*.md                     # spec of record (new)
.forge/runtime/state.json        # per-machine session state (runtime-created)
.forge/audit/overrides.log       # override audit trail (runtime-created)
```

`template/`, `stacks/`, `skills/`, `agents/`, `audit/`, `global/`, and `integrations/` are unchanged from v2.9 except for `audit/score.sh` gaining item 14 (behaviors coverage, 0-1, neutral if absent).

## 2. No-op upgrade

Pull v3.0 and run your normal commands. Everything keeps working:

```bash
cd ~/.dotforge
git pull origin main
git checkout v3.0.0
```

Then in a consuming project:

```bash
/forge audit       # still scores your project; item 14 = 0 (neutral)
/forge sync        # merges template updates as before
/forge status      # unchanged
```

If you do nothing else, you are done. v3 behaviors do not run unless you wire them in.

## 3. Opt in to the core behavior catalogue

The core catalogue lives in `behaviors/` inside the dotforge repo:

- `no-destructive-git` (hard_block) — blocks `git push --force`, `reset --hard`, `clean -f`, `branch -D`
- `search-first` (escalates) — requires a Grep/Glob/Read before Write/Edit
- `verify-before-done` (escalates) — requires a test/build command before `git push`
- `respect-todo-state` (escalates) — requires `TaskUpdate` interleaved with `TaskCreate`

To enable all four in the **dotforge repo itself** (useful for testing, or for self-hosting dotforge work), they are already enabled in `behaviors/index.yaml`.

To enable them in a **consuming project**, you have to compile and wire them explicitly. This is deliberate — Claude Code hooks run with file-system access, and dotforge refuses to auto-inject them.

### 3a. Compile

```bash
# From your project root
mkdir -p .claude/hooks/generated
for b in no-destructive-git search-first verify-before-done respect-todo-state; do
    bash ~/.dotforge/scripts/compiler/compile.sh \
        ~/.dotforge/behaviors/$b/behavior.yaml \
        .claude/hooks/generated/
done
```

Output per behavior: one or more `<id>__<event>__<matcher>__<idx>.sh` files, plus a `<id>.settings.json` fragment describing the hook wiring.

### 3b. Wire into `settings.json`

Each compiled behavior emits a `settings.json` snippet describing where to register the hook. Example fragment:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {"type": "command", "command": ".claude/hooks/generated/no-destructive-git__pretooluse__bash__0.sh"}
        ]
      }
    ]
  }
}
```

Merge each snippet into your `.claude/settings.json` `hooks.PreToolUse` array. Preserve any existing hooks you already have (block-destructive.sh is fully compatible and should stay).

Order matters: put safety-critical behaviors (hard_block) first so they short-circuit before softer checks increment their counters.

### 3c. Verify

```bash
/forge behavior status
/forge behavior list
/forge audit   # item 14 should now score 1
```

Run a deliberately failing command to confirm enforcement:

```bash
# Inside Claude Code
Bash(git push origin main --force)
# Expected: hook returns deny, tool call blocked
```

## 4. Opt in to opinionated behaviors

`plan-before-code` and `objection-format` ship with `enabled: false` in `behaviors/index.yaml`. To enable them:

```bash
/forge behavior on plan-before-code --project
/forge behavior on objection-format --project
```

Then recompile and rewire as in step 3. These are stricter and may generate friction — read each behavior's `describe` output before turning them on:

```bash
/forge behavior describe plan-before-code
/forge behavior describe objection-format
```

## 5. Runtime controls

Once behaviors are wired, you have four escape hatches:

| Scope | Command | Effect |
|-------|---------|--------|
| Session | `/forge behavior off <id> --session $SID` | Disable for current session only. Does not mutate `index.yaml`. Survives `/clear` via `scope: session`. |
| Project | `/forge behavior off <id> --project` | Disable permanently by setting `enabled: false` in `behaviors/index.yaml`. Requires recompile. |
| Strictness | `/forge behavior strict <id>` | Halve every escalation threshold in `behavior.yaml`. |
| Strictness | `/forge behavior relaxed <id>` | Double every escalation threshold. |

Soft-blocks can also be overridden inline during a session: the runtime detects reinvocation of the same `tool_input` within a window and logs the override to `.forge/audit/overrides.log` without incrementing the counter. See [`RUNTIME.md §12`](RUNTIME.md).

## 6. Rollback

If v3 behaviors cause problems:

```bash
# Disable all behaviors at the project level
for b in no-destructive-git search-first verify-before-done respect-todo-state plan-before-code objection-format; do
    /forge behavior off $b --project 2>/dev/null
done

# OR remove the compiled hooks entirely
rm -rf .claude/hooks/generated/

# OR remove the hook registrations from settings.json manually
```

Your v2.9 configuration continues to work unchanged. Nothing else needs to revert.

## 7. Authoring custom behaviors

See [`SCHEMA.md`](SCHEMA.md) for the complete `behavior.yaml` v1 field reference and [`COMPILER.md`](COMPILER.md) for how triggers become hooks. The short version:

```yaml
schema_version: "1"
id: my-behavior
name: Human Name
description: One sentence purpose.
category: core          # or opinionated, experimental
scope: session
enabled: true

policy:
  triggers:
    - event: PreToolUse
      matcher: "Bash"
      conditions:
        - field: command
          operator: regex_match
          value: 'rm\s+-rf\b'
      action: evaluate

  enforcement:
    default_level: hard_block

  recovery:
    hint: "Use git revert or stash instead."

rendering:
  block_reason: "rm -rf blocked by my-behavior."
```

Drop it under `behaviors/my-behavior/behavior.yaml`, add `- id: my-behavior` to `behaviors/index.yaml`, compile, and wire.

Write tests alongside the behavior under `behaviors/my-behavior/tests/` using the helper pattern from any existing behavior (e.g., `behaviors/no-destructive-git/tests/`).

## 8. Known limitations (v3.0)

- `scope: task` and `scope: project` parse but are not functional — only `scope: session` is supported.
- `conditions` on `session_state.counter` is not usable inside triggers (only `tool_input` fields).
- No `type: prompt` hooks yet — all behaviors compile to bash.
- Export to `.cursorrules` / `AGENTS.md` / `.windsurfrules` does not yet carry behaviors (deferred to 3.1).

See [`SCOPE.md`](SCOPE.md) for the full deferred-features list and [`DECISIONS.md`](DECISIONS.md) for why.
