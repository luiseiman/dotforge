---
name: websocket-shadow-import
description: Local directory named websocket/ shadows websocket-client PyPI package
type: config
source_type: cross-project
tags: [error-promotion, imports, naming, pyrofex, python]
date: 2026-03-23
project: cotiza-api-cloud
status: active
tested_in: [cotiza-api-cloud]
incorporated_in: [stacks/python-fastapi/rules/backend.md]
effectiveness: monitoring
error_type: config
---

## Pattern

A local package directory named `websocket/` shadows the `websocket-client` PyPI package.
pyRofex (and any lib using `import websocket`) fails with `AttributeError: module 'websocket' has no attribute 'WebSocketApp'`.

## Rule

Before naming a local directory, check if the name collides with an installed PyPI package:
```bash
pip3 show <dirname>
```
If it returns a result, choose a different name (e.g., `ws_clients/` instead of `websocket/`).

## Fix Applied

Renamed `websocket/` -> `ws_clients/` + updated 4 import sites.
Committed as: "Fix: Renombrar websocket/ — evitar shadow de websocket-client"
