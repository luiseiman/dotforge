#!/usr/bin/env bash
# Sessions with last_accessed_at older than 24h get purged.
set -u
. "$(dirname "$0")/_helpers.sh"
trap test_cleanup EXIT

test_init

# Inject two sessions: one fresh, one expired.
OLD_TS="2020-01-01T00:00:00Z"
NOW_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

cat > "$FORGE_STATE_FILE" <<EOF
{
  "schema_version": "1",
  "sessions": {
    "fresh-session": {
      "created_at": "${NOW_TS}",
      "last_accessed_at": "${NOW_TS}",
      "flags": {},
      "behaviors": {}
    },
    "expired-session": {
      "created_at": "${OLD_TS}",
      "last_accessed_at": "${OLD_TS}",
      "flags": {"should_vanish": {"set_at": "${OLD_TS}"}},
      "behaviors": {}
    }
  }
}
EOF

# Trigger a mutation to force purge path
forge_counter_increment "fresh-session" "dummy-behavior" "Read" >/dev/null

# fresh-session still there
fresh=$(jq -r '.sessions["fresh-session"] // empty' "$FORGE_STATE_FILE")
if [ -z "$fresh" ]; then
    printf 'FAIL: fresh-session was incorrectly purged\n' >&2
    exit 1
fi

# expired-session gone
expired=$(jq -r '.sessions["expired-session"] // empty' "$FORGE_STATE_FILE")
if [ -n "$expired" ]; then
    printf 'FAIL: expired-session should have been purged\n  got: %s\n' "$expired" >&2
    exit 1
fi

test_pass "test_ttl"
