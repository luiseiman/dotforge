#!/usr/bin/env bash
# forge-doctor — classify dotforge-managed files in a project against
# .claude/.forge-manifest.json so /forge sync, /forge diff and session-startup
# can decide per file instead of guessing.
#
# Usage: scripts/forge-doctor.sh [PROJECT_DIR] [--json]
#
# Classes:
#   intact    — on disk, sha256 equals the manifest hash → sync may overwrite silently
#   drifted   — on disk, hash differs → sync must show a diff and ask (local edit)
#   missing   — in manifest, not on disk → sync may recreate
#   unmanaged — under .claude/ but not in the manifest → sync must never touch
#
# Exit: 0 all managed files intact · 1 drifted or missing present · 2 no manifest
# Needs: bash 3.2+, python3 (stdlib json only), shasum.
set -u

PROJECT_DIR="."; JSON=false
for a in "$@"; do
  case "$a" in --json) JSON=true ;; *) PROJECT_DIR="$a" ;; esac
done
MANIFEST="$PROJECT_DIR/.claude/.forge-manifest.json"
if [ ! -f "$MANIFEST" ]; then
  if $JSON; then printf '{"error":"no manifest","manifest":"%s"}\n' "$MANIFEST"; else echo "forge-doctor: no manifest at $MANIFEST (run /forge bootstrap or /forge sync)" >&2; fi
  exit 2
fi

hash_of() { shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1; }

INTACT=""; DRIFTED=""; MISSING=""; UNMANAGED=""
MANAGED_LIST=$(mktemp -t forge-doctor-XXXXXX)
trap 'rm -f "$MANAGED_LIST"' EXIT

# path<TAB>hash per managed file
python3 - "$MANIFEST" > "$MANAGED_LIST" <<'PY'
import json, sys
m = json.load(open(sys.argv[1]))
for path, meta in sorted((m.get("files") or {}).items()):
    h = (meta.get("hash") if isinstance(meta, dict) else str(meta)) or ""
    print(f"{path}\t{h.replace('sha256:', '')}")
PY

while IFS=$'\t' read -r rel expected; do
  [ -n "$rel" ] || continue
  f="$PROJECT_DIR/$rel"
  if [ ! -f "$f" ]; then MISSING="$MISSING$rel"$'\n'
  elif [ "$(hash_of "$f")" = "$expected" ]; then INTACT="$INTACT$rel"$'\n'
  else DRIFTED="$DRIFTED$rel"$'\n'
  fi
done < "$MANAGED_LIST"

# unmanaged: shipped config under .claude/ that the manifest does not know
while IFS= read -r f; do
  rel="${f#"$PROJECT_DIR"/}"
  grep -qF "$rel"$'\t' "$MANAGED_LIST" && continue
  UNMANAGED="$UNMANAGED$rel"$'\n'
done < <(find "$PROJECT_DIR/.claude" -type f \
  -not -path '*/session/*' -not -path '*/agent-memory*' -not -path '*/worktrees/*' \
  -not -path '*/hooks/generated/*' -not -name 'settings.local.json' -not -name '.forge-manifest.json' \
  -not -name '.DS_Store' 2>/dev/null | sort)

count() { printf '%s' "$1" | grep -c . ; }
NI=$(count "$INTACT"); ND=$(count "$DRIFTED"); NM=$(count "$MISSING"); NU=$(count "$UNMANAGED")

if $JSON; then
  python3 - "$INTACT" "$DRIFTED" "$MISSING" "$UNMANAGED" "$MANIFEST" <<'PY'
import json, sys
def L(s): return [x for x in s.split("\n") if x]
intact, drifted, missing, unmanaged, manifest = sys.argv[1:6]
m = json.load(open(manifest))
print(json.dumps({"dotforge_version": m.get("dotforge_version"), "synced_at": m.get("synced_at"),
                  "intact": L(intact), "drifted": L(drifted), "missing": L(missing), "unmanaged": L(unmanaged)}, indent=2))
PY
else
  echo "═══ forge-doctor: $PROJECT_DIR (manifest v$(python3 -c "import json;print(json.load(open('$MANIFEST')).get('dotforge_version','?'))"), synced $(python3 -c "import json;print(json.load(open('$MANIFEST')).get('synced_at','?'))")) ═══"
  echo "intact: $NI · drifted: $ND · missing: $NM · unmanaged: $NU"
  [ "$ND" -gt 0 ] && { echo "── drifted (local edits — sync must diff + ask) ──"; printf '%s' "$DRIFTED" | sed 's/^/  ~ /'; }
  [ "$NM" -gt 0 ] && { echo "── missing (sync may recreate) ──"; printf '%s' "$MISSING" | sed 's/^/  - /'; }
  [ "$NU" -gt 0 ] && { echo "── unmanaged (never touched by sync) ──"; printf '%s' "$UNMANAGED" | sed 's/^/  ? /'; }
fi

[ "$ND" -eq 0 ] && [ "$NM" -eq 0 ]
