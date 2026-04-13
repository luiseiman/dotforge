---
id: practice-2026-04-13-v3-clear-creates-session-boundary
title: "/clear creates a new session_id, abandoning all session-scoped behavior state"
source: "dotforge v3 Phase 1 live smoke test in ~/tmp-v3-live"
source_type: experience
discovered: 2026-04-13
status: inbox
tags: [v3, behavior-governance, session-lifecycle, runtime, audit-gap]
tested_in: tmp-v3-live
incorporated_in: []
replaced_by: null
---

## Observed behavior

During the Phase 1 live smoke test in `~/tmp-v3-live`, after driving
search-first to counter=5 / effective_level=soft_block / pending_block
present, the user ran `/clear` in the Claude Code session and then
requested the previously blocked Write (`src/http.py`).

Result in `.forge/runtime/state.json`:

```
sessions:
  874b22a7-...   (original)
    counter: 5
    effective_level: soft_block
    pending_block: {hash, blocked_at} ← intact
    flags.search_context_ready: present (orphan from a post-block Read)
    behaviors.search-first: full history

  1f91580c-...   (new, created ~5 min later by /clear)
    counter: 0
    behaviors: {}
    flags: {}
```

The new Write proceeded silently in the fresh session: Claude did
`Searched for 2 patterns` (Grep → flag set) → `Write src/http.py`
(flag consumed, counter stays 0), with no nudge, no warning, no deny.

## What this means

`session_id` in Claude Code hook payloads changes on `/clear`, NOT only
at process start. Our Phase 0 assumption was that a session_id was
bound to the process lifetime. It is actually bound to the
*conversation* — `/clear` starts a new one.

## Impact on behavior governance

1. **Soft_blocks are evadable via `/clear`** — any user who hits a
   session-scoped block can clear the conversation and resume the
   blocked operation with counter=0 and no permission prompt.

2. **No audit trail for the evasion.** `.forge/audit/overrides.log`
   records zero entries for this scenario because no tool call in the
   new session ever triggered the override detection path. The original
   session with its intact pending_block simply gets orphaned until
   the 24h TTL purges it.

3. **Pending_blocks can linger unclaimed.** A pending_block from an
   abandoned session is never cleared by the mismatch/expiry logic in
   forge_pending_block_try_override, because no hook invocation in
   that session ever reaches that function.

4. **Hard_block is NOT affected** — hard_blocks reset to their initial
   denying level on any fresh counter evaluation, so `/clear` does not
   provide an escape from them. Only session-scoped soft_block loses
   continuity.

## Root cause

Two design choices stack to produce this gap:

- **Claude Code design:** `/clear` is defined as "start fresh," and
  from a user-experience standpoint that includes dropping behavior
  state. This is not a Claude Code bug — it's consistent with `/clear`
  semantics everywhere else (history, context, tool result cache).

- **dotforge v3 design:** all counters and pending_blocks live in
  per-session state. There is no project-scope or account-scope
  persistence in Phase 1. This was the simplest Phase 1 shape and it
  is documented as a limitation in RUNTIME.md §3.

## Proposed fixes (not for Phase 1 — capture only)

**Fix A — add project-scope counters for safety-critical behaviors.**
Let behavior.yaml declare `scope: project`. Those behaviors persist
counters in `behaviors/<id>/state.yaml` (or an equivalent project-scope
store) instead of `.forge/runtime/state.json`. `/clear` does not reset
them. Higher friction but closes the evasion path for behaviors like
`no-destructive-git`.

**Fix B — audit orphaned sessions.** On hook invocation in a fresh
session, sweep state.json for sessions with unexpired pending_blocks
and append a "session_abandoned_with_pending_block" entry to the audit
log. Does not prevent the evasion but leaves evidence.

**Fix C — SessionStart hook** that fires on `source: clear` and
detects the transition. Could emit a warning, inject context about the
abandoned behaviors into the new session, or refuse to clear if
safety-critical behaviors are at or above soft_block. Highest
complexity, highest integration value.

My preference as of 2026-04-13: B is the lowest-cost defensible fix
for Phase 2. A is the long-term right answer for any behavior that
actually needs to bind a user, not a conversation.

## Related finding — flag masking override

Adjacent but separate: the compiled check_flag hook template has this
short-circuit structure:

```
if forge_flag_consume $sid $flag; then
    exit 0            # Flag present → silent pass
else
    run_evaluate      # Only here does try_override run
fi
```

This means a flag presence (set by any prior Read/Grep/Glob) masks the
pending_block override path. A user who gets a soft_block and then
reads a file before retrying will NOT have the retry recorded as an
override, because flag-consume short-circuits before run_evaluate.

Not verifiable in the live test because /clear intervened first, but
verifiable by code inspection and should be added to Phase 2's test
suite as a regression. Fix would be: reorder the check_flag template
so pending_block detection precedes flag consumption when the
behavior has ever emitted a pending_block for this session.

## Incorporation plan

- RUNTIME.md §3 — already updated with the empirical finding (Phase 1
  closing commit)
- Phase 2 backlog:
  - Add `scope: project` to SCHEMA.md (Fix A)
  - Implement session-sweep on hook init (Fix B)
  - Reorder check_flag template (flag masking fix)
  - Add unit test: pending_block survives across multiple intervening
    flag operations and still triggers override detection
- No code change in Phase 1. Phase 1 is green and this is a semantic
  refinement, not a breakage.
