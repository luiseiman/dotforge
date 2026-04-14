#!/usr/bin/env bash
# tests/test-skills-index.sh — validates skills/index.yaml consistency
#
# Invariant: every directory under skills/ must appear in skills/index.yaml
# exactly once, and every entry in the index must have a matching
# skills/<id>/SKILL.md.
#
# Also validates:
# - schema_version is "1"
# - each entry has id, category, target
# - category is one of the declared set
# - target is one of the declared set
# - no duplicate ids
#
# Exit codes: 0 = ok, 1 = mismatch or schema violation

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INDEX="$REPO_ROOT/skills/index.yaml"
SKILLS_DIR="$REPO_ROOT/skills"

if [[ ! -f "$INDEX" ]]; then
  echo "FAIL: $INDEX not found" >&2
  exit 1
fi

# Parse the index with python3 (yaml is standard)
RESULT=$(python3 - "$INDEX" "$SKILLS_DIR" <<'PYEOF'
import os
import sys
import yaml

index_path, skills_dir = sys.argv[1], sys.argv[2]

try:
    with open(index_path) as f:
        data = yaml.safe_load(f) or {}
except Exception as e:
    print(f"FAIL: cannot parse {index_path}: {e}")
    sys.exit(1)

errors = []
warnings = []

if data.get("schema_version") != "1":
    errors.append(f"schema_version must be \"1\", got {data.get('schema_version')!r}")

entries = data.get("skills") or []
if not entries:
    errors.append("no skills entries found")

valid_categories = {"lifecycle", "analysis", "practices", "domain", "export",
                    "integrations", "scouting", "governance"}
valid_targets = {"project", "global", "both", "external"}

seen_ids = set()
index_ids = []

for i, entry in enumerate(entries):
    if not isinstance(entry, dict):
        errors.append(f"entry #{i}: not a mapping")
        continue
    sid = entry.get("id")
    if not sid:
        errors.append(f"entry #{i}: missing id")
        continue
    if sid in seen_ids:
        errors.append(f"entry {sid!r}: duplicate id")
    seen_ids.add(sid)
    index_ids.append(sid)

    cat = entry.get("category")
    if cat not in valid_categories:
        errors.append(f"entry {sid!r}: invalid category {cat!r} (must be one of {sorted(valid_categories)})")

    tgt = entry.get("target")
    if tgt not in valid_targets:
        errors.append(f"entry {sid!r}: invalid target {tgt!r} (must be one of {sorted(valid_targets)})")

    skill_md = os.path.join(skills_dir, sid, "SKILL.md")
    if not os.path.isfile(skill_md):
        errors.append(f"entry {sid!r}: no SKILL.md at {skill_md}")

# Check every dir under skills/ appears in the index
try:
    fs_ids = sorted(
        name for name in os.listdir(skills_dir)
        if os.path.isdir(os.path.join(skills_dir, name))
        and os.path.isfile(os.path.join(skills_dir, name, "SKILL.md"))
    )
except OSError as e:
    errors.append(f"cannot list {skills_dir}: {e}")
    fs_ids = []

missing_from_index = set(fs_ids) - set(index_ids)
missing_from_fs = set(index_ids) - set(fs_ids)

for sid in sorted(missing_from_index):
    errors.append(f"skill {sid!r}: exists in filesystem but not in index")
for sid in sorted(missing_from_fs):
    errors.append(f"skill {sid!r}: in index but missing from filesystem")

if errors:
    print("FAIL")
    for e in errors:
        print(f"  - {e}")
    sys.exit(1)

print(f"PASS: {len(index_ids)} skills validated")
sys.exit(0)
PYEOF
)

echo "$RESULT"
[[ "$RESULT" == PASS* ]]
