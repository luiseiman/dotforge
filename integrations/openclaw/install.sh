#!/bin/bash
# Install claude-kit forge skill into OpenClaw
# Usage: bash integrations/openclaw/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_KIT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OPENCLAW_SKILLS="$HOME/.openclaw/skills"
OPENCLAW_CONFIG="$HOME/.openclaw/openclaw.json"

echo "═══ claude-kit → OpenClaw install ═══"
echo ""

# Check prerequisites
if ! command -v openclaw &>/dev/null; then
  echo "⚠ OpenClaw not installed. Installing skill anyway."
  echo "  Install OpenClaw: npm install -g openclaw@latest"
  echo ""
fi

# Claude CLI is optional — bridge commands need it, but read-only commands work without
if ! command -v claude &>/dev/null; then
  echo "⚠ Claude Code CLI not found."
  echo "  Bridge commands (/forge audit, sync, etc.) require it."
  echo "  Read-only commands (/forge status, version) work without it."
  echo ""
fi

# Step 1: Install SKILL.md
echo "── Step 1: Install skill file ──"
mkdir -p "$OPENCLAW_SKILLS/forge"

if ln -sf "$SCRIPT_DIR/SKILL.md" "$OPENCLAW_SKILLS/forge/SKILL.md" 2>/dev/null; then
  echo "✓ Installed forge skill as symlink → $OPENCLAW_SKILLS/forge/SKILL.md"
else
  cp "$SCRIPT_DIR/SKILL.md" "$OPENCLAW_SKILLS/forge/SKILL.md"
  echo "✓ Installed forge skill as copy → $OPENCLAW_SKILLS/forge/SKILL.md"
fi

# Step 2: Register in openclaw.json
echo ""
echo "── Step 2: Register in openclaw.json ──"

if [ -f "$OPENCLAW_CONFIG" ]; then
  # Check if forge is already registered
  if python3 -c "
import json
with open('$OPENCLAW_CONFIG') as f:
    cfg = json.load(f)
entries = cfg.get('skills', {}).get('entries', {})
if 'forge' in entries:
    print('already_registered')
else:
    print('needs_registration')
" 2>/dev/null | grep -q "already_registered"; then
    echo "✓ forge already registered in openclaw.json"
  else
    # Add forge to skills.entries
    python3 -c "
import json

with open('$OPENCLAW_CONFIG') as f:
    cfg = json.load(f)

if 'skills' not in cfg:
    cfg['skills'] = {}
if 'entries' not in cfg['skills']:
    cfg['skills']['entries'] = {}

cfg['skills']['entries']['forge'] = {
    'enabled': True
}

with open('$OPENCLAW_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)

print('done')
" 2>/dev/null

    if [ $? -eq 0 ]; then
      echo "✓ Registered forge in openclaw.json (skills.entries.forge.enabled = true)"
    else
      echo "✗ Could not auto-register. Add manually to $OPENCLAW_CONFIG:"
      echo '  "skills": { "entries": { "forge": { "enabled": true } } }'
    fi
  fi
else
  echo "⚠ openclaw.json not found at $OPENCLAW_CONFIG"
  echo "  After OpenClaw onboard, add to openclaw.json:"
  echo '  "skills": { "entries": { "forge": { "enabled": true } } }'
fi

# Step 3: Set CLAUDE_KIT_DIR
echo ""
echo "── Step 3: Environment variable ──"

SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if grep -q "CLAUDE_KIT_DIR" "$SHELL_RC" 2>/dev/null; then
  echo "✓ CLAUDE_KIT_DIR already set in $SHELL_RC"
else
  echo "export CLAUDE_KIT_DIR=\"$CLAUDE_KIT_DIR\"" >> "$SHELL_RC"
  echo "✓ Added CLAUDE_KIT_DIR=$CLAUDE_KIT_DIR to $SHELL_RC"
  export CLAUDE_KIT_DIR="$CLAUDE_KIT_DIR"
fi

# Step 4: Verify
echo ""
echo "── Verification ──"
echo "Skill file:    $([ -f "$OPENCLAW_SKILLS/forge/SKILL.md" ] && echo '✓' || echo '✗')"
echo "Config entry:  $(python3 -c "import json; cfg=json.load(open('$OPENCLAW_CONFIG')); print('✓' if 'forge' in cfg.get('skills',{}).get('entries',{}) else '✗')" 2>/dev/null || echo '?')"
echo "CLAUDE_KIT_DIR: $([ -n "$CLAUDE_KIT_DIR" ] && echo "✓ $CLAUDE_KIT_DIR" || echo '✗ not set')"
echo "Claude CLI:    $(command -v claude &>/dev/null && echo '✓' || echo '⚠ not found (bridge commands disabled)')"
echo ""
echo "── Next steps ──"
echo "1. Restart OpenClaw: openclaw restart (or systemctl restart openclaw)"
echo "2. Test: /forge status"
echo ""
