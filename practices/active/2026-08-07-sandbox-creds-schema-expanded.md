---
id: practice-2026-08-07-sandbox-creds-schema-expanded
title: sandbox.credentials schema expanded to files/envVars objects with mask|deny modes
source: "/forge watch — Claude Code upstream docs"
source_type: upstream-doc
discovered: 2026-08-07
status: active
tags: [sandbox, security, settings, docs-drift]
tested_in: []
incorporated_in: [".claude/rules/domain/sandboxing.md"]
replaced_by: null
---

## Description
Claude Code's `sandbox.credentials` setting is no longer a simple boolean flag. Current schema (post-v2.1.187): an object with `files: [{path, mode: "mask|deny", extract: "regex"}]` and `envVars: [{name, mode: "mask|deny"}]`. `mode: "mask"` is a new capability distinct from `deny` — sanitizes/redacts value instead of hard-blocking read. Invalid config degrades to `deny` mode by managed-settings tolerant stripping.

dotforge `domain/sandboxing.md` still documents the old form ("blocks reads to credential files"), and `template/settings.json.tmpl` + `stacks/*/settings.json.partial` don't emit the new schema. Production-tier projects (TRADINGBOT, cotiza-api-cloud, InviSight-iOS) benefit most from `mask` mode (redact API keys in tool output rather than blocking access outright).

## Evidence
Fetched from https://code.claude.com/docs/en/settings (2026-08-07). Full expanded schema section:
```json
"sandbox": {
  "credentials": {
    "files": [{"path": "/path/to/file", "mode": "mask|deny", "extract": "regex"}],
    "envVars": [{"name": "API_KEY", "mode": "mask|deny"}]
  }
}
```

## Impact on dotforge
- Update `domain/sandboxing.md` credentials section (currently boolean/list description)
- Update `template/settings.json.tmpl` — emit new object form as example
- Update `stacks/*/settings.json.partial` — production-tier stacks should default to `mask` mode
- Add migration guidance for projects still using boolean form

## Decision
Pending
