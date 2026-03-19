#!/bin/bash
# Stop hook: detecta cambios en .claude/ al final de una sesión
# Si hay archivos .claude/ modificados en la sesión, genera una nota
# en practices/inbox/ para que /forge update la procese.
#
# === INSTALLATION ===
# 1. Set CLAUDE_KIT_DIR to your clone location (global/sync.sh does this)
# 2. Make executable: chmod +x hooks/detect-claude-changes.sh
# 3. Add to ~/.claude/settings.json:
#    {
#      "hooks": {
#        "Stop": [
#          {
#            "matcher": "",
#            "hooks": [
#              {
#                "type": "command",
#                "command": "$CLAUDE_KIT_DIR/hooks/detect-claude-changes.sh"
#              }
#            ]
#          }
#        ]
#      }
#    }
# ========================

# Resolve CLAUDE_KIT_DIR: use env var if set, otherwise default to script's parent
CLAUDE_KIT_DIR="${CLAUDE_KIT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
INBOX_DIR="$CLAUDE_KIT_DIR/practices/inbox"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
TODAY="$(date +%Y-%m-%d)"

# No ejecutar dentro de claude-kit mismo
if [[ "$PROJECT_DIR" == "$CLAUDE_KIT_DIR"* ]]; then
  exit 0
fi

# Buscar archivos .claude/ modificados en las últimas 2 horas
CHANGED_FILES=$(find "$PROJECT_DIR/.claude" -name "*.md" -o -name "*.sh" -o -name "*.json" 2>/dev/null | while read f; do
  if [[ -f "$f" ]] && find "$f" -mmin -120 -print -quit 2>/dev/null | grep -q .; then
    echo "$f"
  fi
done)

if [[ -z "$CHANGED_FILES" ]]; then
  exit 0
fi

# Verificar que el inbox existe
mkdir -p "$INBOX_DIR"

# Generar nota en inbox
SLUG="$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')-session-changes"
OUTFILE="$INBOX_DIR/${TODAY}-${SLUG}.md"

# No duplicar si ya existe una de hoy para este proyecto
if [[ -f "$OUTFILE" ]]; then
  exit 0
fi

FILE_LIST=$(echo "$CHANGED_FILES" | sed "s|$PROJECT_DIR/||g" | sort)
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')

cat > "$OUTFILE" << HEREDOC
---
id: practice-${TODAY}-${SLUG}
title: "Cambios en .claude/ detectados en ${PROJECT_NAME}"
source: "hook post-sesión — ${PROJECT_NAME}"
source_type: experience
discovered: ${TODAY}
status: inbox
tags: [auto-detected, ${PROJECT_NAME}]
tested_in: ${PROJECT_NAME}
incorporated_in: []
replaced_by: null
---

## Descripción
Se detectaron ${FILE_COUNT} archivo(s) modificados en .claude/ del proyecto ${PROJECT_NAME} durante la sesión.

## Archivos modificados
${FILE_LIST}

## Evaluación necesaria
Revisar si estos cambios contienen patrones, reglas, o configuraciones que deberían generalizarse a claude-kit.

## Decisión
Pendiente — evaluar en próximo /forge update
HEREDOC

exit 0
