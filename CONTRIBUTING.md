# Contributing to claude-kit

Thanks for your interest in contributing! claude-kit is a configuration factory for Claude Code — everything is markdown + shell scripts, no application code.

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
