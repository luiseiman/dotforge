---
globs: "**/*redis*,**/*stream*"
---

# Redis Rules

## Principio: Streams, NO pub/sub
- Redis Streams para colas persistentes y procesamiento asíncrono
- Pub/sub solo para notificaciones efímeras que pueden perderse
- Si el mensaje importa → Stream. Si es "nice to have" → pub/sub.

## Streams
- Consumer groups para procesamiento distribuido: `XREADGROUP GROUP group consumer`
- ACK obligatorio después de procesar: `XACK stream group id`
- `XAUTOCLAIM` para recuperar mensajes stuck (consumer muerto)
- `MAXLEN ~1000` o `MINID` para evitar streams infinitos
- Serialización: JSON para legibilidad, msgpack si performance importa

## Keys
- Namespace obligatorio: `{app}:{entity}:{id}` (ej: `myapp:users:123`)
- TTL explícito en keys temporales. No keys eternos sin motivo.
- `SCAN` para iterar. NUNCA `KEYS *` en producción (bloquea single-thread)
- `EXISTS` antes de operaciones costosas

## Connection
- Connection pool (no crear conexión por request)
- `decode_responses=True` en Python para evitar bytes vs str
- Timeout de conexión: 5s connect, 10s socket
- Retry con backoff para reconexión

## Persistencia
- RDB para snapshots (default). AOF para durabilidad (más lento).
- Si Redis es cache → `maxmemory-policy allkeys-lru`
- Si Redis es data store → backup regular + AOF

## Errores comunes
- Olvidar XACK → mensajes se re-entregan infinitamente
- KEYS * en prod con millones de keys → timeout de todo el server
- No configurar maxmemory → Redis consume toda la RAM y muere
- Serializar objetos Python nativos (pickle) → incompatible cross-language
