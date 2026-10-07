---
id: practice-2026-06-04-long-lived-container-masks-config-drift
title: A long-lived container masks config drift until it is recreated
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [docker, deploy, config, debugging, infra]
tested_in: TradingBot
incorporated_in: ["stacks/docker-deploy/rules/infra.md"]
replaced_by: null
---

## Description
A long-running container holds the environment it was started with in memory. If the `.env`/compose config drifts afterward (a key rotated, a value changed), nothing breaks until the container is recreated — at which point it suddenly picks up the new (possibly wrong) value. When something works "until the first rebuild," suspect config drift between the running container's in-memory env and the current `.env` on disk, rather than the code you just changed.

## Evidence
TradingBot's container had been running with a working `service_role` key in memory. The VPS `.env` held an `anon` key. A routine `docker compose up --build` recreated the container, which then loaded the `anon` key and went blind against the DB — making it look like the just-deployed code change broke things, when the real cause was pre-existing config drift surfaced by the recreate.

## Impact on dotforge
- Candidate for a docker/deploy rules note: "config drift hides in long-lived containers; verify env (decode/inspect) after a recreate, and don't attribute a post-rebuild break to the code diff by default."

## Decision
Pending
