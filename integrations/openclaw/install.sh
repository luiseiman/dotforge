#!/bin/bash
# Install claude-kit forge skill into OpenClaw
# Usage: bash integrations/openclaw/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_KIT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
INTEGRATIONS_DIR="$CLAUDE_KIT_DIR/integrations"
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"
OPENCLAW_ENV="$HOME/.openclaw/.env"

echo "═══ claude-kit → OpenClaw install ═══"
echo ""

# Check prerequisites
if ! command -v openclaw &>/dev/null; then
  echo "⚠ OpenClaw not installed."
  echo "  Install: npm install -g openclaw@latest && openclaw onboard --install-daemon"
  echo ""
fi

if ! command -v claude &>/dev/null; then
  echo "⚠ Claude Code CLI not found."
  echo "  Bridge commands (/forge audit, sync, etc.) require it."
  echo ""
fi

# Step 1: Register extraDirs in openclaw.json
# OpenClaw rejects symlinks that resolve outside its root.
# Instead, we tell OpenClaw to load skills directly from integrations/.
echo "── Step 1: Register skill directory ──"

if [ -f "$OPENCLAW_CONFIG" ]; then
  python3 -c "
import json

with open('$OPENCLAW_CONFIG') as f:
    cfg = json.load(f)

# Add extraDirs under skills.load
if 'skills' not in cfg:
    cfg['skills'] = {}
if 'load' not in cfg['skills']:
    cfg['skills']['load'] = {}

extra = cfg['skills']['load'].get('extraDirs', [])
if '$INTEGRATIONS_DIR' not in extra:
    extra.append('$INTEGRATIONS_DIR')
    cfg['skills']['load']['extraDirs'] = extra
    with open('$OPENCLAW_CONFIG', 'w') as f:
        json.dump(cfg, f, indent=2)
    print('added')
else:
    print('exists')
" 2>/dev/null

  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    echo "✓ Registered $INTEGRATIONS_DIR in openclaw.json (skills.load.extraDirs)"
  else
    echo "✗ Could not update openclaw.json. Add manually:"
    echo "  \"skills\": { \"load\": { \"extraDirs\": [\"$INTEGRATIONS_DIR\"] } }"
  fi
else
  echo "⚠ openclaw.json not found at $OPENCLAW_CONFIG"
  echo "  Run 'openclaw onboard' first, then re-run this script."
fi

# Step 2: Set CLAUDE_KIT_DIR in OpenClaw's .env
# OpenClaw doesn't inherit shell environment — use its own .env file.
echo ""
echo "── Step 2: Set CLAUDE_KIT_DIR ──"

mkdir -p "$(dirname "$OPENCLAW_ENV")"

if [ -f "$OPENCLAW_ENV" ] && grep -q "CLAUDE_KIT_DIR" "$OPENCLAW_ENV" 2>/dev/null; then
  echo "✓ CLAUDE_KIT_DIR already set in $OPENCLAW_ENV"
else
  echo "CLAUDE_KIT_DIR=$CLAUDE_KIT_DIR" >> "$OPENCLAW_ENV"
  echo "✓ Added CLAUDE_KIT_DIR=$CLAUDE_KIT_DIR to $OPENCLAW_ENV"
fi

# Step 3: Clean up legacy symlinks (from older install.sh versions)
echo ""
echo "── Step 3: Cleanup ──"

LEGACY_SKILL="$HOME/.openclaw/skills/forge"
if [ -d "$LEGACY_SKILL" ] || [ -L "$LEGACY_SKILL/SKILL.md" ]; then
  rm -rf "$LEGACY_SKILL"
  echo "✓ Removed legacy symlink at $LEGACY_SKILL"
else
  echo "✓ No legacy install to clean"
fi

# Step 4: Verify
echo ""
echo "── Verification ──"
echo "Skill file:     $([ -f "$INTEGRATIONS_DIR/openclaw/SKILL.md" ] && echo '✓' || echo '✗')"
echo "Config entry:   $(python3 -c "import json; cfg=json.load(open('$OPENCLAW_CONFIG')); dirs=cfg.get('skills',{}).get('load',{}).get('extraDirs',[]); print('✓' if '$INTEGRATIONS_DIR' in dirs else '✗')" 2>/dev/null || echo '?')"
echo "CLAUDE_KIT_DIR: $(grep -q 'CLAUDE_KIT_DIR' "$OPENCLAW_ENV" 2>/dev/null && echo "✓ $(grep CLAUDE_KIT_DIR "$OPENCLAW_ENV" | head -1)" || echo '✗')"
echo "Claude CLI:     $(command -v claude &>/dev/null && echo '✓' || echo '⚠ not found (bridge commands disabled)')"

echo ""
echo "── Next steps ──"
echo "1. Restart OpenClaw: openclaw restart"
echo "2. Verify: openclaw skills list 2>&1 | grep forge"
echo "3. Test: /forge status"
echo ""
