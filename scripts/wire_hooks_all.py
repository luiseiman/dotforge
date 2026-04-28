#!/usr/bin/env python3
"""wire_hooks_all.py — programmatic deep sync: wire missing hooks into each
project's settings.json + union-merge deny list.

Companion to sync_all.py (which only adds files on disk). This script wires
those files into settings.json so they actually fire.

Strategy:
- For each event/matcher in template/settings.json.tmpl's hooks block, ensure
  the corresponding command is registered in the project's settings.json.
- Hooks already wired are left alone (idempotent).
- Custom hooks the project has are preserved.
- Deny list: union of template deny + project deny (never removes).
- Allow list: NOT touched (project-owned).
- CLAUDE.md: NOT touched.

Safety:
- Validates JSON before writing.
- Backs up settings.json to settings.json.bak.<timestamp> on first change.
- --dry-run shows planned wiring without writing.

Usage:
  python3 scripts/wire_hooks_all.py --dry-run
  python3 scripts/wire_hooks_all.py
"""
from __future__ import annotations

import argparse
import copy
import json
import sys
from datetime import datetime
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml required", file=sys.stderr)
    sys.exit(2)

DOTFORGE = Path(__file__).resolve().parent.parent
REGISTRY = DOTFORGE / "registry/projects.local.yml"
TEMPLATE_SETTINGS = DOTFORGE / "template/settings.json.tmpl"


def load_template_hooks() -> dict:
    s = json.loads(TEMPLATE_SETTINGS.read_text())
    return s.get("hooks", {})


def load_template_deny() -> list[str]:
    s = json.loads(TEMPLATE_SETTINGS.read_text())
    return list(s.get("permissions", {}).get("deny", []))


def hook_command_exists(event_entries: list, command: str) -> bool:
    for entry in event_entries or []:
        for h in entry.get("hooks", []):
            cmd = h.get("command", "")
            # Match on basename so we tolerate path variations (.claude/hooks/X.sh
            # vs $DOTFORGE_DIR/hooks/X.sh vs absolute path)
            if cmd.endswith(command.split("/")[-1]):
                return True
    return False


def wire_event(project_event: list, template_event: list, target_command: str, matcher: str) -> bool:
    """Add target_command to the matching matcher group if absent. Returns True if added."""
    # Look for an existing entry with this matcher
    target_basename = target_command.split("/")[-1]
    for entry in project_event:
        if entry.get("matcher", "") == matcher:
            for h in entry.get("hooks", []):
                if h.get("command", "").endswith(target_basename):
                    return False  # already wired
            # Add to this matcher group
            tmpl_hook = next(
                (h for tentry in template_event if tentry.get("matcher", "") == matcher
                 for h in tentry.get("hooks", []) if h.get("command", "").endswith(target_basename)),
                None,
            )
            if tmpl_hook:
                entry.setdefault("hooks", []).append(copy.deepcopy(tmpl_hook))
                return True
            return False
    # No existing entry with this matcher — clone template's full entry for this matcher
    tmpl_entry = next(
        (e for e in template_event if e.get("matcher", "") == matcher),
        None,
    )
    if tmpl_entry:
        new_entry = copy.deepcopy(tmpl_entry)
        # Strip out hooks not matching our target command, keep only the one we want
        new_entry["hooks"] = [
            h for h in new_entry.get("hooks", [])
            if h.get("command", "").endswith(target_basename)
        ]
        if new_entry["hooks"]:
            project_event.append(new_entry)
            return True
    return False


