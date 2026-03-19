# Scoring de Auditoría

## Cálculo

```
score_obligatorio = sum(items 1-5)  # máximo 10
score_recomendado = sum(items 6-10) # máximo 5
score_total = score_obligatorio + (score_recomendado * 0.5)  # bonus pesa 50%
score_normalizado = min(score_total / 10 * 10, 10)  # normalizado a 10
```

## Interpretación

| Score | Nivel | Significado |
|-------|-------|-------------|
| 9-10  | Excelente | Configuración completa y madura. Solo ajustes menores. |
| 7-8.9 | Bueno | Sólido pero faltan algunos recomendados. |
| 5-6.9 | Aceptable | Funcional pero con gaps importantes. Necesita sync. |
| 3-4.9 | Deficiente | Faltan obligatorios. Necesita bootstrap parcial. |
| 0-2.9 | Crítico | Casi sin configuración. Necesita bootstrap completo. |

## Prioridad de corrección

1. Hook block-destructive (seguridad)
2. CLAUDE.md (contexto para Claude)
3. settings.json con deny list (seguridad)
4. Rules con globs (calidad de output)
5. Lint hook (calidad de código)
6. El resto
