---
id: practice-2026-04-26-pr-url-template-and-attribution
title: prUrlTemplate and attribution.commit/pr settings (v2.1.119) — supersede includeCoAuthoredBy
source: "official changelog"
source_type: upstream
discovered: 2026-04-26
status: active
tags: [settings, git, attribution, upstream, deprecation]
tested_in: null
incorporated_in: ["docs/changelog.md#v340"]
replaced_by: null
---

## Description
Two related Git/attribution settings:

- **`prUrlTemplate`** (v2.1.119) — substitutes `{host}`, `{owner}`, `{repo}`, `{number}`, `{url}` to point the footer PR badge at a custom code-review URL (GitHub Enterprise, GitLab self-hosted, Bitbucket Server).
- **`attribution.commit`** / **`attribution.pr`** — set the trailer text appended to commits/PRs Claude creates. Deprecates the older `includeCoAuthoredBy` boolean (still honored for back-compat).

The model also resolves `owner/repo#N` shorthand against the git remote host instead of always pointing at github.com (v2.1.119).

## Evidence
CHANGELOG v2.1.119: "Added `prUrlTemplate` setting to point the footer PR badge at a custom code-review URL instead of github.com" and "`owner/repo#N` shorthand links in output now use your git remote's host instead of always pointing at github.com".
Settings doc lists `attribution.commit` and `attribution.pr` and marks `includeCoAuthoredBy` deprecated.

## Impact on dotforge
- `template/settings.json.tmpl` — optional `attribution` block; do NOT default `prUrlTemplate` (only useful for self-hosted)
- `.claude/rules/_common.md` — Git section currently has no attribution guidance; could mention the trailer settings as the canonical knob
- `stacks/` — none of the current stacks target self-hosted Git; document for users who do

## Decision
Pending
