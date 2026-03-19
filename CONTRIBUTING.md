> **[English](#contributing-to-claude-kit)** | **[Español](#contribuir-a-claude-kit)**

# Contributing to claude-kit

Thanks for your interest in contributing! claude-kit is the only end-to-end configuration management system for Claude Code — not a one-shot bootstrap or a static collection. It uniquely combines additive stack layering, intelligent template sync, normalized audit scoring (0-10), a practices pipeline for continuous improvement, and cross-project registry tracking. Everything is markdown + shell scripts, no application code.

## How to contribute

### Reporting issues

Open an issue with:
- What you expected
- What happened instead
- Your Claude Code version (`claude --version`)

### Proposing a new stack

1. Create `stacks/<name>/` with:
   - `rules/*.md` — contextual rules with `globs:` frontmatter
   - `settings.json.partial` — permissions and hooks to merge
   - Optional `hooks/*.sh` — stack-specific validation
2. Add detection rules to `stacks/detect.md`
3. Test with `/forge bootstrap` on a real project
4. Submit a PR

See `docs/creating-stacks.md` for the full guide.

### Improving rules or prompts

- All Claude-consumed content (rules, agent prompts, skill steps) must be in **English**
- User-facing content (docs, descriptions, changelog) may be in Spanish or English
- Prompts must be compact: imperative mood, no filler, one instruction per line
- Test your changes by running `/forge audit` on a bootstrapped project

### Submitting a practice

Use `/forge capture "description"` to create a practice in `practices/inbox/`. Practices go through a lifecycle: `inbox/` → `evaluating/` → `active/` → `deprecated/`.

## Development setup

```bash
# Clone
git clone https://github.com/luiseiman/claude-kit.git
cd claude-kit

# Set CLAUDE_KIT_DIR (used by skills and hooks)
export CLAUDE_KIT_DIR="$(pwd)"

# Install globally (symlinks skills, agents, commands into ~/.claude/)
./global/sync.sh

# Validate
bash -n .claude/hooks/*.sh
shellcheck .claude/hooks/*.sh 2>/dev/null || true
python3 -c "import yaml; yaml.safe_load(open('registry/projects.yml'))"
```

## Conventions

- **Commits**: atomic, imperative mood, first line <72 chars, prefixed with `feat:`, `fix:`, `chore:`, `docs:`
- **Hooks**: bash scripts, `exit 0` (ok) or `exit 2` (block), must be `chmod +x`
- **Skills**: directory with `SKILL.md` containing `name`/`description` frontmatter
- **Rules**: markdown with `globs:` frontmatter for auto-loading
- **Templates**: `.tmpl` extension with `<!-- forge:section -->` markers

## What NOT to contribute

- Application code — claude-kit only generates Claude Code configuration
- Rules that aren't derived from real project experience
- Features that add complexity without clear value

## Code of conduct

Be respectful. Be constructive. Focus on the work.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

# Contribuir a claude-kit

Gracias por tu interés en contribuir. claude-kit es el único sistema de gestión de configuración end-to-end para Claude Code — no un bootstrap one-shot ni una colección estática. Combina de forma única stack layering aditivo, sync inteligente de plantillas, audit scoring normalizado (0-10), un pipeline de prácticas para mejora continua y registry cross-proyecto con tracking. Todo es markdown + shell scripts, sin código de aplicación.

## Cómo contribuir

### Reportar problemas

Abrí un issue con:
- Qué esperabas
- Qué pasó en su lugar
- Tu versión de Claude Code (`claude --version`)

### Proponer un nuevo stack

1. Creá `stacks/<nombre>/` con:
   - `rules/*.md` — reglas contextuales con frontmatter `globs:`
   - `settings.json.partial` — permisos y hooks para mergear
   - Opcional `hooks/*.sh` — validación específica del stack
2. Agregá reglas de detección en `stacks/detect.md`
3. Probá con `/forge bootstrap` en un proyecto real
4. Enviá un PR

Consultá `docs/creating-stacks.md` para la guía completa.

### Mejorar reglas o prompts

- Todo el contenido consumido por Claude (reglas, prompts de agentes, pasos de skills) debe estar en **inglés**
- El contenido para usuarios (docs, descripciones, changelog) puede estar en español o inglés
- Los prompts deben ser compactos: modo imperativo, sin relleno, una instrucción por línea
- Probá tus cambios ejecutando `/forge audit` en un proyecto bootstrapeado

### Enviar una práctica

Usá `/forge capture "descripción"` para crear una práctica en `practices/inbox/`. Las prácticas pasan por un ciclo de vida: `inbox/` → `evaluating/` → `active/` → `deprecated/`.

## Configuración de desarrollo

```bash
# Clonar
git clone https://github.com/luiseiman/claude-kit.git
cd claude-kit

# Configurar CLAUDE_KIT_DIR (usado por skills y hooks)
export CLAUDE_KIT_DIR="$(pwd)"

# Instalar globalmente (symlinks de skills, agents, commands en ~/.claude/)
./global/sync.sh

# Validar
bash -n .claude/hooks/*.sh
shellcheck .claude/hooks/*.sh 2>/dev/null || true
python3 -c "import yaml; yaml.safe_load(open('registry/projects.yml'))"
```

## Convenciones

- **Commits**: atómicos, modo imperativo, primera línea <72 chars, con prefijo `feat:`, `fix:`, `chore:`, `docs:`
- **Hooks**: scripts bash, `exit 0` (ok) o `exit 2` (bloquear), deben tener `chmod +x`
- **Skills**: directorio con `SKILL.md` que contenga frontmatter `name`/`description`
- **Rules**: markdown con frontmatter `globs:` para carga automática
- **Templates**: extensión `.tmpl` con marcadores `<!-- forge:section -->`

## Qué NO contribuir

- Código de aplicación — claude-kit solo genera configuración para Claude Code
- Reglas que no provengan de experiencia en proyectos reales
- Features que agreguen complejidad sin valor claro

## Código de conducta

Sé respetuoso. Sé constructivo. Enfocate en el trabajo.

## Licencia

Al contribuir, aceptás que tus contribuciones serán licenciadas bajo la Licencia MIT.
