#!/usr/bin/env bash
# fix-session-metrics.sh — propagate the corrected session-report.sh to every
# registered project and delete the malformed JSON metrics files.
#
# Fixes bug discovered 2026-04-21: every JSON under ~/.claude/metrics/<slug>/*.json
# was malformed due to `grep -c ... || echo "0"` double-output + arithmetic
# cascade on corrupted previous files.
#
# Usage:
#   bash scripts/fix-session-metrics.sh           # apply
#   bash scripts/fix-session-metrics.sh --dry-run # preview
#
# Idempotent. Safe to re-run.

set -u

DOTFORGE_DIR=$(cd "$(dirname "$0")/.." && pwd)
TEMPLATE_HOOK="$DOTFORGE_DIR/template/hooks/session-report.sh"
export REGISTRY="$DOTFORGE_DIR/registry/projects.local.yml"
METRICS_ROOT="$HOME/.claude/metrics"
DRY_RUN=false

[ "${1:-}" = "--dry-run" ] && DRY_RUN=true

if [ ! -f "$TEMPLATE_HOOK" ]; then
    echo "ERROR: $TEMPLATE_HOOK not found" >&2
    exit 2
fi
if [ ! -f "$REGISTRY" ]; then
    echo "ERROR: $REGISTRY not found" >&2
    exit 2
fi

_is_broken() {
    local f="$1"
    [ -f "$f" ] || return 1
    grep -q '|| echo "0"' "$f" 2>/dev/null
}

_slug() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g'
}

PROJECTS=$(python3 - <<'PYEOF'
import yaml, os
with open(os.environ["REGISTRY"]) as f:
    d = yaml.safe_load(f)
for p in d["projects"]:
    print(f"{p['name']}\t{p['path']}")
PYEOF
)

if [ -z "$PROJECTS" ]; then
    echo "No projects found in registry."
    exit 0
fi

printf '%s\n' "═══ FIX SESSION METRICS ═══"
printf 'Template: %s\n' "$TEMPLATE_HOOK"
printf 'Registry: %s\n' "$REGISTRY"
printf 'Dry-run:  %s\n\n' "$DRY_RUN"

PATCHED=0
SKIPPED_CLEAN=0
SKIPPED_MISSING=0
CLEANED=0

while IFS=$'\t' read -r NAME RAW_PATH; do
    [ -z "$NAME" ] && continue

    PROJ_PATH="$RAW_PATH"
    if [ "$PROJ_PATH" = "." ]; then
        PROJ_PATH="$DOTFORGE_DIR"
    fi

    HOOK="$PROJ_PATH/.claude/hooks/session-report.sh"
    SLUG=$(_slug "$NAME")
    METRICS_DIR="$METRICS_ROOT/$SLUG"

    printf '── %-22s ' "$NAME"

    if [ ! -d "$PROJ_PATH" ]; then
        printf 'SKIP (path not found: %s)\n' "$PROJ_PATH"
        SKIPPED_MISSING=$((SKIPPED_MISSING + 1))
        continue
    fi

    if [ ! -f "$HOOK" ]; then
        printf 'no session-report.sh — skipped\n'
        SKIPPED_MISSING=$((SKIPPED_MISSING + 1))
        continue
    fi

    if _is_broken "$HOOK"; then
        if $DRY_RUN; then
            printf 'would patch hook'
        else
            ORIG_SHEBANG=$(head -n 1 "$HOOK")
            cp "$TEMPLATE_HOOK" "$HOOK"
            if [ "$ORIG_SHEBANG" != "$(head -n 1 "$TEMPLATE_HOOK")" ] && [ -n "$ORIG_SHEBANG" ]; then
                sed -i.bak "1s|.*|$ORIG_SHEBANG|" "$HOOK"
                rm -f "$HOOK.bak"
            fi
            chmod +x "$HOOK"
            printf 'patched'
        fi
        PATCHED=$((PATCHED + 1))
    else
        printf 'hook clean (no fix needed)'
        SKIPPED_CLEAN=$((SKIPPED_CLEAN + 1))
    fi

    if [ -d "$METRICS_DIR" ]; then
        MALFORMED=0
        for jf in "$METRICS_DIR"/*.json; do
            [ -f "$jf" ] || continue
            if ! jq -e . "$jf" >/dev/null 2>&1; then
                if ! $DRY_RUN; then
                    rm -f "$jf"
                fi
                MALFORMED=$((MALFORMED + 1))
            fi
        done
        if [ "$MALFORMED" -gt 0 ]; then
            printf ' | cleaned %s malformed json' "$MALFORMED"
            CLEANED=$((CLEANED + MALFORMED))
        fi
    fi
    printf '\n'
done <<< "$PROJECTS"

printf '\n═══ SUMMARY ═══\n'
printf 'Hooks patched:        %d\n' "$PATCHED"
printf 'Hooks already clean:  %d\n' "$SKIPPED_CLEAN"
printf 'Projects skipped:     %d\n' "$SKIPPED_MISSING"
printf 'Malformed JSON files cleaned: %d\n' "$CLEANED"

if $DRY_RUN; then
    printf '\n(dry-run: no changes written)\n'
fi
