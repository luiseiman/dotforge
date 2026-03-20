# architect memory

Learnings and discoveries from architect agent sessions.

## 2026-03-20 — Practices inbox evaluation (4 items)
- **Decision:** REJECT tradingbot-session-changes (empty notification, not a practice), REJECT hookify-stack (Python app code violates config-only constraint), REWORK session-reviewer (needs external project validation), ACCEPT trading-stack (with category field addition)
- **Rejected:** hookify Python rule engine — the concept of hookify.*.local.md files is good, but the implementation must be bash, not Python with classes/dataclasses/LRU cache. Re-entry path: rewrite hooks in bash with jq+sed.
- **Pattern:** Domain stacks (trading) should use `"category": "domain"` in plugin.json to distinguish from technology stacks. No subdirectory tier needed.
- **Pattern:** Post-session hook capture produces low-value practices when it only lists filenames without diff context. The hook itself needs improvement.
