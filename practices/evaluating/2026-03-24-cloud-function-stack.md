---
id: practice-2026-03-24-cloud-function-stack
title: "Evaluar si vault-bot necesita stack cloud-function separado de gcp-cloud-run"
source: session-discovery
source_type: manual
status: evaluating
tags: [stacks, gcp, cloud-function, vault-bot]
date: 2026-03-24
---

## Context

vault-bot uses `functions_framework` (Google Cloud Functions), not FastAPI or Cloud Run containers. It was originally misclassified as `python-fastapi`, then corrected to `gcp-cloud-run` as the closest match. However, Cloud Run and Cloud Functions have different deployment models, constraints, and rules:

- **Cloud Run**: containers, Dockerfile, long-running, configurable concurrency, custom ports
- **Cloud Functions**: single entry point, event-driven, cold starts, no Dockerfile, `functions_framework`

The `gcp-cloud-run` stack rules (Docker, healthchecks, port config, multi-container) don't fully apply to a Cloud Function.

## Evaluation Criteria

1. How many projects use Cloud Functions vs Cloud Run?
2. Are the differences significant enough to warrant a separate stack?
3. What rules would differ? (deploy commands, no Dockerfile, entry point conventions, cold start optimization)
4. Could `gcp-cloud-run` be extended with conditionals, or is a clean split better?

## Recommendation

Evaluate during next `/forge update` cycle.
