---
name: derup-domain-extract
description: Domain extraction for derup ER modeler — sources read, files created, patterns learned
type: project
---

## 2026-03-25 — /forge domain extract on derup

Sources read: CLAUDE.md, CLAUDE_ERRORS.md (16 entries), agent-memory/implementer.md, auto-memory MEMORY.md, existing rules (frontend.md, _common.md), git log, er.ts, aiCommands.ts, chatParser.ts, Canvas.tsx (connection validation section), App.tsx (AI providers, WebSocket).

5 domain rule files created in `.claude/rules/domain/`:
- `er-modeling.md` — node types, valid connection pairs, self-relationships, aggregations, DiagramSnapshot
- `ai-command-protocol.md` — Zod discriminated union schema, all command types, parsing functions, App.tsx helper rules
- `chat-parser.md` — fuzzy match algorithm (startsWith before Levenshtein), attribute extraction quirks, clear-diagram boolean condition
- `ai-providers.md` — Gemini/Grok/Ollama/OpenClaw enum, connectivity states, VPS gateway reload pattern
- `canvas-rendering.md` — SVG connectors, self-relationships, isValidConnection actual pairs, export history
- `websocket-collaboration.md` — room lifecycle, sync message shape, TS strict state trap

Role section added to CLAUDE.md with 5 bullet points covering core concerns + 3 operational rules.

**Key learnings:**
- CLAUDE_ERRORS.md was the richest source — 16 real errors with root causes, directly translatable to domain rules
- derup uses custom SVG canvas, NOT React Flow despite similar concepts
- AI provider enum is `'gemini' | 'grok' | 'ollama' | 'openclaw'` (not OpenAI/Anthropic directly)
- `npm run lint` has known pre-existing violations — `npm run build` is the authoritative check
- chatParser has 7 pre-existing failing tests — do not attempt to fix unless explicitly asked
