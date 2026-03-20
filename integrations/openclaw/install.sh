#!/bin/bash
# Install claude-kit forge skill into OpenClaw
# Usage: bash integrations/openclaw/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_SKILLS="$HOME/.openclaw/skills"

# Check prerequisites
if ! command -v claude &>/dev/null; then
  echo "Error: Claude Code CLI not found."
  echo "Install from: https://docs.anthropic.com/en/docs/claude-code"
  exit 1
fi

if ! command -v openclaw &>/dev/null; then
  echo "Warning: OpenClaw not installed. Installing skill anyway."
  echo "Install OpenClaw: npm install -g openclaw@latest"
fi

# Create skills directory if needed
mkdir -p "$OPENCLAW_SKILLS/forge"

# Symlink or copy
if ln -sf "$SCRIPT_DIR/SKILL.md" "$OPENCLAW_SKILLS/forge/SKILL.md" 2>/dev/null; then
  echo "✓ Installed forge skill as symlink"
else
  cp "$SCRIPT_DIR/SKILL.md" "$OPENCLAW_SKILLS/forge/SKILL.md"
  echo "✓ Installed forge skill as copy (symlinks not supported)"
fi

# Check CLAUDE_KIT_DIR
CLAUDE_KIT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
echo ""
echo "Add to your shell profile (~/.zshrc or ~/.bashrc):"
echo "  export CLAUDE_KIT_DIR=\"$CLAUDE_KIT_DIR\""
echo ""
echo "Then restart OpenClaw to load the skill."
echo "Usage: /forge status | /forge audit project:<name>"
