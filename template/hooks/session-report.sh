#!/bin/bash
# Stop hook: generate session report on session end
# Matcher: (none — Stop event)
# Configurable: set FORGE_SESSION_REPORT=true to enable

[[ "${FORGE_SESSION_REPORT:-false}" != "true" ]] && exit 0

REPORT_FILE="SESSION_REPORT.md"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)

# Collect git changes from this session (last hour of commits)
RECENT_FILES=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | head -20)
RECENT_COMMITS=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -10)

# Count files by type
MODIFIED_COUNT=$(echo "$RECENT_FILES" | grep -c '.' 2>/dev/null || echo "0")

# Check if tests were run (look for recent test output markers)
TESTS_RAN="unknown"
if git log --oneline --since="1 hour ago" 2>/dev/null | grep -qiE 'test|spec'; then
  TESTS_RAN="yes (referenced in commits)"
fi

# Check for errors logged
ERROR_COUNT=0
if [[ -f "CLAUDE_ERRORS.md" ]]; then
  ERROR_COUNT=$(grep -c "| $DATE |" CLAUDE_ERRORS.md 2>/dev/null || echo "0")
fi

# Append to report
cat >> "$REPORT_FILE" << REPORT

---

## Session: $DATE $TIME

### Files touched
$MODIFIED_COUNT files modified

$(echo "$RECENT_FILES" | sed 's/^/- /' 2>/dev/null)

### Commits
$(echo "$RECENT_COMMITS" | sed 's/^/- /' 2>/dev/null)

### Tests
$TESTS_RAN

### Errors logged today
$ERROR_COUNT new entries in CLAUDE_ERRORS.md
REPORT

exit 0
