#!/bin/bash
# claude-kit global sync
# Installs/updates skills, agents, and commands into ~/.claude/
# Works on Linux, macOS, and Windows (WSL/Git Bash)
# Usage: ./global/sync.sh [--dry-run]

set -euo pipefail

CLAUDE_KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=false

# --- Platform detection ---
detect_platform() {
  case "$(uname -s)" in
    Linux*)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    Darwin*)  echo "macos" ;;
    MINGW*|MSYS*|CYGWIN*) echo "gitbash" ;;
    *)        echo "unknown" ;;
  esac
}

PLATFORM=$(detect_platform)

# --- Symlink support ---
# Windows Git Bash may not support symlinks; fall back to file copy
can_symlink() {
  if [[ "$PLATFORM" == "gitbash" ]]; then
    # Test if symlinks work (requires Developer Mode or admin on Windows)
    local test_target=$(mktemp)
    local test_link="${test_target}.link"
    if ln -s "$test_target" "$test_link" 2>/dev/null; then
      rm -f "$test_link" "$test_target"
      return 0
    else
      rm -f "$test_target"
      return 1
    fi
  fi
  return 0
}

USE_SYMLINKS=true
if ! can_symlink; then
  USE_SYMLINKS=false
  echo "⚠ Symlinks not supported — using file copies instead"
  echo "  (Enable Developer Mode in Windows Settings for symlink support)"
fi

# --- Link or copy a file/directory ---
# Usage: link_item <source> <destination>
link_item() {
  local src="$1"
  local dst="$2"
  if $USE_SYMLINKS; then
    ln -s "$src" "$dst"
  elif [[ -d "$src" ]]; then
    cp -R "$src" "$dst"
  else
    cp "$src" "$dst"
  fi
}

# --- Check if destination is a valid link to source ---
# Usage: is_current_link <source> <destination>
is_current_link() {
  local src="$1"
  local dst="$2"
  if $USE_SYMLINKS; then
    [[ -L "$dst" ]] && {
      local current
      current=$(readlink "$dst" 2>/dev/null || readlink -f "$dst" 2>/dev/null || echo "")
      [[ "$current" == "$src" || "$current" == "${src%/}" ]]
    }
  else
    # For copies, check a marker file we leave behind
    [[ -f "${dst}/.claude-kit-source" ]] && [[ "$(cat "${dst}/.claude-kit-source" 2>/dev/null)" == "$src" ]]
  fi
}

# --- Remove a link or copy ---
remove_item() {
  local dst="$1"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -d "$dst" ]]; then
    rm -rf "$dst"
  else
    rm -f "$dst"
  fi
}

# --- Install item (link or copy) with source marker ---
install_item() {
  local src="$1"
  local dst="$2"
  link_item "$src" "$dst"
  # For copies, leave a marker so we can detect updates
  if ! $USE_SYMLINKS && [[ -d "$dst" ]]; then
    echo "$src" > "${dst}/.claude-kit-source"
  fi
}

# --- File owner detection (cross-platform) ---
get_file_owner() {
  local path="$1"
  case "$PLATFORM" in
    macos)
      stat -f '%Su' "$path" 2>/dev/null || echo ""
      ;;
    linux|wsl)
      stat -c '%U' "$path" 2>/dev/null || echo ""
      ;;
    *)
      echo ""
      ;;
  esac
}

# --- Resolve correct home directory ---
# When running as root (sudo, containers), $HOME may point to /root or /var/root
# instead of the actual user's home. We detect the real owner of the repo.
if [[ "${CLAUDE_HOME:-}" != "" ]]; then
  # Explicit override — respect it
  :
elif [[ "$(id -u)" == "0" ]]; then
  resolved=false

  # Method 1: SUDO_USER (set by sudo on Linux and macOS)
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    owner_home=$(eval echo "~${SUDO_USER}")
    CLAUDE_HOME="${owner_home}/.claude"
    echo "⚠ Running as root (sudo) — targeting ${SUDO_USER}'s home: ${owner_home}"
    resolved=true
  fi

  # Method 2: repo owner differs from root
  if ! $resolved; then
    repo_owner=$(get_file_owner "$CLAUDE_KIT_DIR")
    if [[ -n "$repo_owner" && "$repo_owner" != "root" ]]; then
      owner_home=$(eval echo "~${repo_owner}")
      CLAUDE_HOME="${owner_home}/.claude"
      echo "⚠ Running as root — targeting ${repo_owner}'s home: ${owner_home}"
      resolved=true
    fi
  fi

  # Method 3: infer from repo path
  if ! $resolved; then
    # Linux/WSL: /home/<user>/...
    # macOS: /Users/<user>/...
    if [[ "$CLAUDE_KIT_DIR" =~ ^/home/([^/]+)/ ]]; then
      inferred_user="${BASH_REMATCH[1]}"
      CLAUDE_HOME="/home/${inferred_user}/.claude"
      echo "⚠ Running as root — inferred target from repo path: /home/${inferred_user}"
      resolved=true
    elif [[ "$CLAUDE_KIT_DIR" =~ ^/Users/([^/]+)/ ]]; then
      inferred_user="${BASH_REMATCH[1]}"
      CLAUDE_HOME="/Users/${inferred_user}/.claude"
      echo "⚠ Running as root — inferred target from repo path: /Users/${inferred_user}"
      resolved=true
    fi
  fi

  # Fallback: use root's home
  if ! $resolved; then
    CLAUDE_HOME="${HOME}/.claude"
  fi
