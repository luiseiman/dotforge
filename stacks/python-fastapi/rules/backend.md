---
globs: "**/*.py"
---

# Python / FastAPI Rules

## Stack
Python 3.12+, FastAPI, async/await nativo. Type hints en funciones públicas. Ruff como linter/formatter.

## Patterns
- Endpoints thin: lógica en services/, no en routes/
- Dependency injection via FastAPI Depends()
- Pydantic models para request/response validation
- async def por defecto; def solo para operaciones sync-only (file I/O pesado)
- HTTPException con detail JSON, no strings

## Testing
- `pytest -v` con fixtures en conftest.py
- PYTHONPATH setear si el proyecto tiene subdirectorios
- Mock solo lo externo (APIs, DB real). Lógica de negocio: test directo
- async tests: `pytest-asyncio` con `asyncio_mode = "auto"` en pyproject.toml
- Factory functions en `tests/factories.py` para crear test data — importar directo, no via conftest.py

## Redis (si aplica)
- Redis Streams para colas (NO pub/sub para persistencia)
- Keys con namespace: `{app}:{entity}:{id}`
- TTL explícito en keys temporales

## Errores comunes
- Olvidar `await` en async calls → retorna coroutine, no resultado
- `response_model` sin `model_config = ConfigDict(from_attributes=True)` → falla con ORM
- Background tasks que no capturan excepciones → mueren silenciosamente
- `replace_all=True` in Edit without checking uniqueness — multiple similar patterns in a file get clobbered
- Local `import asyncio` inside functions: `patch("module.asyncio.sleep")` fails with AttributeError — use `patch("asyncio.sleep")` directly
