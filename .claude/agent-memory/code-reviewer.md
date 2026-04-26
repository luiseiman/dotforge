# code-reviewer memory

Learnings and discoveries from code-reviewer agent sessions.

## 2026-04-13 — dotforge v3.0 spec cross-document consistency review

- **Recurring:** DECISIONS.md in this project captures early design intent and may predate final implementation decisions — always check it against implementation docs (SPEC/SCHEMA/RUNTIME) for channel/mechanism drift.
- **Recurring:** When a spec set has a "closed decisions" document, implementation docs often refine or silently override it (e.g., `flock` → `mkdir`, `stderr` → `stdout JSON`). Flag these as critical because they produce incompatible implementations depending on which document an engineer reads first.
- **False positive:** `override_allowed` absence in soft_block JSON output (SPEC 5.5) is intentional — not a missing field. Claude Code's default behavior when `permissionDecision: deny` is to show the override prompt without an explicit field.
- **Recurring:** Compiler specs for hook-based systems often omit secondary event hooks (e.g., `PermissionDenied`) that carry critical functionality (audit writes). Always verify all event types mentioned in behavioral specs appear in the compiler pipeline.

## 2026-04-13 — dotforge v3.0 spec deep review (5 implementation docs)

- **Recurring:** PermissionDenied event fires ONLY on auto-mode classifier denials, NOT on PreToolUse hook-generated denials. Any audit trail depending on PermissionDenied for hook-originated blocks is broken by design. Use PreToolUse re-invocation detection instead.
- **Recurring:** `set -euo pipefail` in generated bash hooks causes `grep -q` no-match (exit 1) to kill the entire hook. Either remove `set -e` or wrap every grep in a conditional/subshell.
- **Recurring:** `grep -oP` (PCRE) is BSD-incompatible on macOS. Always use `grep -oE` (extended regex) or `sed` for portable regex extraction.
- **Recurring:** DSL-based trigger conditions that reference only `tool_input` and `session_state.counter` cannot express temporal/sequential behaviors ("did X before Y"). Behaviors like search-first, verify-before-done require session history tracking beyond a simple counter.
- **False positive:** `override_allowed` field omission in soft_block JSON is intentional per SPEC.md S5.5 note — don't flag as missing field.
- **Recurring:** mkdir-based locks need age-based fallback cleanup when PID file is missing (process killed between mkdir and pid write). Check directory mtime, not just PID existence.
