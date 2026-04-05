---
globs: "**/*redis*"
---

# Redis Rules

## Principle: Streams, NOT pub/sub
- Redis Streams for persistent queues and async processing
- Pub/sub only for ephemeral notifications that can be lost
- If the message matters → Stream. If it's "nice to have" → pub/sub.

## Streams
- Consumer groups for distributed processing: `XREADGROUP GROUP group consumer`
- ACK required after processing: `XACK stream group id`
- `XAUTOCLAIM` to recover stuck messages (dead consumer)
- `MAXLEN ~1000` or `MINID` to prevent infinite streams
- Serialization: JSON for readability, msgpack if performance matters

## Keys
- Namespace required: `{app}:{entity}:{id}` (e.g.: `myapp:users:123`)
- Explicit TTL on temporary keys. No eternal keys without reason.
- `SCAN` to iterate. NEVER `KEYS *` in production (blocks single-thread)
- `EXISTS` before expensive operations

## Connection
- Connection pool (do not create one connection per request)
- `decode_responses=True` in Python to avoid bytes vs str issues
- Connection timeout: 5s connect, 10s socket
- Retry with backoff for reconnection

## Persistence
- RDB for snapshots (default). AOF for durability (slower).
- If Redis is cache → `maxmemory-policy allkeys-lru`
- If Redis is data store → regular backup + AOF

## Common errors
- Forgetting XACK → messages re-delivered infinitely
- KEYS * in prod with millions of keys → whole server timeout
- Not configuring maxmemory → Redis consumes all RAM and dies
- Serializing native Python objects (pickle) → incompatible cross-language
