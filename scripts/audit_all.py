#!/usr/bin/env python3
"""Audit all projects listed in registry/projects.local.yml against audit/checklist.md.

Deterministic, script-based alternative to running the /audit-project skill 12 times.
Walks each project path, scores the 15 checklist items, and updates the registry.

Usage: python3 scripts/audit_all.py [--dry-run]
"""
import argparse
import json
import re
import stat
import sys
from datetime import date
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml required — pip install pyyaml", file=sys.stderr)
    sys.exit(2)

DOTFORGE = Path(__file__).resolve().parent.parent
REGISTRY = DOTFORGE / "registry/projects.local.yml"
VERSION_FILE = DOTFORGE / "VERSION"
TODAY = date.today().isoformat()

# Prompt-injection patterns — tuned to avoid false positives on CLI placeholders.
# Standalone <word> in docs (e.g. `/compact <instructions>`) is NOT flagged.
# We require either a matching close-tag OR a hijack phrase.
INJECTION_PHRASES = [
    r"ignore previous",
    r"IGNORE ALL",
    r"disregard previous",
    r"override instructions",
    r"disregard all",
    r"new instructions:",
]
INJECTION_TAG_PAIRS = [
    (r"<system>", r"</system>"),
    (r"<instructions>", r"</instructions>"),
]


def test_x(path: Path) -> bool:
    try:
        return path.is_file() and bool(path.stat().st_mode & stat.S_IXUSR)
    except Exception:
        return False


def read_text(path: Path, limit: int = 200_000) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")[:limit]
    except Exception:
        return ""


def read_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None


def scan_injection(texts: list[str]) -> tuple[bool, str]:
    """Return (found, reason). Only flag genuine hijack attempts."""
    for t in texts:
        tl = t.lower()
        for phrase in INJECTION_PHRASES:
            if re.search(phrase.lower(), tl):
                return True, f"phrase '{phrase}'"
        for open_t, close_t in INJECTION_TAG_PAIRS:
            if re.search(open_t, tl) and re.search(close_t, tl):
                return True, f"paired tag '{open_t}...{close_t}'"
    return False, ""


