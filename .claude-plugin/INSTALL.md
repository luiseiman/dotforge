# dotforge Installation

## Full Mode (recommended)

Full mode gives access to all features including `/forge` commands, agents, and practices pipeline.

### Linux

```bash
git clone https://github.com/luiseiman/dotforge.git ~/dotforge
cd ~/dotforge && ./global/sync.sh
```

### macOS

```bash
git clone https://github.com/luiseiman/dotforge.git ~/dotforge
cd ~/dotforge && ./global/sync.sh
```

> Requires bash 3.2+ (pre-installed on macOS). If using Homebrew bash, both work.

### Windows (WSL — recommended)

```bash
# From WSL terminal:
git clone https://github.com/luiseiman/dotforge.git ~/dotforge
cd ~/dotforge && ./global/sync.sh
```

### Windows (Git Bash)

```bash
# From Git Bash:
git clone https://github.com/luiseiman/dotforge.git ~/dotforge
cd ~/dotforge && ./global/sync.sh
```

> Symlinks require Developer Mode enabled in Windows Settings > Privacy & Security > For Developers. If symlinks are not available, `sync.sh` automatically falls back to file copies.

### After installation

In any project directory:
```
/forge bootstrap    # Initialize .claude/ with full config
/forge audit        # Audit configuration and get a score (0-10)
/forge sync         # Update config against current template
```

### Explicit target directory

If `sync.sh` detects the wrong home directory, override with:
```bash
CLAUDE_HOME=/path/to/.claude ./global/sync.sh
```

## Plugin Mode (marketplace)

Install directly from the Claude Code plugin marketplace:

```bash
/install luiseiman/dotforge
```

Plugin mode installs a curated subset: hooks, rules, and commands.
Skills, agents, and practices pipeline require Full Mode (git clone).

### What's included

| Component | Plugin Mode | Full Mode |
|-----------|-------------|-----------|
| block-destructive hook | yes | yes |
| lint-on-save hook | yes | yes |
| warn-missing-test hook | yes | yes |
| Common rules | yes | yes |
| Commands (audit, health, review, debug) | yes | yes |
| Skills (/forge) | no | yes |
| Agents (7 subagents) | no | yes |
| Practices pipeline | no | yes |
| Stack rules | no | yes (selectable) |

> For the full feature set (skills, agents, stacks, practices), use Full Mode above.

## Stack Plugins

Individual stacks will be available as standalone plugins:

```bash
/install dotforge-stack-python-fastapi
/install dotforge-stack-react-vite-ts
```

Each stack plugin includes its `rules/*.md` and `settings.json.partial`.
Multiple stack plugins compose via permission union merge.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `/forge` not found after install | Run `sync.sh` again — check that target path matches your `~/.claude/` |
| Symlinks installed in wrong home | Set `CLAUDE_HOME` explicitly: `CLAUDE_HOME=~/.claude ./global/sync.sh` |
| Windows: "symlink not supported" | Enable Developer Mode, or let sync.sh use file copies (automatic) |
| macOS: "permission denied" on sync.sh | Run `chmod +x global/sync.sh` first |
| WSL: changes not visible in Windows | Claude Code should be run from WSL, not Windows cmd |
