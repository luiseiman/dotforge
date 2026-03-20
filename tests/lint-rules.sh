#!/bin/bash
# Validate that all rule .md files have proper frontmatter
# Exit 0 = all pass, exit 1 = failures found

ERRORS=0
CHECKED=0

for rule_file in template/rules/*.md stacks/*/rules/*.md; do
  [ -f "$rule_file" ] || continue
  CHECKED=$((CHECKED + 1))
  BASENAME=$(basename "$rule_file")

  # _common.md uses globs: "**/*" which is valid
  # All rules must have frontmatter with globs:
  HAS_FRONTMATTER=$(head -1 "$rule_file" | grep -c "^---$")
  if [ "$HAS_FRONTMATTER" -eq 0 ]; then
    echo "✗ $rule_file — missing frontmatter (no opening ---)"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  HAS_GLOBS=$(sed -n '/^---$/,/^---$/p' "$rule_file" | grep -c "^globs:")
  if [ "$HAS_GLOBS" -eq 0 ]; then
    echo "✗ $rule_file — missing globs: in frontmatter"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  echo "✓ $rule_file"
done

echo ""
echo "Checked: $CHECKED rules, Errors: $ERRORS"
[ $ERRORS -eq 0 ] || exit 1
