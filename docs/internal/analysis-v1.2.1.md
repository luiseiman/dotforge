# Análisis Integral / Comprehensive Analysis — dotforge v1.2.1

> Internal analysis of 7 dimensions across 83 files and 49 rules. Mixed Spanish/English.
>
> Análisis interno de 7 dimensiones sobre 83 archivos y 49 reglas.

**Fecha / Date:** 2026-03-19

## Inventario

- **83 archivos** en 11 directorios
- 8 stacks, 6 agentes, 7 skills, 9 docs, 2 prácticas
- 8 proyectos gestionados, todos en score 10.0

## Las 7 Dimensiones

### 1. SEGURIDAD — 9/10

**Fortalezas:**
- deny list (10 patrones) + block-destructive.sh (12 patrones)
- .gitignore protege secrets en todos los proyectos
- Security cap en scoring (si falla seguridad, max = 6.0)
- Claude Code fix: `allow` ya no bypasea `deny`

**Debilidades:**
- Security cap es instruccional (texto en skill), no programático
- No hay validación de que los deny patterns realmente bloqueen

### 2. MEMORIA — 8/10

**Fortalezas:**
- 5 capas definidas (CLAUDE.md, rules, errors, auto-memory, agent memory)
- memory.md rule inyectada en 8 proyectos
- autoMemoryEnabled en 8 proyectos
- Estrategia documentada en docs/memory-strategy.md

**Debilidades:**
- CLAUDE_ERRORS.md depende de lectura voluntaria (memory.md rule recuerda pero no fuerza)
- Agent memory (`memory: project`) declarativo — ningún directorio agent-memory/ creado
- No hay promoción automática de errores recurrentes a rules

### 3. CONTEXTO — 9/10

**Fortalezas:**
- CLAUDE.md por proyecto + global siempre cargado
- 49 rules con globs contextuales
- 8 stacks modulares
- `<!-- forge:custom -->` protege secciones en sync

**Debilidades:**
- Some bootstrapped projects have minimal CLAUDE.md without Architecture section
- `_common.md` copiado sin ajustar globs al stack real
- Prompt Language rule ambigua (dice "todo en inglés" pero docs están en español)

### 4. AGENTES — 7/10

**Fortalezas:**
- 6 agentes bien definidos con tools restringidos
- 4 con `memory: project` para aprendizaje acumulativo
- agents.md rule con decision tree completo
- Instalados via symlinks (36 en 6 proyectos)

**Debilidades:**
- `memory: project` declarativo, no operativo aún
- implementer referencia `.claude/specs/in-progress/` inexistente
- Agent Teams no probado en práctica
- No hay hooks SubagentStart/SubagentStop configurados

### 5. APRENDIZAJE — 5/10 (la más débil)

**Fortalezas:**
- Pipeline practices: inbox → evaluating → active → deprecated
- `/forge capture` y `/forge update` funcionales
- 1 práctica activa con 6 sub-prácticas extraídas

**Debilidades:**
- Pipeline casi vacío: 2 entries en total
- `/forge watch` y `/forge scout` listados pero sin implementación
- `practices/sources.yml` no existe (referenciado por scout)
- `practices/README.md` dice web search automático (removido en v0.9.0)
- No hay detección automática de prácticas
- No hay cross-pollination de errores entre proyectos

### 6. AUDITORÍA — 7/10

**Fortalezas:**
- Checklist 11 items (5 obligatorios, 6 recomendados)
- Scoring con fórmula + security cap
- `/forge audit` ejecutable en cualquier proyecto
- Registry trackea 8 proyectos

**Debilidades:**
- Fórmula demasiado generosa (todos dan 10.0 pese a gaps)
- Stack detection duplicado en 4 archivos
- Security cap es texto, no código
- No hay trending (scores en el tiempo)
- Registry scores uniformes y desactualizados

### 7. PROPAGACIÓN — 8/10

**Fortalezas:**
- bootstrap, sync, global sync funcionales
- Merge inteligente (unión de sets, preserva custom)
- `.forge-manifest.json` trackea deployments
- Symlinks para agentes

**Debilidades:**
- No hay git tags → `/forge diff` no funciona
- Changelog sin entry v1.2.1
- bootstrap no crea agent-memory/ ni specs/in-progress/
- `{{DOTFORGE_PATH}}` placeholder no resuelto por sync.sh

## Mapa de sinergia

```
DIMENSIÓN       ALIMENTA A →              SE ALIMENTA DE ←
─────────────────────────────────────────────────────────────
Seguridad       Todas (base)               Auditoría (detecta gaps)
Memoria         Contexto, Aprendizaje      Agentes (agent memory)
Contexto        Agentes, Seguridad         Memoria, Aprendizaje, Propagación
Agentes         Memoria (escriben)         Contexto (leen), Seguridad (limitan)
Aprendizaje     Contexto (nuevas rules)    Memoria (errores), Auditoría (gaps)
Auditoría       Aprendizaje (gaps→fixes)   Todas (mide cada una)
Propagación     Todas (distribuye)         Aprendizaje (qué propagar)
```

**Sinergias rotas:**
1. Aprendizaje → Contexto: pipeline no genera rules automáticamente
2. Memoria → Aprendizaje: errores no se promueven cross-project
3. Auditoría → Aprendizaje: gaps no se capturan como prácticas
4. Agentes → Memoria: agent memory declarado pero no operativo

## 10 Issues Concretos

| # | Issue | Dimensión | Impacto |
|---|-------|-----------|---------|
| 1 | Changelog sin entry v1.2.1 | Propagación | Bajo |
| 2 | practices/README.md dice web search (removido) | Aprendizaje | Bajo |
| 3 | README dice "51 items" seguridad (son ~30) | Documentación | Bajo |
| 4 | swiftformat (template) vs swiftlint (stack) | Contexto | Medio |
| 5 | Stack detection duplicado 4 veces | Auditoría | Medio |
| 6 | No hay git tags para /forge diff | Propagación | Medio |
| 7 | implementer referencia specs/in-progress/ inexistente | Agentes | Bajo |
| 8 | Fórmula de scoring demasiado generosa | Auditoría | Medio |
| 9 | /forge watch y scout sin skill formal | Aprendizaje | Bajo |
| 10 | Registry scores uniformes (9.5) desactualizados | Auditoría | Bajo |

## Veredicto

dotforge es sólido en las dimensiones que importan operacionalmente (Seguridad, Contexto, Propagación) y débil en las aspiracionales (Aprendizaje, agent memory). La sinergia más fuerte es Seguridad → Contexto → Agentes. La más débil es Aprendizaje → todo lo demás (pipeline vacío).

**Prioridad**: corregir los 10 issues (30 min), crear git tags (5 min), ajustar fórmula de scoring. El aprendizaje se arregla con hábito, no con más código.
