# Demo Recording

`vhs` no funciona con CLIs interactivos como Claude Code. Hay que grabar manualmente.

## Instrucciones

1. Instalar Kap: `brew install --cask kap`
2. Abrir terminal, resize a ~900x500
3. Iniciar grabación en Kap
4. Correr:
   ```
   cd ~/Documents/GitHub/algún-proyecto
   claude
   /forge init
   ```
5. Esperar output, mostrar resultado
6. Exportar como GIF desde Kap (Settings → GIF, FPS 10, max width 900)
7. Guardar como `demo/demo.gif`

## Agregar al README

Una vez generado el GIF, agregar después de los badges en README.md:
```markdown
![dotforge demo](demo/demo.gif)
```
