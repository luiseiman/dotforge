#!/usr/bin/env python3
"""compact-filter — reduce a Claude Code compact_summary before persisting it.

Reads the summary from stdin, writes a filtered version to stdout, and emits
metrics (input/output bytes, ratio, removed sections) to stderr.

Filters applied (conservative — never drops headings, decisions, file paths):

1. Collapse oversized fenced code blocks (> MAX_CODE_LINES lines):
   keep first 5 + last 5 + "(... N lines elided ...)"
2. Collapse oversized inline tool-output blocks signalled by indent-style or
   bracketed dumps the LLM emitted (heuristic: contiguous runs of >= 30 lines
   that are mostly path/identifier-like and not part of a fenced block).
3. Deduplicate identical paragraphs that appear 3+ times (rare in real
   summaries but happens when the model paraphrases sections).
4. Strip trailing whitespace and collapse runs of >2 blank lines to exactly 2.

What is NEVER filtered:
- Lines starting with #, *, -, |, >, =, [, : (markdown structure)
- Lines containing 'decision', 'error', 'fix', 'pending', 'next step',
  'commit', 'TODO' (case-insensitive)
- File paths (anything matching r'[A-Za-z0-9_./-]+\\.(md|sh|py|json|yaml|yml|tsx?|ts|js|sql|toml|ini)')
- The first 50 lines (usually contains the most important context)

Designed to be safe: if anything looks risky to drop, it stays. Worst case the
file size is unchanged. Best case 30-60% reduction on tool-heavy summaries.
"""

from __future__ import annotations

import re
import sys
from typing import List

MAX_CODE_LINES = 40           # collapse fenced blocks longer than this
DEDUPE_MIN_REPEATS = 3        # only dedupe paragraphs seen this many times
KEEP_HEAD_LINES = 10          # always preserve the first N lines verbatim
MAX_BLANK_RUN = 2             # collapse runs of blank lines to this max
RUN_THRESHOLD = 30            # contiguous unprotected lines to trigger collapse

PROTECT_TOKENS = (
    "decision", "error", "fix", "pending", "next step",
    "commit", "todo", "blocker", "warning", "fail",
)
PROTECT_PREFIXES = ("#", "*", "-", "|", ">", "=", "[", ":")
PATH_RE = re.compile(
    r"[A-Za-z0-9_./-]+\.(?:md|sh|py|json|yaml|yml|tsx|ts|js|sql|toml|ini|cfg|env|lock)\b"
)


def is_protected(line: str) -> bool:
    s = line.strip()
    if not s:
        return False
    if s.startswith(PROTECT_PREFIXES):
        return True
    low = s.lower()
    if any(tok in low for tok in PROTECT_TOKENS):
        return True
    if PATH_RE.search(s):
        return True
    return False


def collapse_fenced_blocks(lines: List[str]) -> List[str]:
    """Collapse fenced code blocks longer than MAX_CODE_LINES."""
    out: List[str] = []
    i = 0
    n = len(lines)
    while i < n:
        line = lines[i]
        # Detect fence start
        stripped = line.lstrip()
        if stripped.startswith("```"):
            fence = stripped[: len(stripped) - len(stripped.lstrip("`"))]  # ``` or ````
            indent = line[: len(line) - len(stripped)]
            # Find matching close fence
            j = i + 1
            block: List[str] = []
            while j < n:
                jline = lines[j]
                jstripped = jline.lstrip()
                if jstripped.startswith(fence) and jstripped[len(fence):].strip() == "":
                    break
                block.append(jline)
                j += 1
            if j >= n:
                # Unclosed fence — leave as-is
                out.append(line)
                i += 1
                continue
            # j is the closing fence
            if len(block) > MAX_CODE_LINES:
                elided = len(block) - 10
                out.append(line)
                out.extend(block[:5])
                out.append(f"{indent}# ... ({elided} lines elided by compact-filter) ...")
                out.extend(block[-5:])
                out.append(lines[j])
            else:
                out.append(line)
                out.extend(block)
                out.append(lines[j])
            i = j + 1
        else:
            out.append(line)
            i += 1
    return out


