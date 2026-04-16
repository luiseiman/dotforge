---
id: auto-mode-no-enable-flag
source: watch:code.claude.com/docs/en/changelog
status: inbox
captured: 2026-04-17
tags: [auto-mode, cli-flags, drift, high-priority, v2.1.111]
tested_in: []
incorporated_in: []
---

# Auto mode no longer requires `--enable-auto-mode` flag

## Observation

v2.1.111 removed the `--enable-auto-mode` gate. Auto mode is now enabled simply by setting `permissions.defaultMode: "auto"` in settings.json — no CLI flag needed to opt into the feature globally.

## Required update

`domain/auto-mode.md` doesn't currently mention `--enable-auto-mode` (so no direct edit there). But it does say:

> - Enable: `permissions.defaultMode: "auto"` in settings.json
> - Disable (managed): `permissions.disableAutoMode: "disable"`

This description is still correct — but now it's the ONLY way to enable, since the research-preview gate is gone. Should note that the research preview period is over.

Also relevant: **Auto mode for Max subscribers** now available with Opus 4.7 — a pricing-tier gate, not a flag.

## Affected files

- `.claude/rules/domain/auto-mode.md` — remove "research preview" hedging, add Max-tier note

## Impact

Users can now enable auto mode unintentionally via settings edits. Our audit checklist item #13 (auto mode safety) becomes more important — more projects may be running in auto mode without the friction of a CLI opt-in.
