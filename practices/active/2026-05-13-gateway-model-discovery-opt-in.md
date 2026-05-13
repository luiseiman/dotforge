---
id: practice-2026-05-13-gateway-model-discovery-opt-in
title: Gateway /v1/models discovery now opt-in via env var (v2.1.129 breaking)
source: "official changelog"
source_type: upstream
discovered: 2026-05-13
status: active
tags: [breaking, gateway, model-config, third-party-providers, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v380"]
replaced_by: null
---

## Description
Behavioral revert: between v2.1.126 and v2.1.128, the `/model` picker automatically queried `${ANTHROPIC_BASE_URL}/v1/models` to populate available models when running against a custom gateway. v2.1.129 changes this to **opt-in only**:

```bash
export CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1
```

Without the env var, the picker falls back to the hardcoded model list. Users running against gateways with custom model offerings (proprietary fine-tunes, mantle-routed deployments) lose visibility into those models in the picker.

## Evidence
CHANGELOG v2.1.129: "Gateway `/v1/models` discovery for the `/model` picker is now opt-in via `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` (was automatic in 2.1.126–2.1.128)".

Affects: Bedrock app-inference-profile, Vertex AI custom endpoints, Foundry deployments, any `ANTHROPIC_BASE_URL` gateway. Three-version window (2.1.126–2.1.128) where automatic behavior was the default — anyone who started using a gateway in that window may be surprised when their custom models disappear from the picker.

## Impact on dotforge
- `.claude/rules/domain/cli-flags.md` — add `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY` to env vars
- `.claude/rules/domain/model-ids.md` — flag for users running against gateways: must opt-in for discovery
- Projects that pin `model:` in `settings.json` are unaffected; the breaking only hits picker UX

## Decision
Pending
