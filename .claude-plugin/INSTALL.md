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

## Plugin Mode (lightweight)

Plugin mode installs a curated subset: hooks, rules, and commands.
Skills, agents, and practices pipeline require the full repository.

### What's included

| Component | Included | Notes |
|-----------|----------|-------|
| block-destructive hook | yes | PreToolUse, blocks dangerous commands |
| lint-on-save hook | yes | PostToolUse, auto-lint on file write |
| warn-missing-test hook | yes | PostToolUse, strict profile only |
| Common rules | yes | _common.md, memory.md, agents.md |
| Commands | yes | audit, health, review, debug |
| Skills (/forge) | no | Requires full repo |
| Agents (6 subagents) | no | Requires full repo |
| Practices pipeline | no | Requires full repo |
| Stack rules | selectable | Pick stacks during install |

### Installation

```bash
# Plugin system is not yet available in Claude Code.
# Use git clone + sync.sh (see Full Mode above) for now.
# This section will be updated when plugin support ships.
```

## Stack Plugins

Individual stacks are also available as standalone plugins:

```bash
# When plugin system supports composition:
claude plugin install dotforge-stack-python-fastapi
claude plugin install dotforge-stack-react-vite-ts
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
