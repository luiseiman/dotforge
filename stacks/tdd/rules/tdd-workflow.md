---
globs: "**/*.py,**/*.ts,**/*.tsx,**/*.js,**/*.jsx,**/*.go,**/*.swift,**/*.rb"
description: TDD workflow enforcement
---

# TDD Workflow

## Red-Green-Refactor

1. Write a failing test first. Run it. Confirm it fails for the right reason.
2. Implement minimum code to pass the test. Nothing more.
3. Run tests. All must pass before proceeding.
4. Refactor only after green. Tests must stay green throughout.
5. NEVER skip the red step — a test that never failed proves nothing.

## Test naming

- Python: `test_<what>_<condition>_<expected_result>`
- JS/TS: `"should <behavior> when <condition>"`
- Go: `Test<What><Condition>` with `t.Run("<condition>", ...)`

## Constraints

- One behavior per test. No multi-assertion omnibus tests.
- Test public interfaces, not implementation details.
- Failing tests in CI are never acceptable to silence — fix the code or the test.
- Mock only I/O boundaries (network, filesystem, time). Never mock the unit under test.
