#!/usr/bin/env bash
# on/off actions: project scope mutates index.yaml; session scope mutates state.json.
set -u
. "$(dirname "$0")/_helpers.sh"
trap cli_test_cleanup EXIT

cli_test_init

# ---------- Project scope ----------

# Verify initial state
initial=$(yaml_get "${FORGE_BEHAVIORS_DIR}/index.yaml" "behaviors.0.enabled")
assert_eq "true" "$initial" "initial enabled in index.yaml" || exit 1

# Disable at project scope
bash "$CLI" off search-first --project >/dev/null || { printf 'FAIL: off project\n' >&2; exit 1; }
after_off=$(yaml_get "${FORGE_BEHAVIORS_DIR}/index.yaml" "behaviors.0.enabled")
assert_eq "false" "$after_off" "project off → index.yaml enabled=false" || exit 1

# Re-enable
bash "$CLI" on search-first --project >/dev/null || { printf 'FAIL: on project\n' >&2; exit 1; }
after_on=$(yaml_get "${FORGE_BEHAVIORS_DIR}/index.yaml" "behaviors.0.enabled")
assert_eq "true" "$after_on" "project on → index.yaml enabled=true" || exit 1

# Default scope is project
bash "$CLI" off search-first >/dev/null
default_scope=$(yaml_get "${FORGE_BEHAVIORS_DIR}/index.yaml" "behaviors.0.enabled")
assert_eq "false" "$default_scope" "default scope is project" || exit 1
bash "$CLI" on search-first >/dev/null  # restore

# Unknown behavior id → error
if bash "$CLI" off nonexistent --project 2>/dev/null; then
    printf 'FAIL: off with unknown id should fail\n' >&2
    exit 1
fi

# ---------- Session scope ----------

SID="sess-on-off-test"

# Session off writes to state.json
bash "$CLI" off search-first --session "$SID" >/dev/null || { printf 'FAIL: off session\n' >&2; exit 1; }
val=$(jq -r --arg sid "$SID" '.sessions[$sid].behavior_overrides["search-first"].enabled' "$FORGE_STATE_FILE")
assert_eq "false" "$val" "session off → state.json enabled=false" || exit 1

# forge_behavior_session_is_disabled agrees
if ! forge_behavior_session_is_disabled "$SID" "search-first"; then
    printf 'FAIL: session_is_disabled should return 0 after off\n' >&2
    exit 1
fi

# Session on clears the override
bash "$CLI" on search-first --session "$SID" >/dev/null
cleared=$(jq -r --arg sid "$SID" '.sessions[$sid].behavior_overrides["search-first"] // "null"' "$FORGE_STATE_FILE")
assert_eq "null" "$cleared" "session on → override removed" || exit 1

if forge_behavior_session_is_disabled "$SID" "search-first"; then
    printf 'FAIL: session_is_disabled should return 1 after on\n' >&2
    exit 1
fi

# --session without SESSION_ID errors
if bash "$CLI" off search-first --session 2>/dev/null; then
    printf 'FAIL: --session without id should fail\n' >&2
    exit 1
fi

test_pass "test_on_off"
