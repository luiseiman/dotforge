---
id: permission-request-updatedinput-deny-recheck
source: watch:code.claude.com/docs/en/changelog
status: active
captured: 2026-04-17
tags: [permissions, hooks, security, high-priority, v2.1.110]
tested_in: []
incorporated_in: ['3.2.0']
---

# `PermissionRequest.updatedInput` now re-checked against `permissions.deny`

## Observation

v2.1.110 bug fix: previously, a `PermissionRequest` hook returning `updatedInput` could bypass static deny rules because the deny check ran only against the ORIGINAL input. Now fixed — updatedInput is re-validated against `permissions.deny` before being accepted.

## Why it matters for dotforge

`domain/permission-model.md` section "Dynamic permissions from hooks" (added in v3.1.0) documents the `updatedPermissions` API but doesn't explicitly note this safeguard. The current text says:

> Static deny rules still enforce — a hook cannot remove a managed deny.

That is correct BUT doesn't cover the `updatedInput` path explicitly. A reader might assume `updatedInput` is a free pass to mutate a tool call. It isn't — deny rules re-check after mutation.

## Required update

Add explicit note in `permission-model.md`:

```
**Security note on `updatedInput`**: when a hook returns `updatedInput` to
mutate a tool call, the modified input is re-checked against `permissions.deny`
before execution (fix in v2.1.110). A hook cannot use `updatedInput` to smuggle
an otherwise-denied payload past static deny rules.
```

## Affected files

- `.claude/rules/domain/permission-model.md` — dynamic permissions section
