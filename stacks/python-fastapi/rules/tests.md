---
globs: "tests/**/*.py"
---

# Python Testing Rules

## Convenciones
- Factory functions en `tests/factories.py` para crear test data — importar directo, no via conftest.py
- Fixtures explícitas en conftest.py con nombres descriptivos. No fixtures "mágicas" sin tipo de retorno claro
- Nombres de test: `test_<qué>_<condición>_<resultado_esperado>`
- Assert con mensajes descriptivos: `assert result == expected, f"Expected {expected}, got {result}"`
- No mockear lo que se puede testear directamente. Mock solo para servicios externos (APIs, DB real, third-party)

## Async
- pytest-asyncio con `asyncio_mode = "auto"` en pyproject.toml
- Fixtures async: `@pytest_asyncio.fixture` (no `@pytest.fixture` para async)
- httpx.AsyncClient para test de endpoints FastAPI

## Patching
- Patch targets follow the namespace where the name is **used**, not where it's **defined**. After refactoring a method to a new module, update all `patch()` paths accordingly
- If a module uses `import asyncio` locally inside a function (not at top-level), patch `asyncio.sleep` globally — not `module.asyncio.sleep`
- After delegating/extracting methods to new modules, search all `patch()` calls targeting the old module's internals

## Concurrency Tests
- Threads don't propagate exceptions to the main thread by default. Use a `_run_threads(target, n, *args)` helper that wraps target in try/except, collects exceptions in a shared list, and asserts empty after join
- Verify RLock by behavior (acquire twice from same thread with `blocking=False`), not by `type().__name__` — internal type `_RLock` is private and may change

## Migration print→logging
- Replace adjacent `print(f"... {e}")` + `traceback.print_exc()` with a single `logger.exception(f"... {e}")` — it includes the full traceback
- Remove orphaned `import traceback` after migration
- Remove module prefix constants (e.g. `PRINT_PREFIX = "[module]"`) — logger name provides this

## Coverage
- No apuntar a 100% — cubrir paths críticos y edge cases
- Priorizar: happy path, error handling, boundary conditions
- Ignorar: boilerplate, getters triviales, código generado
