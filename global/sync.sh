#!/bin/bash
# claude-kit global sync
# Instala/actualiza symlinks de skills, agents y commands en ~/.claude/
# Uso: ./global/sync.sh [--dry-run]

set -euo pipefail

CLAUDE_KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=false

# Resolve the correct home directory.
# If running as root (e.g. via sudo or in containers), $HOME may point to /root
# instead of the actual user's home. We detect the real owner of the repo.
if [[ "${CLAUDE_HOME:-}" != "" ]]; then
  # Explicit override — respect it
  :
elif [[ "$(id -u)" == "0" ]]; then
  # Running as root (sudo, container, etc.) — try to find the real user's home
  resolved=false

  # Method 1: SUDO_USER (set by sudo)
  if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    owner_home=$(eval echo "~${SUDO_USER}")
    CLAUDE_HOME="${owner_home}/.claude"
    echo "⚠ Running as root (sudo) — targeting ${SUDO_USER}'s home: ${owner_home}"
    resolved=true
  fi

  # Method 2: repo owner differs from root
  if ! $resolved; then
    repo_owner=$(stat -c '%U' "$CLAUDE_KIT_DIR" 2>/dev/null || stat -f '%Su' "$CLAUDE_KIT_DIR" 2>/dev/null)
    if [[ -n "$repo_owner" && "$repo_owner" != "root" ]]; then
      owner_home=$(eval echo "~${repo_owner}")
      CLAUDE_HOME="${owner_home}/.claude"
      echo "⚠ Running as root — targeting ${repo_owner}'s home: ${owner_home}"
      resolved=true
    fi
  fi

  # Method 3: repo path is under /home/<user>/ (common in containers)
  if ! $resolved && [[ "$CLAUDE_KIT_DIR" =~ ^/home/([^/]+)/ ]]; then
    inferred_user="${BASH_REMATCH[1]}"
    CLAUDE_HOME="/home/${inferred_user}/.claude"
    echo "⚠ Running as root — inferred target from repo path: /home/${inferred_user}"
    resolved=true
  fi

  # Fallback: use root's home
  if ! $resolved; then
    CLAUDE_HOME="${HOME}/.claude"
  fi
else
  CLAUDE_HOME="${HOME}/.claude"
fi

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "=== DRY RUN — no se aplicarán cambios ==="
fi

action() {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

echo "═══ claude-kit global sync ═══"
echo "claude-kit: ${CLAUDE_KIT_DIR}"
echo "target:     ${CLAUDE_HOME}"
echo ""

# --- Skills ---
echo "── Skills ──"
mkdir -p "${CLAUDE_HOME}/skills"
for skill_dir in "${CLAUDE_KIT_DIR}/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  link="${CLAUDE_HOME}/skills/${skill_name}"
  if [[ -L "$link" ]]; then
    current=$(readlink "$link")
    if [[ "$current" == "$skill_dir" || "$current" == "${skill_dir%/}" ]]; then
      echo "  ✓ ${skill_name} (ok)"
    else
      echo "  ↻ ${skill_name} (update: ${current} → ${skill_dir})"
      action "rm '$link' && ln -s '${skill_dir%/}' '$link'"
    fi
  elif [[ -e "$link" ]]; then
    echo "  ⚠ ${skill_name} (exists but not a symlink — skipping)"
  else
    echo "  + ${skill_name} (new)"
    action "ln -s '${skill_dir%/}' '$link'"
  fi
done

# --- Agents ---
echo ""
echo "── Agents ──"
mkdir -p "${CLAUDE_HOME}/agents"
for agent_file in "${CLAUDE_KIT_DIR}/agents"/*.md; do
  agent_name=$(basename "$agent_file")
  link="${CLAUDE_HOME}/agents/${agent_name}"
  if [[ -L "$link" ]]; then
    current=$(readlink "$link")
    if [[ "$current" == "$agent_file" ]]; then
      echo "  ✓ ${agent_name} (ok)"
    else
      echo "  ↻ ${agent_name} (update)"
      action "rm '$link' && ln -s '$agent_file' '$link'"
    fi
  elif [[ -e "$link" ]]; then
    echo "  ⚠ ${agent_name} (exists but not a symlink — skipping)"
  else
    echo "  + ${agent_name} (new)"
    action "ln -s '$agent_file' '$link'"
  fi
done

# --- Commands (forge.md) ---
echo ""
echo "── Commands ──"
mkdir -p "${CLAUDE_HOME}/commands"
forge_src="${CLAUDE_KIT_DIR}/global/commands/forge.md"
forge_dst="${CLAUDE_HOME}/commands/forge.md"
if [[ -f "$forge_src" ]]; then
  if [[ -L "$forge_dst" ]]; then
    echo "  ✓ forge.md (symlink ok)"
  elif [[ -f "$forge_dst" ]]; then
    echo "  ↻ forge.md (replacing file with symlink)"
    action "rm '$forge_dst' && ln -s '$forge_src' '$forge_dst'"
  else
    echo "  + forge.md (new)"
    action "ln -s '$forge_src' '$forge_dst'"
  fi
else
  echo "  - forge.md (source not found, skipping)"
fi
# Preserve other commands (vault.md, etc.) — don't touch them

# --- Settings.json deny list ---
echo ""
echo "── Settings.json ──"
settings_file="${CLAUDE_HOME}/settings.json"
if [[ -f "$settings_file" ]]; then
  # Check if deny list is empty
  deny_count=$(python3 -c "
import json
with open('$settings_file') as f:
    d = json.load(f)
deny = d.get('permissions', {}).get('deny', [])
print(len(deny))
" 2>/dev/null || echo "error")

  if [[ "$deny_count" == "0" ]]; then
    echo "  ⚠ deny list VACÍA — esto contradice la filosofía de seguridad de claude-kit"
    echo "    Ejecutá '/forge global sync' desde Claude Code para mergear deny list"
  elif [[ "$deny_count" == "error" ]]; then
    echo "  ⚠ No se pudo leer settings.json"
  else
    echo "  ✓ deny list tiene ${deny_count} entries"
  fi
else
  echo "  - No existe (se creará con /forge global sync desde Claude Code)"
fi

echo ""
echo "═══ Sync completo ═══"
