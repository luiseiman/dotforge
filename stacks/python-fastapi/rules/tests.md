---
globs: "tests/**/*.py"
---

# Python Testing Rules

## Conventions
- Factory functions in `tests/factories.py` for test data — import directly, not via conftest.py
- Explicit fixtures in conftest.py with descriptive names. No "magic" fixtures without a clear return type
- Test names: `test_<what>_<condition>_<expected_result>`
- Assert with descriptive messages: `assert result == expected, f"Expected {expected}, got {result}"`
- Do not mock what can be tested directly. Mock only external services (APIs, real DB, third-party)

## Async
- pytest-asyncio with `asyncio_mode = "auto"` in pyproject.toml
- Async fixtures: `@pytest_asyncio.fixture` (not `@pytest.fixture` for async)
- httpx.AsyncClient for FastAPI endpoint tests

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
- Do not target 100% — cover critical paths and edge cases
- Prioritize: happy path, error handling, boundary conditions
- Ignore: boilerplate, trivial getters, generated code