def sync_project(settings_path: Path, template_hooks: dict, template_deny: list[str], dry: bool) -> dict:
    """Returns dict of changes: hooks_added, deny_added, total_changes."""
    if not settings_path.exists():
        return {"error": "settings.json missing"}

    try:
        s = json.loads(settings_path.read_text())
    except Exception as e:
        return {"error": f"invalid JSON: {e}"}

    original = copy.deepcopy(s)
    hooks_added = []
    deny_added = []

    # Wire each hook from template
    proj_hooks = s.setdefault("hooks", {})
    for event_name, template_event in template_hooks.items():
        proj_event = proj_hooks.setdefault(event_name, [])
        # Each template entry may have one or more hooks; wire each individually
        for tentry in template_event:
            matcher = tentry.get("matcher", "")
            for h in tentry.get("hooks", []):
                cmd = h.get("command", "")
                if wire_event(proj_event, template_event, cmd, matcher):
                    hooks_added.append(f"{event_name}[{matcher or '*'}]: {cmd.split('/')[-1]}")

    # Union-merge deny list
    perms = s.setdefault("permissions", {})
    proj_deny = perms.setdefault("deny", [])
    for entry in template_deny:
        if entry not in proj_deny:
            proj_deny.append(entry)
            deny_added.append(entry)

    if not hooks_added and not deny_added:
        return {"no_changes": True}

    # Validate JSON before writing
    try:
        json.dumps(s)  # should always succeed but cheap to verify
    except Exception as e:
        return {"error": f"resulting JSON invalid: {e}"}

    if not dry:
        # Backup
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = settings_path.with_suffix(f".json.bak.{ts}")
        backup.write_text(json.dumps(original, indent=2) + "\n")
        # Write
        settings_path.write_text(json.dumps(s, indent=2) + "\n")

    return {
        "hooks_added": hooks_added,
        "deny_added": deny_added,
        "total_changes": len(hooks_added) + len(deny_added),
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    template_hooks = load_template_hooks()
    template_deny = load_template_deny()

    print(f"═══ WIRE HOOKS + MERGE DENY (programmatic deep sync) ═══")
    print(f"Template events: {list(template_hooks.keys())}")
    print(f"Template deny:   {len(template_deny)} entries")
    print(f"Dry-run: {args.dry_run}\n")

    with open(REGISTRY) as f:
        data = yaml.safe_load(f)

    summary = []
    for proj in data["projects"]:
        name = proj["name"]
        path = Path(proj["path"])
        if str(path) == ".":
            path = DOTFORGE
        settings = path / ".claude" / "settings.json"
        result = sync_project(settings, template_hooks, template_deny, args.dry_run)

        if "error" in result:
            print(f"── {name:<20} ERROR: {result['error']}")
            summary.append((name, "error", 0, 0))
            continue
        if result.get("no_changes"):
            print(f"── {name:<20} ✓ already wired")
            summary.append((name, "ok", 0, 0))
            continue

        bits = []
        if result["hooks_added"]:
            bits.append(f"+{len(result['hooks_added'])} hooks")
        if result["deny_added"]:
            bits.append(f"+{len(result['deny_added'])} deny")
        print(f"── {name:<20} {' | '.join(bits)}")
        for h in result["hooks_added"]:
            print(f"      hook:  {h}")
        for d in result["deny_added"]:
            print(f"      deny:  {d}")
        summary.append((name, "synced", len(result["hooks_added"]), len(result["deny_added"])))

    print("\n═══ SUMMARY ═══")
    total_hooks = sum(s[2] for s in summary)
    total_deny = sum(s[3] for s in summary)
    synced = sum(1 for s in summary if s[1] == "synced")
    already = sum(1 for s in summary if s[1] == "ok")
    errors = sum(1 for s in summary if s[1] == "error")
    print(f"Synced:         {synced}/{len(summary)}")
    print(f"Already wired:  {already}")
    print(f"Errors:         {errors}")
    print(f"Hooks wired:    {total_hooks}")
    print(f"Deny entries:   {total_deny}")
    if args.dry_run:
        print("\n(dry-run: no files written)")
    else:
        print("\nNote: settings.json.bak.<timestamp> created on each modified project.")
        print("      CLAUDE.md not touched. Allow list not touched. Custom hooks preserved.")
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
