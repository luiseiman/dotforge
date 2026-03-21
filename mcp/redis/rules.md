---
globs: "**/*.py,**/*.ts,**/*.js,**/docker-compose*"
---

# Redis MCP Rules

## Server caveat
No official Redis MCP server exists. Community implementations vary in quality and tool names.
Treat this as an inspection tool, not an operational one — prefer CLI (`redis-cli`) for writes.

## Safe read operations (call freely)
- `get`, `keys`, `hgetall`, `hget`: key inspection
- `lrange`, `smembers`: collection inspection
- `type`, `ttl`, `dbsize`: metadata
- `info`: server stats and memory usage

## Stream-specific reads (call freely for SOMA/event-driven projects)
- `xrange`: read messages from a stream by ID range
- `xlen`: count messages in a stream
- `xinfo_stream`: stream metadata (length, groups, consumer lag)
- `xinfo_groups`: consumer group states and pending counts

## Write operations — confirm first
Before any SET, DEL, EXPIRE, XADD, or consumer group operation:
1. State the key(s) affected
2. State the current value (read it first if unknown)
3. State why the write is needed
4. Wait for explicit confirmation

## Hard stops (always denied)
- `flushdb` / `flushall` — data destruction. Never call.
- `debug` / `config resetstat` — operational risk.

## Redis Streams guidance (SOMA pattern)
- Use XADD with MAXLEN ~ N to prevent unbounded stream growth in high-frequency producers
- Consumer groups: always check pending (XPENDING) before assuming a message was processed
- XREAD BLOCK: requires explicit timeout handling — never block indefinitely without a fallback
- Dead letter pattern: if a message fails N times, route to a dedicated DLQ stream before deleting

## Key pattern conventions
Before using `keys *` (can be slow on large datasets): prefer `scan` cursor iteration.
When key count is unknown, always add a limit or use type/prefix filtering.
