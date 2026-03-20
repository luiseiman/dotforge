---
name: diff-project
description: Muestra qué cambió en claude-kit desde el último sync del proyecto, para decidir si conviene ejecutar /forge sync.
---

# Diff Proyecto

Mostrar qué cambió en claude-kit desde la última sincronización del proyecto actual.

## Paso 1: Identificar baseline del proyecto

1. Leer `$CLAUDE_KIT_DIR/registry/projects.yml`
2. Buscar el proyecto actual por `path` (comparar con `$PWD`)
3. Obtener `claude_kit_version` y `last_sync`
4. Si no hay `claude_kit_version` registrada (null), reportar:
   ```
   Proyecto no synceado — no hay baseline contra la cual comparar.
   Ejecutar /forge sync para establecer baseline.
   ```
   Y terminar.

## Paso 2: Verificar manifest local

Si existe `.claude/.forge-manifest.json` en el proyecto actual:
1. Leerlo y obtener la versión y los hashes de archivos
2. Para cada archivo en el manifest, calcular `shasum -a 256 <file> | cut -d' ' -f1`
3. Comparar contra el hash registrado
4. Reportar archivos modificados localmente (hash difiere) y archivos eliminados
5. Usar la version del manifest como baseline (más precisa que el registry)

Si NO existe manifest, continuar con Paso 3 usando git log.

## Paso 3: Detectar cambios en claude-kit

Ejecutar en `$CLAUDE_KIT_DIR/`:

```bash
git log --oneline v<version>..HEAD -- template/ stacks/
```

Donde `<version>` es el tag correspondiente a `claude_kit_version` del proyecto.

Si el tag no existe, usar `last_sync` como referencia:
```bash
git log --oneline --since="<last_sync>" -- template/ stacks/
```

Si no hay commits relevantes, reportar:
```
claude-kit no tiene cambios en template/stacks desde v<version>.
El proyecto está al día.
```

## Paso 4: Mostrar resumen de cambios

Para cada archivo modificado en template/ o stacks/ relevantes al proyecto:

```
═══ DIFF claude-kit: v<anterior> → v<actual> ═══
Proyecto: <nombre> (último sync: <fecha>)

Archivos modificados en claude-kit:
  template/hooks/block-destructive.sh — <resumen del diff>
  template/rules/_common.md — <resumen del diff>
  stacks/python-fastapi/rules/backend.md — <resumen del diff>

Archivos locales con modificaciones (vs manifest):
  .claude/rules/_common.md — hash difiere del deployado
```

Filtrar stacks/ para mostrar solo los stacks que el proyecto usa (leer del registry).

## Paso 5: Recomendar acción

Si hay cambios relevantes:
```
Recomendación: ejecutar /forge sync para incorporar estos cambios.
```

Si solo hay cambios cosméticos o en stacks no usados:
```
Los cambios no afectan a este proyecto. No es necesario sync.
```

## Instalación

Este skill se instala automáticamente si ya existe el symlink de `skills/` en `~/.claude/skills/`. Si no, crear el symlink:
```bash
ln -sf $CLAUDE_KIT_DIR/skills ~/.claude/skills
```
