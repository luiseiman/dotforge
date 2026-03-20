"""Load hookify rule files from .claude/ directory."""

import glob
import os
import re
import sys
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class Condition:
    """A single match condition within a rule."""
    field: str
    operator: str
    pattern: str


@dataclass
class Rule:
    """A hookify rule parsed from a .local.md file."""
    name: str
    enabled: bool
    event: str  # bash, file, stop, prompt, all
    action: str  # warn, block
    conditions: List[Condition] = field(default_factory=list)
    message: str = ""
    tool_matcher: Optional[str] = None  # Bash, Edit|Write, *, etc.
    source_file: str = ""


# Map event types to tool matchers
EVENT_TOOL_MAP = {
    "bash": "Bash",
    "file": "Edit|Write|MultiEdit",
    "stop": None,
    "prompt": None,
    "all": "*",
}


def parse_frontmatter(content: str) -> tuple:
    """Parse YAML frontmatter and body from markdown content.

    Returns (frontmatter_dict, body_string).
    """
    if not content.startswith("---"):
        return {}, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    fm_text = parts[1].strip()
    body = parts[2].strip()

    # Simple YAML parsing (no dependency on pyyaml)
    fm = {}
    current_key = None
    current_list = None

    for line in fm_text.split("\n"):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        # List item under a key
        if stripped.startswith("- ") and current_key and current_list is not None:
            item_text = stripped[2:].strip()
            # Check if it's a dict item (field: value)
            if ": " in item_text:
                item_dict = {}
                # Parse this line and following indented lines
                item_dict_key, item_dict_val = item_text.split(": ", 1)
                item_dict[item_dict_key.strip()] = item_dict_val.strip()
                current_list.append(item_dict)
            else:
                current_list.append(item_text)
            continue

        # Indented key: value under a list item
        if line.startswith("    ") and current_list and isinstance(current_list[-1], dict):
            if ": " in stripped:
                k, v = stripped.split(": ", 1)
                current_list[-1][k.strip()] = v.strip()
            continue

        # Top-level key with no value (e.g., "conditions:")
        if stripped.endswith(":") and ": " not in stripped and not stripped.startswith("- "):
            current_key = stripped[:-1].strip()
            current_list = []
            fm[current_key] = current_list
            continue

        # Top-level key: value
        if ": " in stripped:
            key, value = stripped.split(": ", 1)
            key = key.strip()
            value = value.strip()

            if value == "":
                # Could be start of a list
                current_key = key
                current_list = []
                fm[key] = current_list
            else:
                # Simple value
                if value.lower() == "true":
                    value = True
                elif value.lower() == "false":
                    value = False
                fm[key] = value
                current_key = key
                current_list = None
        elif stripped.startswith("- ") and current_key:
            # Continuation of list
            if not isinstance(fm.get(current_key), list):
                fm[current_key] = []
                current_list = fm[current_key]
            current_list = fm[current_key]
            item = stripped[2:].strip()
            current_list.append(item)

    return fm, body


def load_rules(project_dir: str = None) -> List[Rule]:
    """Load all hookify rules from .claude/ directory.

    Args:
        project_dir: Project root. Defaults to CWD.

    Returns:
        List of enabled Rule objects.
    """
    if project_dir is None:
        project_dir = os.getcwd()

    claude_dir = os.path.join(project_dir, ".claude")
    pattern = os.path.join(claude_dir, "hookify.*.md")
    rule_files = glob.glob(pattern)

    rules = []
    for filepath in sorted(rule_files):
        try:
            with open(filepath, "r") as f:
                content = f.read()
        except (IOError, OSError) as e:
            print(f"Warning: Could not read {filepath}: {e}", file=sys.stderr)
            continue

        fm, body = parse_frontmatter(content)

        if not fm.get("name"):
            print(f"Warning: Rule file {filepath} missing 'name' in frontmatter", file=sys.stderr)
            continue

        if not fm.get("enabled", True):
            continue

        event = fm.get("event", "all")
        action = fm.get("action", "warn")

        # Build conditions
        conditions = []

        # Shorthand: single 'pattern' field
        if "pattern" in fm and isinstance(fm["pattern"], str):
            # Determine default field based on event type
            default_field = {
                "bash": "command",
                "file": "file_path",
                "prompt": "user_prompt",
                "stop": "transcript",
                "all": "command",
            }.get(event, "command")

            conditions.append(Condition(
                field=default_field,
                operator="regex_match",
                pattern=fm["pattern"],
            ))

        # Explicit conditions list
        if "conditions" in fm and isinstance(fm["conditions"], list):
            for cond in fm["conditions"]:
                if isinstance(cond, dict):
                    conditions.append(Condition(
                        field=cond.get("field", "command"),
                        operator=cond.get("operator", "regex_match"),
                        pattern=cond.get("pattern", ""),
                    ))

        rule = Rule(
            name=fm["name"],
            enabled=True,
            event=event,
            action=action,
            conditions=conditions,
            message=body,
            tool_matcher=EVENT_TOOL_MAP.get(event, "*"),
            source_file=filepath,
        )
        rules.append(rule)

    return rules
