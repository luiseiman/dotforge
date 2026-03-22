#!/usr/bin/env bash
# mcp/update-versions.sh — query npm for latest MCP server versions and update config.json files
# Usage: ./mcp/update-versions.sh [--dry-run]
# Requires: npm, python3, jq (optional — falls back to python3 for JSON editing)

set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

MCP_DIR="$(cd "$(dirname "$0")" && pwd)"

declare -a PACKAGES=(
  "mcp/github:@modelcontextprotocol/server-github"
  "mcp/postgres:@modelcontextprotocol/server-postgres"
  "mcp/redis:@modelcontextprotocol/server-redis"
  "mcp/slack:@modelcontextprotocol/server-slack"
  "mcp/supabase:@supabase/mcp-server-supabase"
)

REPO_DIR="$(dirname "$MCP_DIR")"

echo "Checking MCP server versions on npm..."
echo ""

UPDATED=0
ERRORS=0

for entry in "${PACKAGES[@]}"; do
  DIR="${entry%%:*}"
  PKG="${entry##*:}"
  CONFIG="$REPO_DIR/$DIR/config.json"

  if [[ ! -f "$CONFIG" ]]; then
    echo "  SKIP  $PKG — config.json not found at $CONFIG"
    continue
  fi

  # Get latest version from npm
  LATEST=$(npm view "$PKG" version 2>/dev/null || echo "")
  if [[ -z "$LATEST" ]]; then
    echo "  ERROR $PKG — npm view failed (package not found?)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Get current pinned version from config.json
  CURRENT=$(python3 -c "
import json, re, sys
d = json.load(open('$CONFIG'))
# Try _verified_with field first
vw = d.get('_verified_with', '')
m = re.search(r'@([\w.\-]+)$', vw)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")

  if [[ "$CURRENT" == "$LATEST" ]]; then
    echo "  OK    $PKG@$LATEST (already pinned)"
    continue
  fi

  echo "  UPDATE $PKG: $CURRENT → $LATEST"

  if [[ "$DRY_RUN" == "1" ]]; then
    continue
  fi

  # Update config.json: replace old version with new in _verified_with and args
  python3 - "$CONFIG" "$PKG" "$CURRENT" "$LATEST" <<'PYEOF'
import json, sys, re

config_path, pkg, old_ver, new_ver = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]

with open(config_path) as f:
    raw = f.read()

# Replace version in _verified_with value
raw = raw.replace(f'{pkg}@{old_ver}', f'{pkg}@{new_ver}')

# Also handle bare package name in args (no version suffix)
# e.g. "@modelcontextprotocol/server-postgres" → "@modelcontextprotocol/server-postgres@0.6.2"
# Only replace if the arg exactly matches the package name without version
import json as _json
d = _json.loads(raw)

def patch_args(obj):
    if isinstance(obj, dict):
        if 'args' in obj and isinstance(obj['args'], list):
            obj['args'] = [
                f'{pkg}@{new_ver}' if a == pkg else a
                for a in obj['args']
            ]
        for v in obj.values():
            patch_args(v)

patch_args(d)
with open(config_path, 'w') as f:
    _json.dump(d, f, indent=2)
    f.write('\n')
PYEOF

  UPDATED=$((UPDATED + 1))
done

echo ""
if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry run — no files modified."
else
  echo "Done. $UPDATED file(s) updated, $ERRORS error(s)."
fi