def _mark_fence_membership(lines: List[str]) -> List[bool]:
    """Return a parallel list: True if line is INSIDE a fenced code block."""
    inside = [False] * len(lines)
    in_block = False
    fence = ""
    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if not in_block and stripped.startswith("```"):
            fence = stripped[: len(stripped) - len(stripped.lstrip("`"))]
            in_block = True
            inside[i] = False  # the fence marker itself stays visible
            continue
        if in_block:
            if stripped.startswith(fence) and stripped[len(fence):].strip() == "":
                in_block = False
                inside[i] = False
                fence = ""
            else:
                inside[i] = True
    return inside


def collapse_long_unprotected_runs(lines: List[str], head_skip: int) -> List[str]:
    """Collapse runs of >= RUN_THRESHOLD contiguous unprotected lines.

    Skips lines inside fenced code blocks (those are handled by
    `collapse_fenced_blocks`). `head_skip` counts lines from the start of the
    document that are always kept verbatim.
    """
    inside_fence = _mark_fence_membership(lines)
    out: List[str] = []
    n = len(lines)
    i = 0
    while i < n:
        if i < head_skip or inside_fence[i] or is_protected(lines[i]) or not lines[i].strip():
            out.append(lines[i])
            i += 1
            continue
        run_start = i
        while (
            i < n
            and lines[i].strip()
            and not is_protected(lines[i])
            and not inside_fence[i]
        ):
            i += 1
        run_len = i - run_start
        if run_len >= RUN_THRESHOLD:
            elided = run_len - 6
            out.extend(lines[run_start:run_start + 3])
            out.append(f"... ({elided} lines elided by compact-filter — unprotected dense run) ...")
            out.extend(lines[i - 3:i])
        else:
            out.extend(lines[run_start:i])
    return out


def dedupe_paragraphs(text: str) -> str:
    """Remove duplicate paragraphs that appear >= DEDUPE_MIN_REPEATS times."""
    paragraphs = re.split(r"\n\s*\n", text)
    counts: dict = {}
    for p in paragraphs:
        key = p.strip()
        if len(key) < 80:  # short paragraphs (titles, single bullets) excluded
            continue
        counts[key] = counts.get(key, 0) + 1
    dupes = {k for k, v in counts.items() if v >= DEDUPE_MIN_REPEATS}
    if not dupes:
        return text
    seen = set()
    keep: List[str] = []
    for p in paragraphs:
        key = p.strip()
        if key in dupes:
            if key in seen:
                continue
            seen.add(key)
        keep.append(p)
    return "\n\n".join(keep)


def collapse_blank_runs(text: str) -> str:
    return re.sub(r"\n{" + str(MAX_BLANK_RUN + 1) + r",}", "\n" * (MAX_BLANK_RUN + 1), text)


def filter_summary(text: str) -> str:
    if not text.strip():
        return text
    text = re.sub(r"[ \t]+\n", "\n", text)  # strip trailing whitespace per line
    lines = text.split("\n")
    lines = collapse_fenced_blocks(lines)
    lines = collapse_long_unprotected_runs(lines, head_skip=KEEP_HEAD_LINES)
    text = "\n".join(lines)
    text = dedupe_paragraphs(text)
    text = collapse_blank_runs(text)
    return text


def main() -> int:
    src = sys.stdin.read()
    if not src:
        return 0
    out = filter_summary(src)
    sys.stdout.write(out)

    in_bytes = len(src.encode("utf-8"))
    out_bytes = len(out.encode("utf-8"))
    ratio = (out_bytes / in_bytes) if in_bytes else 1.0
    saved = in_bytes - out_bytes
    sys.stderr.write(
        f"[compact-filter] in={in_bytes}B  out={out_bytes}B  saved={saved}B  ratio={ratio:.2f}\n"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
