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

## Coverage
- No apuntar a 100% — cubrir paths críticos y edge cases
- Priorizar: happy path, error handling, boundary conditions
- Ignorar: boilerplate, getters triviales, código generado