def audit(proj_path: Path, name: str) -> dict:
    r = {"name": name, "path": str(proj_path), "items": {}, "notes": []}
    claude_md = proj_path / "CLAUDE.md"
    claude_dir = proj_path / ".claude"
    settings_json = claude_dir / "settings.json"
    hooks_dir = claude_dir / "hooks"
    rules_dir = claude_dir / "rules"
    commands_dir = claude_dir / "commands"
    agents_dir = claude_dir / "agents"
    errors_md = proj_path / "CLAUDE_ERRORS.md"
    manifest = claude_dir / ".forge-manifest.json"
    gitignore = proj_path / ".gitignore"

    # Item 1: CLAUDE.md
    if not claude_md.exists():
        r["items"]["1_claude_md"] = 0
    else:
        txt = read_text(claude_md)
        non_blank = [l for l in txt.splitlines() if l.strip() and not l.strip().startswith("#")]
        has_build = bool(re.search(
            r"\b(npm|pnpm|yarn|pip|pytest|go test|cargo|make|uvicorn|vite|swift build|xcodebuild|docker|bun)\b",
            txt, re.I))
        has_arch = bool(re.search(r"\b(structure|architecture|directorio|stack|tecnolog|layout)", txt, re.I))
        has_stack = bool(re.search(
            r"\b(python|typescript|swift|javascript|react|fastapi|swiftui|supabase|go|rust|node|vite)\b",
            txt, re.I))
        if len(non_blank) < 15 or not (has_build and has_arch and has_stack):
            r["items"]["1_claude_md"] = 1
        else:
            r["items"]["1_claude_md"] = 2

    # Item 2: settings.json
    s = read_json(settings_json)
    if not s:
        r["items"]["2_settings"] = 0
    else:
        perm = s.get("permissions", {})
        deny = perm.get("deny", [])
        allow = perm.get("allow", [])
        has_secret_deny = any(re.search(r"\.env|\*\.key|\*\.pem|credentials", str(d), re.I) for d in deny)
        has_wildcard = any(a in ("Bash(*)", "Bash:*", "*") for a in allow)
        if not deny or has_wildcard or not has_secret_deny:
            r["items"]["2_settings"] = 1 if deny else 0
        else:
            r["items"]["2_settings"] = 2

    # Item 3: rules
    rule_files = list(rules_dir.glob("**/*.md")) if rules_dir.exists() else []
    if not rule_files:
        r["items"]["3_rules"] = 0
    else:
        with_globs = 0
        for f in rule_files:
            t = read_text(f, 2000)
            if re.search(r"^globs:\s*\S", t, re.M) or re.search(r"^paths:\s*\S", t, re.M):
                with_globs += 1
        r["items"]["3_rules"] = 2 if with_globs >= max(1, len(rule_files) // 2) else 1

    # Item 4: block-destructive hook
    bd = hooks_dir / "block-destructive.sh"
    if not bd.exists():
        r["items"]["4_block_destructive"] = 0
    else:
        executable = test_x(bd)
        content = read_text(bd)
        has_rm = "rm -rf" in content
        has_drop = "DROP TABLE" in content or "DROP DATABASE" in content
        has_push = "--force" in content
        wired = False
        if s:
            hooks = s.get("hooks", {})
            wired = "block-destructive" in json.dumps(hooks)
        if executable and wired and has_rm and has_drop and has_push:
            r["items"]["4_block_destructive"] = 2
        else:
            r["items"]["4_block_destructive"] = 1
            if not executable:
                r["notes"].append("block-destructive.sh not executable")
            if not wired:
                r["notes"].append("block-destructive.sh not wired in settings.json hooks")

    # Item 5: build/test in CLAUDE.md
    if claude_md.exists():
        txt = read_text(claude_md)
        has_cmd = bool(re.search(
            r"\b(npm|pnpm|yarn|pytest|pip install|go test|cargo|make|uvicorn|docker|swift build|xcodebuild|bun)\b.{0,40}(test|build|dev|lint|run)",
            txt, re.I))
        if not has_cmd:
            has_cmd = bool(re.search(
                r"`(npm|pnpm|yarn|pip|pytest|go|cargo|make|docker|swift|xcodebuild|bun)[^`]{1,40}`",
                txt, re.I))
        r["items"]["5_build_test"] = 2 if has_cmd else 1
    else:
        r["items"]["5_build_test"] = 0

    # Item 6: CLAUDE_ERRORS.md (accept English or Spanish headers)
    if errors_md.exists():
        t = read_text(errors_md)
        has_type = bool(re.search(r"\b(Type|Tipo)\b", t)) and bool(re.search(
            r"\b(syntax|logic|integration|config|security)\b", t, re.I))
        r["items"]["6_errors_md"] = 1 if has_type else 0
    else:
        r["items"]["6_errors_md"] = 0

    # Item 7: lint hook
    lint_hooks = list(hooks_dir.glob("*lint*.sh")) if hooks_dir.exists() else []
    r["items"]["7_lint_hook"] = 1 if any(test_x(h) for h in lint_hooks) else 0

    # Item 8: custom commands
    cmd_files = list(commands_dir.glob("*.md")) if commands_dir.exists() else []
    r["items"]["8_commands"] = 1 if cmd_files else 0

    # Item 9: project memory
    mem_candidates = [
        claude_dir / "MEMORY.md",
        claude_dir / "agent-memory",
        proj_path / "MEMORY.md",
    ]
    has_mem = False
    for m in mem_candidates:
        if m.is_dir() and any(m.iterdir()):
            has_mem = True
            break
        if m.is_file() and m.stat().st_size > 100:
            has_mem = True
            break
    r["items"]["9_memory"] = 1 if has_mem else 0

    # Item 10: agents
    agent_files = list(agents_dir.glob("*.md")) if agents_dir.exists() else []
    agents_rule = (rules_dir / "agents.md") if rules_dir.exists() else None
    has_agents = bool(agent_files) and agents_rule and agents_rule.exists()
    r["items"]["10_agents"] = 1 if has_agents else 0

    # Item 11: .gitignore
    if gitignore.exists():
        g = read_text(gitignore)
        has_env = bool(re.search(r"^\.env", g, re.M))
        has_keys = bool(re.search(r"\*\.key|\*\.pem", g))
        has_creds = bool(re.search(r"credentials", g, re.I))
        r["items"]["11_gitignore"] = 1 if (has_env and (has_keys or has_creds)) else 0
    else:
        r["items"]["11_gitignore"] = 0

    # Item 12: prompt-injection scan
    scan_paths = []
    if rules_dir.exists():
        scan_paths.extend(rules_dir.glob("**/*.md"))
    if claude_md.exists():
        scan_paths.append(claude_md)
    texts = [read_text(sp, 30_000) for sp in scan_paths]
    found, reason = scan_injection(texts)
    if found:
        r["notes"].append(f"injection: {reason}")
    r["items"]["12_injection"] = 0 if found else 1

    # Item 13: auto-mode safety
    if s:
        mode = s.get("permissions", {}).get("defaultMode", "")
        if mode == "auto":
            deny = s.get("permissions", {}).get("deny", [])
            denies_secrets = sum(
                1 for d in deny if re.search(r"\.env|\*\.key|\*\.pem|credentials", str(d), re.I)
            ) >= 3
            r["items"]["13_auto_safe"] = 1 if denies_secrets else 0
        else:
            r["items"]["13_auto_safe"] = 1  # auto mode not enabled — auto-pass
    else:
        r["items"]["13_auto_safe"] = 0

    # Item 14: v3 behaviors
    gen_dir = hooks_dir / "generated"
    gen_hooks = list(gen_dir.glob("*__pretooluse__*.sh")) if gen_dir.exists() else []
    beh_idx = proj_path / "behaviors/index.yaml"
    has_beh = bool(gen_hooks) or beh_idx.exists()
    r["items"]["14_behaviors"] = 1 if has_beh else 0

    # Item 15: sandbox / env-scrub auto-pass
    sandbox_on = False
    env_scrub = False
    if s:
        sandbox_on = s.get("sandbox", {}).get("enabled", False) is True
        env = s.get("env", {})
        if env.get("CLAUDE_CODE_SUBPROCESS_ENV_SCRUB") in ("1", "true", True):
            env_scrub = True
    if sandbox_on:
        fs = s.get("sandbox", {}).get("filesystem", {})
        net = s.get("sandbox", {}).get("network", {})
        has_restriction = bool(fs.get("denyRead") or fs.get("allowWrite") or net.get("allowedDomains"))
        r["items"]["15_sandbox"] = 1 if has_restriction else 0
    elif env_scrub:
        r["items"]["15_sandbox"] = 1  # env-scrub is acceptable defense-in-depth
    else:
        has_secrets = False
        for pat in (".env", ".env.local", "credentials.json", "key.pem"):
            if (proj_path / pat).exists():
                has_secrets = True
                break
        shell_refs = False
        for sh in list(proj_path.glob("**/*.sh"))[:20]:
            t = read_text(sh, 10_000)
            if re.search(r"\b(gcloud|aws|kubectl|terraform)\b", t):
                shell_refs = True
                break
        r["items"]["15_sandbox"] = 0 if (has_secrets or shell_refs) else 1

    # Score calculation
    mand = sum(r["items"][f"{i}_{k}"] for i, k in [
        (1, "claude_md"), (2, "settings"), (3, "rules"),
        (4, "block_destructive"), (5, "build_test")
    ])
    rec = sum(r["items"][f"{i}_{k}"] for i, k in [
        (6, "errors_md"), (7, "lint_hook"), (8, "commands"), (9, "memory"),
        (10, "agents"), (11, "gitignore"), (12, "injection"),
        (13, "auto_safe"), (14, "behaviors"), (15, "sandbox")
    ])
    total = mand * 0.7 + rec * 0.3
    if r["items"]["2_settings"] == 0 or r["items"]["4_block_destructive"] == 0:
        total = min(total, 6.0)
    r["mand"] = mand
    r["rec"] = rec
    r["score"] = round(total, 2)
    r["manifest_present"] = manifest.exists()
    return r


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="Don't write registry")
    args = ap.parse_args()

    version = VERSION_FILE.read_text().strip()
    with open(REGISTRY) as f:
        data = yaml.safe_load(f)

    results = []
    for proj in data["projects"]:
        p = Path(proj["path"])
        if str(p) == ".":
            p = DOTFORGE
        if not p.exists():
            print(f"SKIP: {proj['name']} — path not found: {p}")
            continue
        r = audit(p, proj["name"])
        r["prev_score"] = proj.get("score")
        r["prev_version"] = proj.get("dotforge_version")
        results.append(r)

    print(f"\n{'Project':<20} {'Mand':>6} {'Rec':>6} {'Prev':>5} {'New':>5} {'Δ':>6} {'Baseline':>10} {'Notes'}")
    print("─" * 100)
    for r in results:
        prev = r.get("prev_score") or 0
        delta = r["score"] - prev
        delta_s = f"{delta:+.2f}" if prev else "  new"
        baseline = "manifest" if r["manifest_present"] else "none"
        notes = ", ".join(r["notes"][:2]) if r["notes"] else ""
        print(
            f"{r['name']:<20} {r['mand']:>3}/10 {r['rec']:>3}/10 "
            f"{prev:>5.1f} {r['score']:>5.2f} {delta_s:>6} {baseline:>10}  {notes[:40]}"
        )

    avg = sum(r["score"] for r in results) / len(results)
    perfect = sum(1 for r in results if r["score"] >= 9.0)
    need_attn = sum(1 for r in results if r["score"] < 9.0)
    print(f"\n{len(results)} projects | avg {avg:.2f} | {perfect} perfect (≥9) | {need_attn} need attention")

    print()
    for r in results:
        if r["prev_score"] and r["score"] - r["prev_score"] < -1.5:
            print(f"⚠ ALERT: {r['name']} dropped {r['prev_score'] - r['score']:.1f} points")
        pv = r.get("prev_version") or ""
        if r["score"] < 7.0 and pv and pv != version:
            print(f"→ {r['name']}: run /forge sync (current v{pv} → available v{version})")

    if args.dry_run:
        print("\n(dry-run: registry not written)")
        return 0

    for proj in data["projects"]:
        for r in results:
            if proj["name"] == r["name"]:
                hist = proj.setdefault("history", [])
                hist.append({"date": TODAY, "score": r["score"], "version": version})
                proj["history"] = hist[-8:]
                proj["last_audit"] = TODAY
                proj["score"] = r["score"]
                proj["dotforge_version"] = version
                break

    with open(REGISTRY, "w") as f:
        yaml.safe_dump(data, f, sort_keys=False, default_flow_style=False)
    print(f"\n✓ registry updated: {REGISTRY.relative_to(DOTFORGE)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
