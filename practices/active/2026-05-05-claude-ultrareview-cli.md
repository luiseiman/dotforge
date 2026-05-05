---
id: claude-ultrareview-cli
source: watch:code.claude.com/docs/en/cli-reference
status: active
captured: 2026-05-05
tags: [cli, ci, code-review, medium-priority, v2.1.120]
tested_in: []
incorporated_in: ['3.6.0']
---

# `claude ultrareview [target]` non-interactive CLI subcommand (v2.1.120)

## Observation

v2.1.120 added a non-interactive variant of `/ultrareview`:

```bash
claude ultrareview 1234              # PR number → review with multi-agent analysis
claude ultrareview 1234 --json       # raw payload
claude ultrareview --timeout 60 ...  # override 30-min default
# exit 0 = clean, 1 = findings/error
```

## Why it matters for dotforge

CI integration becomes trivial — pre-merge review gates without needing an interactive session.

Currently `docs/usage-guide.md` doesn't cover automated review at all. Dotforge ships a `code-reviewer` agent for interactive use; pairing with `claude ultrareview` in CI is the natural extension.

## Required update

1. `docs/usage-guide.md` — new subsection in CI/automation context describing the pattern: invoke `claude ultrareview <PR>` in GitHub Actions, capture `--json` output, post as PR comment.
2. Optional: example workflow file in `docs/examples/` (would need a new dir).

## Affected files

- `docs/usage-guide.md`
