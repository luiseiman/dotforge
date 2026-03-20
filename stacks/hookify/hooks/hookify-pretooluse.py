#!/usr/bin/env python3
"""Hookify PreToolUse hook — evaluate rules before tool execution."""

import json
import os
import sys

# Add parent dir to path for core imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.config_loader import load_rules
from core.rule_engine import RuleEngine


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, ValueError):
        sys.exit(0)

    input_data["hook_event_name"] = "PreToolUse"

    # Load rules that apply to bash/file/all events
    all_rules = load_rules()
    applicable = [
        r for r in all_rules
        if r.event in ("bash", "file", "all")
    ]

    if not applicable:
        print(json.dumps({}))
        sys.exit(0)

    engine = RuleEngine()
    result = engine.evaluate(applicable, input_data)
    print(json.dumps(result))
    sys.exit(0)


if __name__ == "__main__":
    main()
