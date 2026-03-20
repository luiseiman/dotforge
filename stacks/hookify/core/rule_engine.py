"""Rule evaluation engine for hookify."""

import re
import sys
from functools import lru_cache
from typing import List, Dict, Any

from core.config_loader import Rule, Condition


@lru_cache(maxsize=128)
def _compile_regex(pattern: str) -> re.Pattern:
    """Compile and cache regex patterns."""
    return re.compile(pattern, re.IGNORECASE)


class RuleEngine:
    """Evaluate hookify rules against hook input data."""

    def evaluate(self, rules: List[Rule], input_data: Dict[str, Any]) -> Dict[str, Any]:
        """Evaluate all rules against input. Return hook response.

        Returns empty dict if no rules match (allow operation).
        """
        hook_event = input_data.get("hook_event_name", "")
        blocking = []
        warnings = []

        for rule in rules:
            if self._matches(rule, input_data):
                if rule.action == "block":
                    blocking.append(rule)
                else:
                    warnings.append(rule)

        if blocking:
            msg = "\n\n".join(f"**[{r.name}]**\n{r.message}" for r in blocking)
            if hook_event == "Stop":
                return {"decision": "block", "reason": msg, "systemMessage": msg}
            elif hook_event in ("PreToolUse", "PostToolUse"):
                return {
                    "hookSpecificOutput": {
                        "hookEventName": hook_event,
                        "permissionDecision": "deny",
                    },
                    "systemMessage": msg,
                }
            return {"systemMessage": msg}

        if warnings:
            msg = "\n\n".join(f"**[{r.name}]**\n{r.message}" for r in warnings)
            return {"systemMessage": msg}

        return {}

    def _matches(self, rule: Rule, input_data: Dict[str, Any]) -> bool:
        """Check if a rule matches the input data."""
        tool_name = input_data.get("tool_name", "")

        # Check tool matcher
        if rule.tool_matcher:
            if rule.tool_matcher != "*" and tool_name not in rule.tool_matcher.split("|"):
                return False

        if not rule.conditions:
            return False

        # ALL conditions must match
        return all(
            self._check_condition(cond, tool_name, input_data)
            for cond in rule.conditions
        )

    def _check_condition(self, cond: Condition, tool_name: str, input_data: Dict[str, Any]) -> bool:
        """Check a single condition against input."""
        value = self._extract_field(cond.field, tool_name, input_data)
        if value is None:
            return False

        op = cond.operator
        pat = cond.pattern

        if op == "regex_match":
            try:
                return bool(_compile_regex(pat).search(value))
            except re.error as e:
                print(f"Invalid regex '{pat}': {e}", file=sys.stderr)
                return False
        elif op == "contains":
            return pat in value
        elif op == "equals":
            return pat == value
        elif op == "not_contains":
            return pat not in value
        elif op == "starts_with":
            return value.startswith(pat)
        elif op == "ends_with":
            return value.endswith(pat)
        return False

    def _extract_field(self, field: str, tool_name: str, input_data: Dict[str, Any]) -> str:
        """Extract field value from hook input data."""
        tool_input = input_data.get("tool_input", {})

        # Direct field in tool_input
        if field in tool_input:
            v = tool_input[field]
            return v if isinstance(v, str) else str(v)

        # Event-specific fields
        if field == "user_prompt":
            return input_data.get("user_prompt", "")
        if field == "reason":
            return input_data.get("reason", "")
        if field == "transcript":
            path = input_data.get("transcript_path")
            if path:
                try:
                    with open(path, "r") as f:
                        return f.read()
                except (IOError, OSError, UnicodeDecodeError):
                    return ""
            return ""

        # Tool-specific aliases
        if tool_name == "Bash" and field == "command":
            return tool_input.get("command", "")

        if tool_name in ("Write", "Edit", "MultiEdit"):
            if field in ("content", "new_text"):
                return tool_input.get("content") or tool_input.get("new_string", "")
            if field in ("old_text", "old_string"):
                return tool_input.get("old_string", "")
            if field == "file_path":
                return tool_input.get("file_path", "")

        return None
