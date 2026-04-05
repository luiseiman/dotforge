---
globs: "**/*.{sql,ipynb,csv,xlsx}"
---

# Data Analysis Rules

## Stack
SQLite or PostgreSQL for data. Python 3.12+ with pandas/polars. Jupyter notebooks for exploration.

## SQLite
- Parameterized queries ALWAYS: `cursor.execute("SELECT * FROM t WHERE id=?", (id,))`
- NEVER string interpolation in SQL
- `.backup()` before destructive operations
- WAL mode for concurrency: `PRAGMA journal_mode=WAL`

## Reproducibility
- Scripts must be re-executable (idempotent)
- Intermediate data: export to CSV/Parquet with timestamp
- Notebooks: run top to bottom without errors (kernel restart + run all)
- Fixed seeds for random operations: `random.seed(42)`

## Pandas
- `df.info()` and `df.describe()` when loading new data
- Check NaN/nulls before operations
- `.copy()` when subsetting to avoid SettingWithCopyWarning
- Explicit types: `astype()` on load, do not assume

## Visualization
- matplotlib/seaborn for analysis. Do not install 5 chart libraries.
- Labels in the user's language
- Descriptive titles, axes with units

## Output
- Reports in markdown or Word (.docx)
- Tables with readable formatting (not raw dataframes)
- Conclusions at the end, not just data
