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
Python 3.12+, FastAPI, native async/await. Type hints on public functions. Ruff as linter/formatter.

## Patterns
- Thin endpoints: logic in services/, not in routes/
- Dependency injection via FastAPI Depends()
- Pydantic models for request/response validation
- async def by default; def only for sync-only operations (heavy file I/O)
- HTTPException with JSON detail, not strings

## Testing
- `pytest -v` with fixtures in conftest.py
- Set PYTHONPATH if the project has subdirectories
- Mock only external dependencies (APIs, real DB). Business logic: test directly
- async tests: `pytest-asyncio` with `asyncio_mode = "auto"` in pyproject.toml
- Factory functions in `tests/factories.py` for test data — import directly, not via conftest.py

## Common errors
- Forgetting `await` in async calls → returns coroutine, not result
- `response_model` without `model_config = ConfigDict(from_attributes=True)` → fails with ORM
- Background tasks that don't capture exceptions → die silently
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
Shadowing causes `AttributeError: module has no attribute`.
