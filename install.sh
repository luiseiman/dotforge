#!/usr/bin/env bash
# dotforge installer — one-liner: curl -fsSL https://raw.githubusercontent.com/luiseiman/dotforge/main/install.sh | bash
set -euo pipefail

VERSION="2.8.1"
REPO="https://github.com/luiseiman/dotforge.git"
DEFAULT_DIR="$HOME/.dotforge"

# ── Platform detection ──
detect_platform() {
  case "$(uname -s)" in
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi ;;
    Darwin*)  echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "gitbash" ;;
    *)        echo "unsupported" ;;
  esac
}

PLATFORM=$(detect_platform)

if [[ "$PLATFORM" == "unsupported" ]]; then
  echo "✗ Unsupported platform. dotforge requires bash (macOS/Linux/WSL)."
  exit 1
fi

if [[ "$PLATFORM" == "gitbash" ]]; then
  echo "⚠ Git Bash detected. dotforge works but WSL is recommended on Windows."
  echo "  Ensure jq and python3 are in PATH for full hook support."
  echo ""
fi

echo "═══ dotforge installer v${VERSION} ═══"
echo "Platform: ${PLATFORM}"
echo ""

# ── Determine install directory ──
DOTFORGE_DIR="${DOTFORGE_DIR:-$DEFAULT_DIR}"

# ── Install or update ──
if [[ -d "$DOTFORGE_DIR/.git" ]]; then
  echo "Updating existing installation at $DOTFORGE_DIR..."
  git -C "$DOTFORGE_DIR" pull --ff-only 2>&1 || {
    echo "⚠ git pull failed. Run manually: cd $DOTFORGE_DIR && git pull"
    exit 1
  }
else
  echo "Installing dotforge to $DOTFORGE_DIR..."
  git clone "$REPO" "$DOTFORGE_DIR" 2>&1 || {
    echo "✗ git clone failed. Check network and try again."
    exit 1
  }
fi

# ── Run global sync ──
echo ""
echo "Running global sync..."
bash "$DOTFORGE_DIR/global/sync.sh" 2>&1

# ── Add DOTFORGE_DIR to shell profile ──
EXPORT_LINE="export DOTFORGE_DIR=\"$DOTFORGE_DIR\""
PROFILE=""

for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
  if [[ -f "$rc" ]]; then
    PROFILE="$rc"
    break
  fi
done

if [[ -n "$PROFILE" ]]; then
  if ! grep -q "DOTFORGE_DIR" "$PROFILE" 2>/dev/null; then
    echo "" >> "$PROFILE"
    echo "# dotforge" >> "$PROFILE"
    echo "$EXPORT_LINE" >> "$PROFILE"
    echo "✓ Added DOTFORGE_DIR to $PROFILE"
  else
    echo "✓ DOTFORGE_DIR already in $PROFILE"
  fi
else
  echo "⚠ No shell profile found. Add manually: $EXPORT_LINE"
fi

# ── Summary ──
INSTALLED_VERSION=$(cat "$DOTFORGE_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')
SKILL_COUNT=$(ls -d "$HOME/.claude/skills"/*/ 2>/dev/null | wc -l | tr -d ' ')
AGENT_COUNT=$(ls "$HOME/.claude/agents"/*.md 2>/dev/null | wc -l | tr -d ' ')
CMD_COUNT=$(ls "$HOME/.claude/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "═══ dotforge installed ═══"
echo "  Version:  ${INSTALLED_VERSION}"
echo "  Skills:   ${SKILL_COUNT}"
echo "  Agents:   ${AGENT_COUNT}"
echo "  Commands: ${CMD_COUNT}"
echo "  Location: ${DOTFORGE_DIR}"
echo ""
echo "Next step: open a project and run /forge init"
