#!/usr/bin/env python3
"""sync_all.py — additive sync of dotforge template + stack rules into every
registered project.

Scope (additive only, by design — full merge is the interactive skill):
- Adds missing template/hooks/*.sh files
- Adds missing stack rules for each detected stack (per .forge-manifest.json)
- Updates .forge-manifest.json: version + synced_at + per-file hashes
- NEVER touches:
    * existing hook files (preserves project-local customizations)
    * .claude/settings.json (allow/deny merge needs human review)
    * CLAUDE.md (custom sections risk)
    * .claude/rules/domain/ (project-owned per sync-template skill)

For full merge sync (settings.json union, CLAUDE.md sections), use the
interactive /forge sync skill per-project.

Usage:
  python3 scripts/sync_all.py            # apply
  python3 scripts/sync_all.py --dry-run  # preview
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from datetime import date
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml required", file=sys.stderr)
    sys.exit(2)

DOTFORGE = Path(__file__).resolve().parent.parent
REGISTRY = DOTFORGE / "registry/projects.local.yml"
TEMPLATE_HOOKS = DOTFORGE / "template/hooks"
STACKS_DIR = DOTFORGE / "stacks"
TODAY = date.today().isoformat()
VERSION = (DOTFORGE / "VERSION").read_text().strip()


def sha256(p: Path) -> str:
    return "sha256:" + hashlib.sha256(p.read_bytes()).hexdigest()


def detect_stacks_from_manifest(claude_dir: Path) -> list[str]:
    m = claude_dir / ".forge-manifest.json"
    if not m.exists():
        return []
    try:
        return json.loads(m.read_text()).get("stacks", []) or []
    except Exception:
        return []


def add_missing_hooks(claude_dir: Path, dry: bool) -> list[str]:
    hooks_dir = claude_dir / "hooks"
    if not hooks_dir.exists():
        return []
    added = []
    for tmpl in sorted(TEMPLATE_HOOKS.glob("*.sh")):
        target = hooks_dir / tmpl.name
        if not target.exists():
            if not dry:
                shutil.copy2(tmpl, target)
                target.chmod(0o755)
            added.append(tmpl.name)
    return added


def add_missing_stack_rules(claude_dir: Path, stacks: list[str], dry: bool) -> list[str]:
    rules_dir = claude_dir / "rules"
    if not rules_dir.exists() or not stacks:
        return []
    added = []
    for stack in stacks:
        src_rules = STACKS_DIR / stack / "rules"
        if not src_rules.exists():
            continue
        for rule in sorted(src_rules.glob("*.md")):
            target = rules_dir / rule.name
            if not target.exists():
                if not dry:
                    shutil.copy2(rule, target)
                added.append(f"{stack}/{rule.name}")
    return added


def update_manifest(claude_dir: Path, stacks: list[str], dry: bool) -> bool:
    """Refresh manifest: version + synced_at + per-file hashes for managed files."""
    manifest_path = claude_dir / ".forge-manifest.json"
    existing = {}
    if manifest_path.exists():
        try:
            existing = json.loads(manifest_path.read_text())
        except Exception:
            existing = {}

    files = existing.get("files", {})
    # Hash each managed file currently in .claude/
    for hook in (claude_dir / "hooks").glob("*.sh") if (claude_dir / "hooks").exists() else []:
        rel = f".claude/hooks/{hook.name}"
        files[rel] = {"hash": sha256(hook), "source": "template"}
    for rule in (claude_dir / "rules").glob("*.md") if (claude_dir / "rules").exists() else []:
        rel = f".claude/rules/{rule.name}"
        existing_entry = files.get(rel)
        if not isinstance(existing_entry, dict):
            files[rel] = {"hash": sha256(rule), "source": "template+stacks"}
        else:
            existing_entry["hash"] = sha256(rule)

    new_manifest = {
        "dotforge_version": VERSION,
        "synced_at": TODAY,
        "stacks": stacks,
        "files": files,
        "sync_method": "additive",
        "sync_note": "Settings.json + CLAUDE.md + domain/ NOT touched. Run interactive /forge sync per-project for full merge.",
    }

    if dry:
        return True
    manifest_path.write_text(json.dumps(new_manifest, indent=2) + "\n")
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    with open(REGISTRY) as f:
        data = yaml.safe_load(f)

    print(f"═══ ADDITIVE SYNC → v{VERSION} ═══")
    print(f"Dry-run: {args.dry_run}\n")

    summary = []
    for proj in data["projects"]:
        name = proj["name"]
        path = Path(proj["path"])
        if str(path) == ".":
            path = DOTFORGE
        if not path.exists():
            print(f"── {name:<20} SKIP (missing path)")
            summary.append((name, "missing", 0, 0))
            continue
        claude_dir = path / ".claude"
        if not claude_dir.exists():
            print(f"── {name:<20} SKIP (no .claude/)")
            summary.append((name, "no .claude", 0, 0))
            continue

        stacks = detect_stacks_from_manifest(claude_dir)
        added_hooks = add_missing_hooks(claude_dir, args.dry_run)
        added_rules = add_missing_stack_rules(claude_dir, stacks, args.dry_run)
        update_manifest(claude_dir, stacks, args.dry_run)

        bits = []
        if added_hooks:
            bits.append(f"+{len(added_hooks)} hooks: {', '.join(added_hooks)}")
        if added_rules:
            bits.append(f"+{len(added_rules)} stack rules: {', '.join(added_rules)}")
        if not bits:
            bits.append("manifest refreshed only")

        print(f"── {name:<20} {' | '.join(bits)}")
        summary.append((name, "synced", len(added_hooks), len(added_rules)))

    print("\n═══ SUMMARY ═══")
    total_hooks = sum(s[2] for s in summary)
    total_rules = sum(s[3] for s in summary)
    synced = sum(1 for s in summary if s[1] == "synced")
    print(f"Projects synced:         {synced}/{len(summary)}")
    print(f"Total hooks added:       {total_hooks}")
    print(f"Total stack rules added: {total_rules}")
    print(f"Manifest version:        v{VERSION}")
    if args.dry_run:
        print("\n(dry-run: no files written)")
    else:
        print("\nNote: settings.json / CLAUDE.md / domain/ NOT touched. Run")
        print("      interactive /forge sync per-project for full merge.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