else
  CLAUDE_HOME="${HOME}/.claude"
fi

# --- Parse args ---
for arg in "$@"; do
  case "$arg" in
    --dry-run)
      DRY_RUN=true
      echo "=== DRY RUN — no changes will be applied ==="
      ;;
  esac
done

action() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

echo "═══ claude-kit global sync ═══"
echo "source:   ${CLAUDE_KIT_DIR}"
echo "target:   ${CLAUDE_HOME}"
echo "platform: ${PLATFORM}"
echo "method:   $( $USE_SYMLINKS && echo "symlinks" || echo "file copies" )"
echo ""

# --- Skills ---
echo "── Skills ──"
action "mkdir -p '${CLAUDE_HOME}/skills'"
for skill_dir in "${CLAUDE_KIT_DIR}/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  link="${CLAUDE_HOME}/skills/${skill_name}"
  src="${skill_dir%/}"
  if is_current_link "$src" "$link" 2>/dev/null; then
    echo "  ✓ ${skill_name} (ok)"
  elif [[ -e "$link" ]]; then
    echo "  ↻ ${skill_name} (update)"
    action "remove_item '$link' && install_item '$src' '$link'"
  else
    echo "  + ${skill_name} (new)"
    action "install_item '$src' '$link'"
  fi
done

# --- Agents ---
echo ""
echo "── Agents ──"
action "mkdir -p '${CLAUDE_HOME}/agents'"
for agent_file in "${CLAUDE_KIT_DIR}/agents"/*.md; do
  agent_name=$(basename "$agent_file")
  link="${CLAUDE_HOME}/agents/${agent_name}"
  if is_current_link "$agent_file" "$link" 2>/dev/null; then
    echo "  ✓ ${agent_name} (ok)"
  elif [[ -e "$link" ]]; then
    echo "  ↻ ${agent_name} (update)"
    action "remove_item '$link' && install_item '$agent_file' '$link'"
  else
    echo "  + ${agent_name} (new)"
    action "install_item '$agent_file' '$link'"
  fi
done

# --- Commands (all .md files in global/commands/) ---
echo ""
echo "── Commands ──"
action "mkdir -p '${CLAUDE_HOME}/commands'"
for cmd_file in "${CLAUDE_KIT_DIR}/global/commands"/*.md; do
  [[ -f "$cmd_file" ]] || continue
  cmd_name=$(basename "$cmd_file")
  cmd_dst="${CLAUDE_HOME}/commands/${cmd_name}"
  if is_current_link "$cmd_file" "$cmd_dst" 2>/dev/null; then
    echo "  ✓ ${cmd_name} (ok)"
  elif [[ -e "$cmd_dst" ]]; then
    echo "  ↻ ${cmd_name} (update)"
    action "remove_item '$cmd_dst' && install_item '$cmd_file' '$cmd_dst'"
  else
    echo "  + ${cmd_name} (new)"
    action "install_item '$cmd_file' '$cmd_dst'"
  fi
done
# Preserve other commands not from claude-kit (vault.md, etc.)

# --- Settings.json deny list ---
echo ""
echo "── Settings.json ──"
settings_file="${CLAUDE_HOME}/settings.json"
if [[ -f "$settings_file" ]]; then
  deny_count=$(python3 -c "
import json
with open('$settings_file') as f:
    d = json.load(f)
deny = d.get('permissions', {}).get('deny', [])
print(len(deny))
" 2>/dev/null || echo "error")

  if [[ "$deny_count" == "0" ]]; then
    echo "  ⚠ deny list empty — run '/forge global sync' from Claude Code to merge deny list"
  elif [[ "$deny_count" == "error" ]]; then
    echo "  ⚠ Could not read settings.json (python3 required)"
  else
    echo "  ✓ deny list has ${deny_count} entries"
  fi
else
  echo "  - Does not exist (will be created with '/forge global sync' from Claude Code)"
fi

echo ""
echo "═══ Sync complete ═══"
