# Scoring de Auditoría

## Cálculo

```
score_obligatorio = sum(items 1-5)  # máximo 10
score_recomendado = sum(items 6-11) # máximo 6
score_total = score_obligatorio * 0.7 + score_recomendado * 0.5  # max = 7.0 + 3.0 = 10.0
score_normalizado = min(score_total, 10)
```

**Efecto:** obligatorios perfectos sin recomendados = 7.0 (Bueno). Para llegar a 9+ se necesitan al menos 4 recomendados.

## Cap por seguridad crítica

Si alguno de estos items es **0**, el score total tiene un cap máximo de **6.0**:
- Item 2 (settings.json) — sin permisos configurados
- Item 4 (hook block-destructive) — sin protección contra comandos destructivos

**Razón:** Un proyecto sin seguridad básica no puede ser "Excelente" independientemente de cuántos recomendados tenga.

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
2. settings.json con deny list (seguridad)
3. CLAUDE.md (contexto para Claude)
4. Rules con globs (calidad de output)
5. Lint hook (calidad de código)
6. El resto
