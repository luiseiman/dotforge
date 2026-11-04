#!/usr/bin/env bash
# UserPromptSubmit hook — warn proactively when context approaches 80% of model window.
#
# Implements the evidence-based 80% threshold from dotforge compaction-strategy.md.
# Measures the REAL context from the transcript: the last non-sidechain assistant
# message carries message.usage, and context = input_tokens +
# cache_creation_input_tokens + cache_read_input_tokens (same method as
# claude-hud / cache-tax). The pre-v4.8.1 heuristic (transcript bytes / 5) was
# wrong after the first compaction: the transcript file never shrinks, so it
# reported 200%+ forever.
# Non-blocking. Emits the warning twice: to stderr for the user and, since
# v4.8.0, as hookSpecificOutput.additionalContext so the MODEL sees it
# (systemMessage/stderr never reach the model — hooks reference).
#
# Configuration via env vars (settings.json env block):
#   CLAUDE_CONTEXT_LIMIT       — override the model window (default: derived from
#                                the transcript model id — 200000 for Haiku 4.x or when
#                                CLAUDE_CODE_DISABLE_1M_CONTEXT=1, else 1000000)
#   CLAUDE_COMPACT_WARN_PCT    — warning threshold percentage (default 80)
#   CLAUDE_COMPACT_URGENT_PCT  — urgent threshold percentage (default 90)
#
# Limitations:
# - Usage reflects the previous turn; the current prompt is not yet counted.
# - Warning fires at most once per turn (UserPromptSubmit).
#
# To disable: remove from settings.json hooks, or set CLAUDE_COMPACT_WARN_PCT=999

set -uo pipefail

HOOK_INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('transcript_path',''))" 2>/dev/null || echo "")

[ -z "$TRANSCRIPT_PATH" ] && exit 0
[ ! -f "$TRANSCRIPT_PATH" ] && exit 0

# Last assistant turn's usage + model, scanning the tail of the transcript only.
read -r EST_TOKENS MODEL_LIMIT < <(tail -c 4000000 "$TRANSCRIPT_PATH" 2>/dev/null | python3 -c '
import json, sys, os
tokens, model = 0, ""
for line in sys.stdin:
    if "\"assistant\"" not in line:
        continue
    try:
        d = json.loads(line)
    except ValueError:
        continue
    if d.get("type") != "assistant" or d.get("isSidechain"):
        continue
    u = (d.get("message") or {}).get("usage") or {}
    if not u:
        continue
    tokens = int(u.get("input_tokens", 0) or 0) + int(u.get("cache_creation_input_tokens", 0) or 0) + int(u.get("cache_read_input_tokens", 0) or 0)
    model = (d.get("message") or {}).get("model") or model
small = "haiku-4" in model.lower() or os.environ.get("CLAUDE_CODE_DISABLE_1M_CONTEXT") == "1"
print(tokens, 200000 if small else 1000000)
' 2>/dev/null || echo "0 1000000")

[ "${EST_TOKENS:-0}" -le 0 ] && exit 0

CONTEXT_LIMIT=${CLAUDE_CONTEXT_LIMIT:-$MODEL_LIMIT}
WARN_PCT=${CLAUDE_COMPACT_WARN_PCT:-80}
URGENT_PCT=${CLAUDE_COMPACT_URGENT_PCT:-90}

WARN_TOKENS=$((CONTEXT_LIMIT * WARN_PCT / 100))
URGENT_TOKENS=$((CONTEXT_LIMIT * URGENT_PCT / 100))
PCT=$((EST_TOKENS * 100 / CONTEXT_LIMIT))

LEVEL=""
if [ "$EST_TOKENS" -gt "$URGENT_TOKENS" ]; then
    LEVEL="URGENT"
    cat >&2 <<EOT

⚠ URGENT — context window est. at ${PCT}% (~${EST_TOKENS} tokens / ${CONTEXT_LIMIT})
   Run NOW:  /forge compact-task
   Auto-compact will fire at ~97% if you don't.
EOT
elif [ "$EST_TOKENS" -gt "$WARN_TOKENS" ]; then
    LEVEL="WARNING"
    cat >&2 <<EOT

⚠ Context window est. at ${PCT}% (~${EST_TOKENS} tokens / ${CONTEXT_LIMIT})
   Recommended: /forge compact-task  (evidence-based 80% threshold)
   Or: /clear  (if switching to unrelated task)
EOT
fi

# Model-visible channel. Must be strictly valid JSON or nothing (fail-closed since v2.1.248).
if [ -n "$LEVEL" ]; then
    python3 - "$LEVEL" "$PCT" "$EST_TOKENS" "$CONTEXT_LIMIT" <<'PY' 2>/dev/null || true
import json, sys
level, pct, est, lim = sys.argv[1:5]
if level == "URGENT":
    advice = "Compact NOW with /forge compact-task (preserve: active task, modified files, decisions, pending TODOs). Auto-compact at ~97% loses momentum and invalidates the prompt cache."
else:
    advice = "Finish the current step, then run /forge compact-task (80% rule), or /clear if the next task is unrelated. Avoid starting a large new exploration before compacting."
msg = f"[dotforge context monitor] {level}: context window ~{pct}% used (~{est} of {lim} tokens, from last turn usage). {advice}"
print(json.dumps({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": msg}}))
PY
fi

exit 0
