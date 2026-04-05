---
globs: "**/*.py"
---

# Python / FastAPI Rules

## System Prompt Overrides
- ALWAYS add docstrings to public functions and classes
- ALWAYS include type hints on function signatures

## Auto-mode Warning
In auto/YOLO mode, `Bash(python3 *)` is silently stripped from allow list. Use specific tool commands (pytest, uvicorn, ruff) instead of bare interpreter calls.

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

## Errores comunes
- Olvidar `await` en async calls → retorna coroutine, no resultado
- `response_model` sin `model_config = ConfigDict(from_attributes=True)` → falla con ORM
- Background tasks que no capturan excepciones → mueren silenciosamente
- `replace_all=True` in Edit without checking uniqueness — multiple similar patterns in a file get clobbered
- Local `import asyncio` inside functions: `patch("module.asyncio.sleep")` fails with AttributeError — use `patch("asyncio.sleep")` directly

## Debugging — root cause first
When 2+ fix attempts address the same symptom without resolving it:
1. Check import/module errors first: `python3 -c "import <module>"`
2. Check for shadowed packages: `pip3 show <dirname>` for each local dir in project root
3. Check missing env vars or wrong config keys in the affected flow
Only after ruling out infrastructure bugs, fix business logic.

## Package naming — avoid shadowing
Before naming a local directory, verify it doesn't shadow a PyPI package:
```bash
pip3 show <dirname>
```
If it returns a result, choose a different name (e.g., `ws_clients/` instead of `websocket/`).
Shadowing causes silent failures: `AttributeError: module 'websocket' has no attribute 'WebSocketApp'`.
