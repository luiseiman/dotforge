---
id: verify-before-done-regex-missing-bash-tests
source: live-session
status: active
captured: 2026-04-21
tags: [v3-behavior, verify-before-done, regex, false-negative, medium-priority]
tested_in: [dotforge]
incorporated_in: ["docs/changelog.md#v340"]
---

# `verify-before-done` regex misses `bash tests/*.sh` — blocks legitimate pushes in markdown/config repos

## Observation

`behaviors/verify-before-done/behavior.yaml` trigger #1 regex enumerates test runners for major language stacks (pytest, npm test, go test, cargo test, vitest, jest, tsc, eslint, make test/check/build, swift test, mvn, gradle, ruff, mypy) but does NOT include `bash tests/...` or `./tests/...`.

dotforge's own test convention is `bash tests/test-*.sh` (shell scripts for validation). Running those tests does not set the `verification_done` flag, so `git push` from dotforge is always soft-blocked even after legitimate verification.

Reproduced today (2026-04-21) during v3.3.0 audit-script push: `bash tests/test-skills-index.sh` passed 19 skills but push still blocked.

## Proposed fix

Extend the regex in `behaviors/verify-before-done/behavior.yaml` trigger #1 to include:

```
|bash\s+tests?/|bash\s+.*test[_-].*\.sh|\./tests?/\S+\.sh
```

Or a broader pattern: `bash\s+\S*test\S*\.sh` to match any `bash <path>/test*.sh` invocation.

Recompile via `scripts/compiler/compile.sh` after edit.

## Workaround (current)

Session-scope disable: `bash scripts/forge-behavior/cli.sh off verify-before-done --session <SID>` — logged to `.forge/audit/overrides.log`.

## Affected files

- `behaviors/verify-before-done/behavior.yaml` (edit regex)
- `.claude/hooks/generated/verify-before-done__pretooluse__bash__0.sh` (regenerate)
