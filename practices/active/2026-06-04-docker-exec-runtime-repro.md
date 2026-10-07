---
id: practice-2026-06-04-docker-exec-runtime-repro
title: Reproduce/diagnose inside the container to use the runtime's real creds and deps
source: "own experience"
source_type: experience
discovered: 2026-06-04
status: active
tags: [docker, debugging, workflow, infra]
tested_in: TradingBot
incorporated_in: ["stacks/docker-deploy/rules/infra.md"]
replaced_by: null
---

## Description
To diagnose or reproduce a runtime issue with the service's actual configuration, run code from the service itself inside its container, e.g. `docker exec -i <container> python3 <<'EOF' ... EOF`. This uses the real key/config/env and the exact installed dependencies, avoiding local-environment drift (missing modules, different `.env`, wrong key). It's also how you read auth-gated endpoints/secrets without exposing them: reference `os.environ` from within the container instead of passing secrets through your shell.

## Evidence
On TradingBot the local Python lost `yaml` after a session resume, so a repro script failed locally. Running the same script via `docker exec -i tradingbot python3 <<EOF` worked: real deps, real Supabase key, real settings. The same technique let us call the bot's own authenticated API (`/api/ratio/cancel`, `/api/imbalances`) using `os.environ['DASHBOARD_API_KEY']` from inside the container, never printing the secret.

## Impact on dotforge
- Candidate for a docker/debugging rules note: "for runtime-faithful repro, exec into the container; reference in-container env for secrets rather than threading them through your shell."

## Decision
Pending
