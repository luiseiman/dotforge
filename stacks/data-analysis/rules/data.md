---
globs: "**/*.{sql,ipynb,csv,xlsx}"
---

# Data Analysis Rules

## Stack
SQLite o PostgreSQL para datos. Python 3.12+ con pandas/polars. Jupyter notebooks para exploración.

## SQLite
- Queries parametrizadas SIEMPRE: `cursor.execute("SELECT * FROM t WHERE id=?", (id,))`
- NUNCA string interpolation en SQL
- `.backup()` antes de operaciones destructivas
- WAL mode para concurrencia: `PRAGMA journal_mode=WAL`

## Reproducibilidad
- Scripts deben ser re-ejecutables (idempotentes)
- Datos intermedios: exportar a CSV/Parquet con timestamp
- Notebooks: ejecutar de arriba a abajo sin errores (kernel restart + run all)
- Seeds fijos para operaciones random: `random.seed(42)`

## Pandas
- `df.info()` y `df.describe()` al cargar datos nuevos
- Verificar NaN/nulls antes de operaciones
- `.copy()` al hacer subset para evitar SettingWithCopyWarning
- Tipos explícitos: `astype()` al cargar, no asumir

## Visualización
- matplotlib/seaborn para análisis. No instalar 5 librerías de charts.
- Labels en español si el usuario es hispanohablante
- Títulos descriptivos, ejes con unidades

## Output
- Reportes en markdown o Word (.docx)
- Tablas con formato legible (no raw dataframes)
- Conclusiones al final, no solo datos
