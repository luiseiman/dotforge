---
id: practice-2026-03-24-cotiza-security-critical
title: "cotiza-api-cloud: 5 CRITICAL security vulnerabilities require dedicated session"
source: forge-insights
source_type: forge-insights
status: deprecated
deprecated_reason: "project-specific action item — not a generalizable dotforge rule; handle in cotiza-api-cloud session"
deprecated_date: 2026-03-24
tags: [security, cotiza-api-cloud, critical]
date: 2026-03-24
---

## Context

`/forge insights` cross-project analysis (2026-03-24) detected 5 CRITICAL findings from cotiza-api-cloud:

1. No authentication on REST API
2. No authentication on WebSocket /ws/cotizaciones
3. Telegram bot has no chat_id validation
4. eval() in strategy_engine.py
5. SSL verification globally disabled in ws_rofex.py

## Decision
Deprecated 2026-03-24 — project-specific vulnerabilities. Address in a dedicated cotiza-api-cloud session. No template/stack change warranted.
