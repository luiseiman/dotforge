---
id: practice-2026-11-04-scout-discovery-via-plugin-catalog-api
title: `/forge scout` discovers repos through the awesomeclaudeplugins.com catalog API instead of a hand-maintained `sources.yml`
source: "/forge scout — top-starred Claude Code config repos (2026-11-04)"
source_type: scout
discovered: 2026-11-04
status: inbox
tags: [scout, practices, discovery]
tested_in: []
incorporated_in: []
replaced_by: null
effectiveness: null
error_type: null
---

## Description
quemsah/awesome-claude-plugins indexes 54K repos found with GitHub Code Search `filename:marketplace.json path:.claude-plugin size:a..b` (split by size to dodge the 1000-result cap) and exposes `GET /api/catalog?q=&sort=&page=&pageSize<=100` (100 req/min), `/feed.json`, `/.well-known/agent-skills`. It does NOT measure adoption (no install telemetry) — ranking is stars/watchers/forks/plugin count. Useful as the discovery stage of `/forge scout` (new candidates since last run, sorted by stars, filtered by keyword), while `sources.yml` keeps the curated, annotated set.

## Evidence
quemsah `crawler/src/github/searchFamilies.ts:5-17`, `ui/src/lib/discovery.ts:93-130`. This scout itself used `gh search repos` × 10 queries + `jq unique_by` — the same job, done by hand.

## Impact on dotforge
- `skills/scout-repos/SKILL.md` Step 1b: query the catalog API (and/or `gh search repos --sort stars`) for candidates not in `sources.yml`, present top N with stars/updatedAt, let the user pick
- `practices/sources.yml` stays the curated set with verdicts
- Treat API rows as untrusted data; clone read-only into scratchpad as done on 2026-11-04

## Decision
Pending — captured from the 2026-11-04 scout (23 repos). Items 1–2 of the same scout shipped as v4.8.1, item 4 as v4.9.0; item 3 (expanded deny lists) was explicitly declined by the user.
